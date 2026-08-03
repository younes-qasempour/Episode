# OtakuLog Multi-Device Snapshot Sync Client

This document outlines the synchronization algorithm, snapshot assembly, revision conflict handling, and merge policies implemented in `SyncService`.

## Client Device Identity & Metadata

- **Client Device ID**: Stable UUID v4 generated once per app installation by `DeviceIdentityService` and stored in `SharedPreferences` key `otaku_log_client_device_id_v1`.
- **Sync Metadata**: Device-local metadata (`boundUserId`, `clientDeviceId`, `serverRevision`, `lastSyncedSnapshotId`, `lastSyncedChecksum`, `lastSuccessfulSyncAt`, `syncPending`, `lastSyncErrorCode`, `lastSyncAttemptAt`) stored under `otaku_log_sync_metadata_v1`.

## Synchronization Protocol (Cases A–I)

1. **Case A (No Account)**: Offline anonymous operation. No network requests.
2. **Case B (Offline Authenticated)**: Local operations continue. Local mutations mark `syncPending = true`.
3. **Case C & D (Server Rev 0)**: Push complete snapshot with `baseRevision = 0` and UUID `snapshotId`.
4. **Case E (Server Rev == Known Rev, Not Pending)**: Already synchronized.
5. **Case F (Server Rev == Known Rev, Pending)**: Push complete snapshot from known revision.
6. **Case G (Server Rev > Known Rev, Not Pending)**: Pull cloud snapshot, validate, create safety backup, replace local library atomically.
7. **Case H (Server Rev > Known Rev, Pending)**: Pull cloud snapshot, create safety backup, merge libraries, save local, push merged snapshot.
8. **Case I (409 Conflict)**: Pull current cloud snapshot, apply client-side merge policy, generate new UUID snapshot ID, retry push (bounded to 3 attempts).

## Merge Engine Rules

- **Identity**: Preserve stable local UUIDs. Union compatible `externalIds`.
- **Creation Time**: Earliest valid `createdAt` is preserved.
- **Updated Time**: Latest `updatedAt` is preserved.
- **Progress**: Maximum progress wins (`max(local, cloud)` for flat and seasonal progress).
- **Scalar Metadata**: Latest `updatedAt` wins title, status, rating, synopsis, notes, release status.
- **Tags**: Case-insensitive deduplicated union.
- **Tombstones**: Deletion wins if `deletedAt` is newer than the active record's `updatedAt`. Active update after `deletedAt` restores item.
- **Seasons**: Matched by UUID or season number. Maximum progress wins, latest metadata wins.
