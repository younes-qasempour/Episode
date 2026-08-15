import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/media_item.dart';
import '../models/sync_metadata.dart';
import '../repositories/local_storage_repository.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../services/device_identity_service.dart';
import '../services/snapshot_assembler.dart';
import '../services/sync_metadata_storage.dart';
import '../utils/clock.dart';

enum SyncStatusState {
  idle,
  offline,
  pending,
  syncing,
  synced,
  conflictResolving,
  error,
  authenticationRequired,
}

class SyncResult {
  final bool success;
  final SyncStatusState state;
  final String? message;

  const SyncResult({
    required this.success,
    required this.state,
    this.message,
  });
}

class SyncService extends ChangeNotifier {
  static const _uuid = Uuid();

  final ApiClient apiClient;
  final LocalStorageRepository storageRepository;
  final SyncMetadataStorage metadataStorage;
  final DeviceIdentityService deviceIdentityService;
  final SnapshotAssembler snapshotAssembler;
  final Clock clock;

  SyncStatusState _state = SyncStatusState.idle;
  SyncMetadata? _metadata;
  String? _lastError;
  Completer<SyncResult>? _activeSyncCompleter;

  SyncService({
    required this.apiClient,
    required this.storageRepository,
    required this.metadataStorage,
    required this.deviceIdentityService,
    SnapshotAssembler? snapshotAssembler,
    Clock? clock,
  })  : snapshotAssembler =
            snapshotAssembler ?? SnapshotAssembler(clock: clock),
        clock = clock ?? const SystemClock();

  SyncStatusState get state => _state;
  SyncMetadata? get metadata => _metadata;
  String? get lastError => _lastError;
  bool get isSyncing =>
      _state == SyncStatusState.syncing ||
      _state == SyncStatusState.conflictResolving;

  Future<SyncMetadata> _getMetadata() async {
    if (_metadata != null) return _metadata!;
    final deviceId = await deviceIdentityService.getOrCreateClientDeviceId();
    _metadata = await metadataStorage.loadMetadata(fallbackDeviceId: deviceId);
    return _metadata!;
  }

  Future<void> markLocalChangePending() async {
    final meta = await _getMetadata();
    _metadata = meta.copyWith(syncPending: true);
    await metadataStorage.saveMetadata(_metadata!);
    if (_state == SyncStatusState.synced || _state == SyncStatusState.idle) {
      _state = SyncStatusState.pending;
    }
    notifyListeners();
  }

  Future<SyncResult> syncNow({String? boundUserId}) async {
    if (_activeSyncCompleter != null) {
      return _activeSyncCompleter!.future;
    }

    final completer = Completer<SyncResult>();
    _activeSyncCompleter = completer;

    _state = SyncStatusState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _executeSyncProcess(boundUserId: boundUserId);
      completer.complete(result);
      return result;
    } catch (e) {
      final errResult = SyncResult(
        success: false,
        state: SyncStatusState.error,
        message: e.toString(),
      );
      completer.complete(errResult);
      return errResult;
    } finally {
      _activeSyncCompleter = null;
    }
  }

  Future<SyncResult> _executeSyncProcess({String? boundUserId}) async {
    final meta = await _getMetadata();
    final deviceId = meta.clientDeviceId;

    // Case A: Unauthenticated / No bound user
    final tokens = await apiClient.tokenStorage.loadTokens();
    if (tokens == null || tokens.accessToken.isEmpty) {
      _state = SyncStatusState.authenticationRequired;
      notifyListeners();
      return const SyncResult(
        success: false,
        state: SyncStatusState.authenticationRequired,
        message: 'Sign in to enable multi-device sync.',
      );
    }

    // Bind user ID if present
    if (boundUserId != null && meta.boundUserId != boundUserId) {
      _metadata = meta.copyWith(boundUserId: boundUserId);
      await metadataStorage.saveMetadata(_metadata!);
    }

    // Step 1: Query server sync status
    Map<String, dynamic> statusRes;
    try {
      final res = await apiClient.get('/sync/status', requiresAuth: true);
      statusRes = Map<String, dynamic>.from(res as Map);
    } on NetworkUnavailableException {
      _state = SyncStatusState.offline;
      notifyListeners();
      return const SyncResult(
        success: false,
        state: SyncStatusState.offline,
        message: 'Offline. Local changes will sync when reconnected.',
      );
    } on AuthenticationRequiredException {
      _state = SyncStatusState.authenticationRequired;
      notifyListeners();
      return const SyncResult(
        success: false,
        state: SyncStatusState.authenticationRequired,
        message: 'Authentication session expired.',
      );
    } catch (e) {
      _state = SyncStatusState.error;
      _lastError = e.toString();
      notifyListeners();
      return SyncResult(
        success: false,
        state: SyncStatusState.error,
        message: e.toString(),
      );
    }

    final hasSnapshot = statusRes['hasSnapshot'] == true;
    final serverRevision = (statusRes['revision'] as num?)?.toInt() ?? 0;
    final knownRevision = _metadata!.serverRevision;
    final isPending = _metadata!.syncPending;

    final deviceInfo = await deviceIdentityService.getDeviceInfo();
    final platform = deviceInfo['platform'] ?? 'android';
    final appVersion = deviceInfo['appVersion'] ?? '1.0.0';

    // Case C & D: Server revision 0
    if (!hasSnapshot || serverRevision == 0) {
      final allItems =
          await storageRepository.loadAllMediaItemsIncludingDeleted();
      return await _pushSnapshot(
        snapshotId: _metadata!.lastSyncedSnapshotId ?? _uuid.v4(),
        deviceId: deviceId,
        baseRevision: 0,
        allItems: allItems,
        platform: platform,
        appVersion: appVersion,
      );
    }

    // Case E: Server revision == Local known revision and not pending
    if (serverRevision == knownRevision && !isPending) {
      _state = SyncStatusState.synced;
      _metadata = _metadata!.copyWith(
        lastSuccessfulSyncAt: clock.nowUtc(),
        clearLastSyncErrorCode: true,
      );
      await metadataStorage.saveMetadata(_metadata!);
      notifyListeners();
      return const SyncResult(
        success: true,
        state: SyncStatusState.synced,
        message: 'Already synchronized.',
      );
    }

    // Case F: Server revision == Local known revision and local pending
    if (serverRevision == knownRevision && isPending) {
      final allItems =
          await storageRepository.loadAllMediaItemsIncludingDeleted();
      return await _pushSnapshot(
        snapshotId: _uuid.v4(),
        deviceId: deviceId,
        baseRevision: serverRevision,
        allItems: allItems,
        platform: platform,
        appVersion: appVersion,
      );
    }

    // Case G: Server revision is newer and local not pending -> Pull & Replace
    if (serverRevision > knownRevision && !isPending) {
      return await _pullAndReplace(
        serverRevision,
        platform: platform,
      );
    }

    // Case H: Server revision is newer and local pending -> Pull & Merge & Push
    if (serverRevision > knownRevision && isPending) {
      return await _pullMergeAndPush(
        serverRevision: serverRevision,
        deviceId: deviceId,
        platform: platform,
        appVersion: appVersion,
      );
    }

    // Default fallback push
    final allItems =
        await storageRepository.loadAllMediaItemsIncludingDeleted();
    return await _pushSnapshot(
      snapshotId: _uuid.v4(),
      deviceId: deviceId,
      baseRevision: serverRevision,
      allItems: allItems,
      platform: platform,
      appVersion: appVersion,
    );
  }

  Future<SyncResult> _pushSnapshot({
    required String snapshotId,
    required String deviceId,
    required int baseRevision,
    required List<MediaItem> allItems,
    required String platform,
    required String appVersion,
    int conflictRetryCount = 0,
  }) async {
    final payload = snapshotAssembler.buildPushPayload(
      snapshotId: snapshotId,
      deviceId: deviceId,
      baseRevision: baseRevision,
      allItems: allItems,
      platform: platform,
      appVersion: appVersion,
    );

    try {
      final res =
          await apiClient.post('/sync/push', body: payload, requiresAuth: true);
      final pushRes = Map<String, dynamic>.from(res as Map);
      final newRev =
          (pushRes['revision'] as num?)?.toInt() ?? (baseRevision + 1);
      final checksum = pushRes['checksum']?.toString();

      _metadata = _metadata!.copyWith(
        serverRevision: newRev,
        lastSyncedSnapshotId: snapshotId,
        lastSyncedChecksum: checksum,
        lastSuccessfulSyncAt: clock.nowUtc(),
        syncPending: false,
        clearLastSyncErrorCode: true,
      );
      await metadataStorage.saveMetadata(_metadata!);

      _state = SyncStatusState.synced;
      notifyListeners();
      return const SyncResult(
        success: true,
        state: SyncStatusState.synced,
        message: 'Sync push successful.',
      );
    } on SyncRevisionConflictException catch (conflict) {
      // Case I: 409 Conflict -> Pull, Merge, and Retry push (max 3 attempts)
      if (conflictRetryCount >= 3) {
        _state = SyncStatusState.error;
        _lastError = 'Conflict retry limit exceeded. Local data preserved.';
        notifyListeners();
        return SyncResult(
          success: false,
          state: SyncStatusState.error,
          message: _lastError,
        );
      }

      _state = SyncStatusState.conflictResolving;
      notifyListeners();

      final targetRev = conflict.currentRevision ?? (baseRevision + 1);
      return await _pullMergeAndPush(
        serverRevision: targetRev,
        deviceId: deviceId,
        platform: platform,
        appVersion: appVersion,
        conflictRetryCount: conflictRetryCount + 1,
      );
    } catch (e) {
      _state = SyncStatusState.error;
      _lastError = e.toString();
      _metadata = _metadata!.copyWith(
        lastSyncErrorCode: e.toString(),
        lastSyncAttemptAt: clock.nowUtc(),
      );
      await metadataStorage.saveMetadata(_metadata!);
      notifyListeners();
      return SyncResult(
        success: false,
        state: SyncStatusState.error,
        message: e.toString(),
      );
    }
  }

  Future<SyncResult> _pullAndReplace(
    int serverRevision, {
    required String platform,
  }) async {
    try {
      final res = await apiClient.get(
        '/sync/pull',
        queryParams: {'knownRevision': '0'},
        requiresAuth: true,
      );
      final pullRes = Map<String, dynamic>.from(res as Map);
      final pulledItems = snapshotAssembler.parsePullPayload(pullRes);

      // Validate pulled items before replacing local data
      snapshotAssembler.validateSnapshotItems(pulledItems);

      // Create safety backup
      await storageRepository.createAutomaticBackup(
        'Pre-sync cloud replace safety backup',
        platform: platform,
      );

      // Atomic local replacement
      await storageRepository.replaceAllMediaItemsAtomically(pulledItems);

      _metadata = _metadata!.copyWith(
        serverRevision: serverRevision,
        lastSyncedSnapshotId: pullRes['snapshotId']?.toString(),
        lastSyncedChecksum: pullRes['checksum']?.toString(),
        lastSuccessfulSyncAt: clock.nowUtc(),
        syncPending: false,
        clearLastSyncErrorCode: true,
      );
      await metadataStorage.saveMetadata(_metadata!);

      _state = SyncStatusState.synced;
      notifyListeners();
      return const SyncResult(
        success: true,
        state: SyncStatusState.synced,
        message: 'Successfully pulled cloud library.',
      );
    } catch (e) {
      _state = SyncStatusState.error;
      _lastError = e.toString();
      notifyListeners();
      return SyncResult(
        success: false,
        state: SyncStatusState.error,
        message: e.toString(),
      );
    }
  }

  Future<SyncResult> _pullMergeAndPush({
    required int serverRevision,
    required String deviceId,
    required String platform,
    required String appVersion,
    int conflictRetryCount = 0,
  }) async {
    try {
      final res = await apiClient.get(
        '/sync/pull',
        queryParams: {'knownRevision': '0'},
        requiresAuth: true,
      );
      final pullRes = Map<String, dynamic>.from(res as Map);
      final cloudItems = snapshotAssembler.parsePullPayload(pullRes);

      snapshotAssembler.validateSnapshotItems(cloudItems);

      final localItems =
          await storageRepository.loadAllMediaItemsIncludingDeleted();

      // Create safety backup
      await storageRepository.createAutomaticBackup(
        'Pre-sync merge safety backup',
        platform: platform,
      );

      // Deterministic Merge
      final mergedItems =
          mergeLibraries(localItems: localItems, cloudItems: cloudItems);

      // Save merged library locally
      await storageRepository.replaceAllMediaItemsAtomically(mergedItems);

      // Push merged snapshot with new UUID
      return await _pushSnapshot(
        snapshotId: _uuid.v4(),
        deviceId: deviceId,
        baseRevision: serverRevision,
        allItems: mergedItems,
        platform: platform,
        appVersion: appVersion,
        conflictRetryCount: conflictRetryCount,
      );
    } catch (e) {
      _state = SyncStatusState.error;
      _lastError = e.toString();
      notifyListeners();
      return SyncResult(
        success: false,
        state: SyncStatusState.error,
        message: e.toString(),
      );
    }
  }

  List<MediaItem> mergeLibraries({
    required List<MediaItem> localItems,
    required List<MediaItem> cloudItems,
  }) {
    final mergedMap = <String, MediaItem>{};

    // Index local items
    for (final local in localItems) {
      mergedMap[local.id] = local;
    }

    // Merge cloud items
    for (final cloud in cloudItems) {
      // Find matching local item by ID or external provider ID or title+type
      final matchKey = _findMatchingLocalKey(cloud, mergedMap.values);

      if (matchKey == null) {
        // Unmatched cloud item -> Add to merged map
        mergedMap[cloud.id] = cloud;
      } else {
        // Matched -> Merge cloud with existing local
        final local = mergedMap[matchKey]!;
        final merged = mergeSingleMediaItem(local: local, cloud: cloud);
        if (matchKey != cloud.id) {
          mergedMap.remove(cloud.id);
        }
        mergedMap[local.id] = merged;
      }
    }

    return mergedMap.values.toList();
  }

  String? _findMatchingLocalKey(MediaItem cloud, Iterable<MediaItem> locals) {
    // 1. Exact ID
    for (final l in locals) {
      if (l.id == cloud.id) return l.id;
    }
    // 2. Exact external provider ID & media type
    for (final l in locals) {
      if (l.mediaType == cloud.mediaType) {
        for (final entry in cloud.externalIds.entries) {
          if (l.externalIds[entry.key] == entry.value) {
            return l.id;
          }
        }
      }
    }
    // 3. Title & media type
    final cloudTitle = cloud.title.trim().toLowerCase();
    for (final l in locals) {
      if (l.mediaType == cloud.mediaType &&
          l.title.trim().toLowerCase() == cloudTitle) {
        return l.id;
      }
    }
    return null;
  }

  MediaItem mergeSingleMediaItem({
    required MediaItem local,
    required MediaItem cloud,
  }) {
    // Determine winner for scalar fields: latest updatedAt wins
    final localUpdated = local.updatedAt;
    final cloudUpdated = cloud.updatedAt;
    final cloudIsNewer = cloudUpdated.isAfter(localUpdated);

    final primary = cloudIsNewer ? cloud : local;
    final secondary = cloudIsNewer ? local : cloud;

    // Preserved createdAt: earliest createdAt
    final localCreated = local.createdAt;
    final cloudCreated = cloud.createdAt;
    final earliestCreated =
        localCreated.isBefore(cloudCreated) ? localCreated : cloudCreated;

    // Latest updatedAt
    final latestUpdated =
        cloudUpdated.isAfter(localUpdated) ? cloudUpdated : localUpdated;

    // Tombstone check: if deletedAt is newer than the other record's updatedAt, deletion wins
    DateTime? finalDeletedAt;
    if (local.deletedAt != null && cloud.deletedAt != null) {
      finalDeletedAt = local.deletedAt!.isAfter(cloud.deletedAt!)
          ? local.deletedAt
          : cloud.deletedAt;
    } else if (local.deletedAt != null) {
      if (local.deletedAt!.isAfter(cloud.updatedAt)) {
        finalDeletedAt = local.deletedAt;
      } else {
        finalDeletedAt = null; // Active update restored item
      }
    } else if (cloud.deletedAt != null) {
      if (cloud.deletedAt!.isAfter(local.updatedAt)) {
        finalDeletedAt = cloud.deletedAt;
      } else {
        finalDeletedAt = null; // Active update restored item
      }
    }

    // Maximum progress wins
    final maxFlatProgress =
        local.flatCurrentProgress > cloud.flatCurrentProgress
            ? local.flatCurrentProgress
            : cloud.flatCurrentProgress;

    // Union externalIds
    final mergedExternalIds = <String, String>{
      ...secondary.externalIds,
      ...primary.externalIds,
    };

    // Union tags (deduplicated, preserving primary casing)
    final tagsSet = <String>{};
    final mergedTags = <String>[];
    for (final t in primary.tags) {
      if (tagsSet.add(t.toLowerCase())) mergedTags.add(t);
    }
    for (final t in secondary.tags) {
      if (tagsSet.add(t.toLowerCase())) mergedTags.add(t);
    }

    // Merge seasons
    final mergedSeasons = _mergeSeasons(local.seasons, cloud.seasons);

    return primary.copyWith(
      id: local.id, // Preserve stable local UUID
      currentProgress: maxFlatProgress,
      externalIds: mergedExternalIds,
      tags: mergedTags,
      seasons: mergedSeasons,
      createdAt: earliestCreated,
      updatedAt: latestUpdated,
      deletedAt: finalDeletedAt,
      clearDeletedAt: finalDeletedAt == null,
      localRevision: (local.localRevision > cloud.localRevision
              ? local.localRevision
              : cloud.localRevision) +
          1,
    );
  }

  List<MediaSeason> _mergeSeasons(
    List<MediaSeason> localSeasons,
    List<MediaSeason> cloudSeasons,
  ) {
    final mergedMap = <String, MediaSeason>{};

    for (final s in localSeasons) {
      mergedMap[s.id] = s;
    }

    for (final cSeason in cloudSeasons) {
      final matchId = mergedMap.keys.firstWhere(
        (id) =>
            id == cSeason.id ||
            mergedMap[id]!.seasonNumber == cSeason.seasonNumber,
        orElse: () => '',
      );

      if (matchId.isEmpty) {
        mergedMap[cSeason.id] = cSeason;
      } else {
        final lSeason = mergedMap[matchId]!;
        final cIsNewer = cSeason.updatedAt.isAfter(lSeason.updatedAt);
        final prim = cIsNewer ? cSeason : lSeason;

        final maxProg = lSeason.currentProgress > cSeason.currentProgress
            ? lSeason.currentProgress
            : cSeason.currentProgress;

        DateTime? finalDel;
        if (lSeason.deletedAt != null && cSeason.deletedAt != null) {
          finalDel = lSeason.deletedAt!.isAfter(cSeason.deletedAt!)
              ? lSeason.deletedAt
              : cSeason.deletedAt;
        } else if (lSeason.deletedAt != null) {
          finalDel = lSeason.deletedAt!.isAfter(cSeason.updatedAt)
              ? lSeason.deletedAt
              : null;
        } else if (cSeason.deletedAt != null) {
          finalDel = cSeason.deletedAt!.isAfter(lSeason.updatedAt)
              ? cSeason.deletedAt
              : null;
        }

        mergedMap[matchId] = prim.copyWith(
          id: lSeason.id,
          currentProgress: maxProg,
          createdAt: lSeason.createdAt.isBefore(cSeason.createdAt)
              ? lSeason.createdAt
              : cSeason.createdAt,
          updatedAt: cIsNewer ? cSeason.updatedAt : lSeason.updatedAt,
          deletedAt: finalDel,
          clearDeletedAt: finalDel == null,
          localRevision: (lSeason.localRevision > cSeason.localRevision
                  ? lSeason.localRevision
                  : cSeason.localRevision) +
              1,
        );
      }
    }

    final result = mergedMap.values.toList();
    result.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    return result;
  }
}
