import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_transfer.dart';
import '../models/media_item.dart';
import '../data/mock_data.dart';

class LocalStorageRepository {
  static const String _storageKey = 'otaku_log_media_items';
  static const String _automaticBackupsKey = 'otaku_log_automatic_backups_v1';
  static const String _transferHistoryKey = 'otaku_log_transfer_history_v1';
  static const int automaticBackupRetention = 5;
  static const int historyRetention = 25;

  final Future<void> Function(List<MediaItem>)? transactionValidator;

  const LocalStorageRepository({this.transactionValidator});

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Load all media items from local storage.
  /// If storage has never been initialized, seed [sampleMediaItems].
  Future<List<MediaItem>> loadMediaItems() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      return _decodeLibrary(jsonString);
    }

    final defaultItems = List<MediaItem>.from(sampleMediaItems);
    await saveAllMediaItems(defaultItems);
    return defaultItems;
  }

  /// Save all media items back to local storage.
  Future<void> saveAllMediaItems(List<MediaItem> items) async {
    _validateLibrary(items);
    final prefs = await _getPrefs();
    final String jsonString = jsonEncode(items.map((i) => i.toMap()).toList());
    final saved = await prefs.setString(_storageKey, jsonString);
    if (!saved) {
      throw const StorageWriteException('Could not save the media library.');
    }
  }

  /// Replace the whole library using a one-key snapshot transaction.
  ///
  /// SharedPreferences does not provide multi-key transactions. The library is
  /// already stored under one key, so replacement snapshots that exact value,
  /// writes the complete candidate list, decodes it again, and restores the
  /// snapshot if writing or validation fails.
  Future<List<MediaItem>> replaceAllMediaItemsAtomically(
    List<MediaItem> items,
  ) async {
    _validateLibrary(items);
    final prefs = await _getPrefs();
    final previous = prefs.getString(_storageKey);
    final encoded = jsonEncode(items.map((item) => item.toMap()).toList());
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
      final verified = _decodeLibrary(stored);
      final verifiedJson = jsonEncode(
        verified.map((item) => item.toMap()).toList(),
      );
      if (verifiedJson != encoded) {
        throw const StorageWriteException(
          'The staged library failed round-trip validation.',
        );
      }
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

  /// Add a new media item or place it at the top of the library.
  Future<List<MediaItem>> saveMediaItem(MediaItem newItem) async {
    final currentItems = await loadMediaItems();
    final index = currentItems.indexWhere(
      (item) =>
          item.id == newItem.id ||
          item.title.toLowerCase() == newItem.title.toLowerCase(),
    );

    if (index >= 0) {
      currentItems[index] = newItem;
    } else {
      currentItems.insert(0, newItem);
    }

    await saveAllMediaItems(currentItems);
    return currentItems;
  }

  /// Update an existing media item in local storage.
  Future<List<MediaItem>> updateMediaItem(MediaItem updatedItem) async {
    final currentItems = await loadMediaItems();
    final index = currentItems.indexWhere((item) => item.id == updatedItem.id);

    if (index >= 0) {
      currentItems[index] = updatedItem;
      await saveAllMediaItems(currentItems);
    }

    return currentItems;
  }

  /// Delete a media item by ID from local storage.
  Future<List<MediaItem>> deleteMediaItem(String id) async {
    final currentItems = await loadMediaItems();
    currentItems.removeWhere((item) => item.id == id);
    await saveAllMediaItems(currentItems);
    return currentItems;
  }

  /// Increment progress for an item by 1 without clamping to a stored total.
  ///
  /// Flat items increment their single progress value. Seasonal items require
  /// an explicit [seasonId], or use the highest-numbered ongoing season when
  /// one is available. Movies and seasonal items without a clear target are
  /// left unchanged. Tracking status is always controlled by the user.
  Future<List<MediaItem>> incrementProgress(
    String id, {
    String? seasonId,
  }) async {
    final currentItems = await loadMediaItems();
    final index = currentItems.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final item = currentItems[index];
      MediaItem updatedItem = item;

      if (item.progressMode == ProgressMode.flat) {
        updatedItem = item.incrementFlatProgress();
      } else {
        final targetId = seasonId ?? item.defaultIncrementSeason?.id;
        if (targetId != null) {
          updatedItem = item.incrementSeason(targetId);
        }
      }

      if (!identical(updatedItem, item)) {
        currentItems[index] = updatedItem;
        await saveAllMediaItems(currentItems);
      }
    }

    return currentItems;
  }

  List<MediaItem> _decodeLibrary(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw const StorageCorruptionException(
          'Stored library data is not a JSON list.',
        );
      }
      final items = decoded.map((entry) {
        if (entry is! Map) {
          throw const StorageCorruptionException(
            'Stored library contains an invalid entry.',
          );
        }
        return MediaItem.fromMap(Map<String, dynamic>.from(entry));
      }).toList();
      _validateLibrary(items);
      return items;
    } on StorageCorruptionException {
      rethrow;
    } on FormatException {
      throw const StorageCorruptionException(
        'Stored library JSON is corrupted.',
      );
    } on TypeError {
      throw const StorageCorruptionException(
        'Stored library contains incompatible field types.',
      );
    }
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
