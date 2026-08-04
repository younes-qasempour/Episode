import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/data_transfer.dart';
import '../models/local_library_document.dart';
import '../models/media_item.dart';
import '../utils/clock.dart';

class LocalStorageRepository {
  static const String _storageKey = 'otaku_log_media_items';
  static const String _automaticBackupsKey = 'otaku_log_automatic_backups_v1';
  static const String _transferHistoryKey = 'otaku_log_transfer_history_v1';
  static const int automaticBackupRetention = 5;
  static const int historyRetention = 25;

  static const _uuid = Uuid();
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final Future<void> Function(List<MediaItem>)? transactionValidator;
  final Clock clock;
  final Function()? onLocalDataChanged;

  const LocalStorageRepository({
    this.transactionValidator,
    this.clock = const SystemClock(),
    this.onLocalDataChanged,
  });

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Load active media items (excluding soft-deleted tombstones).
  /// If storage has never been initialized, seed migrated sample items.
  Future<List<MediaItem>> loadActiveMediaItems() async {
    final allItems = await loadAllMediaItemsIncludingDeleted();
    return allItems.where((item) => item.deletedAt == null).toList();
  }

  /// Default library load returns active media items.
  Future<List<MediaItem>> loadMediaItems() => loadActiveMediaItems();

  /// Load all media items including soft-deleted tombstones.
  /// Handles schema v1 bare-array data and schema v2 envelopes with rollback protection.
  Future<List<MediaItem>> loadAllMediaItemsIncludingDeleted() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return [];
    }

    return await _decodeAndMigrateLibrary(jsonString, prefs);
  }

  /// Clear all media items from local storage.
  Future<List<MediaItem>> clearAllMediaItems() async {
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
    return [];
  }

  /// Save all media items under schema version 2 envelope.
  Future<void> saveAllMediaItems(List<MediaItem> items) async {
    _validateLibrary(items);
    final prefs = await _getPrefs();
    final doc = LocalLibraryDocument(
      schemaVersion: currentLocalLibrarySchemaVersion,
      migratedAt: clock.nowUtc(),
      mediaItems: items,
    );
    final jsonString = doc.toJson();
    final saved = await prefs.setString(_storageKey, jsonString);
    if (!saved) {
      throw const StorageWriteException('Could not save the media library.');
    }
  }

  /// Replace the whole library using a one-key snapshot transaction with rollback.
  Future<List<MediaItem>> replaceAllMediaItemsAtomically(
    List<MediaItem> items,
  ) async {
    _validateLibrary(items);
    final prefs = await _getPrefs();
    final previous = prefs.getString(_storageKey);
    final doc = LocalLibraryDocument(
      schemaVersion: currentLocalLibrarySchemaVersion,
      migratedAt: clock.nowUtc(),
      mediaItems: items,
    );
    final encoded = doc.toJson();

    try {
      final saved = await prefs.setString(_storageKey, encoded);
      if (!saved) {
        throw const StorageWriteException(
          'Could not stage the replacement library.',
        );
      }
      await transactionValidator?.call(items);
      final stored = prefs.getString(_storageKey);
      if (stored == null) {
        throw const StorageWriteException(
          'The staged library disappeared before validation.',
        );
      }
      final verified = await _decodeAndMigrateLibrary(stored, prefs);
      final verifiedDoc = LocalLibraryDocument(
        schemaVersion: currentLocalLibrarySchemaVersion,
        migratedAt: doc.migratedAt,
        mediaItems: verified,
      );
      if (verifiedDoc.toJson() != encoded) {
        throw const StorageWriteException(
          'The staged library failed round-trip validation.',
        );
      }
      onLocalDataChanged?.call();
      return verified;
    } catch (error) {
      if (previous == null) {
        await prefs.remove(_storageKey);
      } else {
        await prefs.setString(_storageKey, previous);
      }
      rethrow;
    }
  }

  /// Save a new media item or update an existing item by ID/title.
  Future<List<MediaItem>> saveMediaItem(MediaItem newItem) async {
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();

    final index = currentItems.indexWhere(
      (item) =>
          item.id == newItem.id ||
          item.title.trim().toLowerCase() == newItem.title.trim().toLowerCase(),
    );

    final String finalId;
    if (newItem.id.trim().isNotEmpty) {
      finalId = newItem.id;
    } else if (index >= 0 && currentItems[index].id.trim().isNotEmpty) {
      finalId = currentItems[index].id;
    } else {
      finalId = _uuid.v4();
    }

    if (index >= 0) {
      final existing = currentItems[index];
      currentItems[index] = newItem.copyWith(
        id: finalId,
        createdAt: existing.createdAt,
        updatedAt: now,
        clearDeletedAt: true,
        localRevision: existing.localRevision + 1,
      );
    } else {
      currentItems.insert(
        0,
        newItem.copyWith(
          id: finalId,
          createdAt: now,
          updatedAt: now,
          clearDeletedAt: true,
          localRevision: 1,
        ),
      );
    }

    await saveAllMediaItems(currentItems);
    return loadActiveMediaItems();
  }

  /// Update an existing media item in local storage.
  Future<List<MediaItem>> updateMediaItem(MediaItem updatedItem) async {
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();
    final index = currentItems.indexWhere((item) => item.id == updatedItem.id);

    if (index >= 0) {
      final existing = currentItems[index];
      currentItems[index] = updatedItem.copyWith(
        createdAt: existing.createdAt,
        updatedAt: now,
        localRevision: existing.localRevision + 1,
      );
      await saveAllMediaItems(currentItems);
    }

    return loadActiveMediaItems();
  }

  /// Toggle favorite status for a media item by ID.
  Future<List<MediaItem>> toggleFavorite(String id) async {
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();
    final index = currentItems.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final item = currentItems[index];
      currentItems[index] = item.copyWith(
        isFavorite: !item.isFavorite,
        updatedAt: now,
        localRevision: item.localRevision + 1,
      );
      await saveAllMediaItems(currentItems);
    }

    return loadActiveMediaItems();
  }

  /// Soft-delete a media item by setting deletedAt to UTC now.
  Future<List<MediaItem>> softDeleteMediaItem(String id) async {
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();
    final index = currentItems.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final item = currentItems[index];
      if (item.deletedAt == null) {
        currentItems[index] = item.copyWith(
          deletedAt: now,
          updatedAt: now,
          localRevision: item.localRevision + 1,
        );
        await saveAllMediaItems(currentItems);
      }
    }

    return loadActiveMediaItems();
  }

  /// Alias for soft deletion.
  Future<List<MediaItem>> deleteMediaItem(String id) => softDeleteMediaItem(id);

  /// Restore a soft-deleted media item.
  Future<List<MediaItem>> restoreDeletedMediaItem(String id) async {
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();
    final index = currentItems.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final item = currentItems[index];
      if (item.deletedAt != null) {
        currentItems[index] = item.copyWith(
          clearDeletedAt: true,
          updatedAt: now,
          localRevision: item.localRevision + 1,
        );
        await saveAllMediaItems(currentItems);
      }
    }

    return loadActiveMediaItems();
  }

  /// Explicitly purge tombstones (deleted items/seasons) older than [cutoff].
  Future<int> purgeDeletedMediaItemsBefore(DateTime cutoff) async {
    final cutoffUtc = cutoff.toUtc();
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();
    var purgedCount = 0;

    final remaining = <MediaItem>[];
    for (final item in currentItems) {
      if (item.deletedAt != null && item.deletedAt!.isBefore(cutoffUtc)) {
        purgedCount++;
        continue;
      }
      // Purge expired embedded deleted seasons
      var seasonPurged = false;
      final remainingSeasons = item.seasons.where((season) {
        if (season.deletedAt != null && season.deletedAt!.isBefore(cutoffUtc)) {
          seasonPurged = true;
          return false;
        }
        return true;
      }).toList();

      if (seasonPurged) {
        remaining.add(
          item.copyWith(
            seasons: remainingSeasons,
            updatedAt: now,
            localRevision: item.localRevision + 1,
          ),
        );
      } else {
        remaining.add(item);
      }
    }

    if (purgedCount > 0 || remaining.length != currentItems.length) {
      await saveAllMediaItems(remaining);
    }

    return purgedCount;
  }

  /// Increment progress for an active item by 1.
  Future<List<MediaItem>> incrementProgress(
    String id, {
    String? seasonId,
  }) async {
    final currentItems = await loadAllMediaItemsIncludingDeleted();
    final now = clock.nowUtc();
    final index = currentItems
        .indexWhere((item) => item.id == id && item.deletedAt == null);

    if (index >= 0) {
      final item = currentItems[index];
      MediaItem updatedItem = item;

      if (item.progressMode == ProgressMode.flat) {
        updatedItem = item.incrementFlatProgress(now: now);
      } else {
        final targetId = seasonId ?? item.defaultIncrementSeason?.id;
        if (targetId != null) {
          updatedItem = item.incrementSeason(targetId, now: now);
        }
      }

      if (!identical(updatedItem, item)) {
        currentItems[index] = updatedItem;
        await saveAllMediaItems(currentItems);
      }
    }

    return loadActiveMediaItems();
  }

  Future<AutomaticBackupRecord> createAutomaticBackup(String reason) async {
    final now = clock.nowUtc();
    final items = await loadAllMediaItemsIncludingDeleted();
    final backupId = _uuid.v4();
    final jsonContent = jsonEncode({
      'schemaVersion': currentLocalLibrarySchemaVersion,
      'migratedAt': now.toIso8601String(),
      'mediaItems': items.map((i) => i.toMap()).toList(),
    });
    final record = AutomaticBackupRecord(
      id: backupId,
      fileName: 'safety-backup-$reason.json',
      createdAt: now,
      itemCount: items.length,
      backupJson: jsonContent,
    );
    await saveAutomaticBackup(record);
    return record;
  }

  Future<void> saveAutomaticBackup(AutomaticBackupRecord backup) async {
    final prefs = await _getPrefs();
    final backups = await loadAutomaticBackups();
    backups.removeWhere((existing) => existing.id == backup.id);
    backups.insert(0, backup);
    if (backups.length > automaticBackupRetention) {
      backups.removeRange(automaticBackupRetention, backups.length);
    }
    final saved = await prefs.setString(
      _automaticBackupsKey,
      jsonEncode(backups.map((item) => item.toMap()).toList()),
    );
    if (!saved) {
      throw const StorageWriteException(
        'Could not create the automatic safety backup.',
      );
    }
  }

  Future<List<AutomaticBackupRecord>> loadAutomaticBackups() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_automaticBackupsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => AutomaticBackupRecord.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.id.isNotEmpty && item.backupJson.isNotEmpty)
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> addTransferHistory(TransferHistoryEntry entry) async {
    final prefs = await _getPrefs();
    final history = await loadTransferHistory();
    history.insert(0, entry);
    if (history.length > historyRetention) {
      history.removeRange(historyRetention, history.length);
    }
    final saved = await prefs.setString(
      _transferHistoryKey,
      jsonEncode(history.map((item) => item.toMap()).toList()),
    );
    if (!saved) {
      throw const StorageWriteException(
        'Could not update import/export history.',
      );
    }
  }

  Future<List<TransferHistoryEntry>> loadTransferHistory() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_transferHistoryKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => TransferHistoryEntry.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<List<MediaItem>> _decodeAndMigrateLibrary(
    String jsonString,
    SharedPreferences prefs,
  ) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const StorageCorruptionException(
        'Stored library JSON is corrupted.',
      );
    }

    if (decoded is List) {
      // Legacy v1 bare array format -> Migrate to Schema v2
      final migrationTime = clock.nowUtc();
      try {
        final migratedItems = _migrateLegacyArray(decoded, migrationTime);
        _validateLibrary(migratedItems);

        final doc = LocalLibraryDocument(
          schemaVersion: currentLocalLibrarySchemaVersion,
          migratedAt: migrationTime,
          mediaItems: migratedItems,
        );

        final saved = await prefs.setString(_storageKey, doc.toJson());
        if (!saved) {
          throw const StorageWriteException(
              'Failed to write migrated library envelope.');
        }
        return migratedItems;
      } catch (error) {
        // Rollback raw value
        await prefs.setString(_storageKey, jsonString);
        if (error is StorageCorruptionException ||
            error is StorageWriteException) {
          rethrow;
        }
        throw StorageMigrationException(
          'Failed to migrate legacy library data: $error',
        );
      }
    } else if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final schemaVersion = (map['schemaVersion'] as num?)?.toInt() ?? 1;

      if (schemaVersion > currentLocalLibrarySchemaVersion) {
        throw StorageUnsupportedSchemaException(
          'Library schema version $schemaVersion is newer than supported version $currentLocalLibrarySchemaVersion.',
        );
      }

      if (schemaVersion == currentLocalLibrarySchemaVersion) {
        final doc = LocalLibraryDocument.fromMap(map);
        _validateLibrary(doc.mediaItems);
        return doc.mediaItems;
      }

      // Future v1 -> v2 map migration if needed
      final doc = LocalLibraryDocument.fromMap(map);
      _validateLibrary(doc.mediaItems);
      return doc.mediaItems;
    } else {
      throw const StorageCorruptionException(
        'Stored library data is neither a JSON list nor envelope map.',
      );
    }
  }

  List<MediaItem> _migrateLegacyArray(List rawList, DateTime migrationTime) {
    final mediaIdMap = <String, String>{};
    final seasonIdMap = <String, String>{};

    // First pass: register existing valid UUIDs and generate new UUIDs for legacy IDs
    for (final entry in rawList) {
      if (entry is! Map) continue;
      final oldId = entry['id']?.toString() ?? '';
      if (oldId.isNotEmpty) {
        if (_uuidRegex.hasMatch(oldId)) {
          mediaIdMap[oldId] = oldId;
        } else {
          mediaIdMap[oldId] = _uuid.v4();
        }
      }

      final seasons = entry['seasons'];
      if (seasons is List) {
        for (final season in seasons) {
          if (season is Map) {
            final oldSeasonId = season['id']?.toString() ?? '';
            if (oldSeasonId.isNotEmpty) {
              if (_uuidRegex.hasMatch(oldSeasonId)) {
                seasonIdMap[oldSeasonId] = oldSeasonId;
              } else {
                seasonIdMap[oldSeasonId] = _uuid.v4();
              }
            }
          }
        }
      }
    }

    // Second pass: parse and convert items
    final migratedItems = <MediaItem>[];
    for (final entry in rawList) {
      if (entry is! Map) {
        throw const StorageCorruptionException(
          'Legacy library contains an invalid entry.',
        );
      }
      final map = Map<String, dynamic>.from(entry);
      final oldId = map['id']?.toString() ?? '';
      final newId = mediaIdMap[oldId] ?? _uuid.v4();

      final externalIds = _stringMap(map['externalIds']);
      final mergedExternalIds = Map<String, String>.from(externalIds);

      // Preserve provider identity from legacy IDs
      final jikanMatch =
          RegExp(r'^jikan_(anime|manga)_(\d+)$').firstMatch(oldId);
      if (jikanMatch != null) {
        mergedExternalIds.putIfAbsent('mal', () => jikanMatch.group(2)!);
        mergedExternalIds.putIfAbsent('jikan', () => jikanMatch.group(2)!);
      }
      final tvmazeMatch = RegExp(r'^tvmaze_series_(\d+)$').firstMatch(oldId);
      if (tvmazeMatch != null) {
        mergedExternalIds.putIfAbsent('tvmaze', () => tvmazeMatch.group(1)!);
      }

      // Convert seasons
      final rawSeasons = map['seasons'];
      final seasons = <MediaSeason>[];
      if (rawSeasons is List) {
        for (final s in rawSeasons) {
          if (s is Map) {
            final sMap = Map<String, dynamic>.from(s);
            final oldSId = sMap['id']?.toString() ?? '';
            final newSId = seasonIdMap[oldSId] ?? _uuid.v4();
            sMap['id'] = newSId;
            seasons.add(
                MediaSeason.fromMap(sMap, fallbackTimestamp: migrationTime));
          }
        }
      }

      map['id'] = newId;
      map['externalIds'] = mergedExternalIds;
      map['seasons'] = seasons.map((s) => s.toMap()).toList();

      final item = MediaItem.fromMap(map, fallbackTimestamp: migrationTime);
      migratedItems.add(item);
    }

    return migratedItems;
  }

  void _validateLibrary(List<MediaItem> items) {
    final ids = <String>{};
    for (final item in items) {
      if (item.id.trim().isEmpty || item.title.trim().isEmpty) {
        throw const StorageCorruptionException(
          'Every media item must have a non-empty ID and title.',
        );
      }
      if (!ids.add(item.id)) {
        throw StorageCorruptionException(
          'The library contains duplicate media ID "${item.id}".',
        );
      }

      final seasonNumbers = <int>{};
      for (final season in item.activeSeasons) {
        if (season.id.trim().isEmpty) {
          throw const StorageCorruptionException(
            'Every active season must have a non-empty ID.',
          );
        }
        if (!seasonNumbers.add(season.seasonNumber)) {
          throw StorageCorruptionException(
            'Media item "${item.title}" contains duplicate active season number ${season.seasonNumber}.',
          );
        }
      }
    }
  }
}

class StorageCorruptionException implements Exception {
  final String message;

  const StorageCorruptionException(this.message);

  @override
  String toString() => message;
}

class StorageWriteException implements Exception {
  final String message;

  const StorageWriteException(this.message);

  @override
  String toString() => message;
}

class StorageUnsupportedSchemaException implements Exception {
  final String message;

  const StorageUnsupportedSchemaException(this.message);

  @override
  String toString() => message;
}

class StorageMigrationException implements Exception {
  final String message;

  const StorageMigrationException(this.message);

  @override
  String toString() => message;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      if (entry.key.toString().trim().isNotEmpty && entry.value != null)
        entry.key.toString(): entry.value.toString(),
  };
}
