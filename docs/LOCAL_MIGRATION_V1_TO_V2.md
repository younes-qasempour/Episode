# Episode Local Storage Migration Guide (v1 to v2)

This document details the automated, atomic migration process used by `LocalStorageRepository` to upgrade legacy local data (schema v1 bare JSON arrays) to the versioned schema v2 envelope format.

## Overview

- **Source Formats**:
  1. **Missing Storage**: When neither the active nor legacy key exists, the
     library starts empty.
  2. **Bare Legacy Array (v1)**: `[...]` array containing legacy records with deterministic provider IDs (`jikan_anime_123`, `tvmaze_series_456`), timestamp IDs (`manual_...`), or seed IDs (`1`..`8`).
  3. **Versioned Envelope (v2)**: `{"schemaVersion": 2, ...}` JSON envelope parsed directly.

- **Target Format**: `LocalLibraryDocument` schema v2 envelope with UUID v4 primary keys, UTC timestamp metadata (`createdAt`, `updatedAt`, `deletedAt`), and `localRevision`.

## Migration Algorithm

```text
1. Read the active SharedPreferences key `episode_media_items`.
2. If it is absent, read legacy key `otaku_log_media_items`. When present, copy
   the raw value to `episode_media_items`, then remove the legacy key after the
   successful copy. If both keys are absent, return an empty library.
3. If the selected JSON string starts with '[' -> Bare legacy array:
   a. Preserve exact raw string in memory for rollback.
   b. Build in-memory ID conversion map:
      - Valid UUIDs -> Keep unchanged.
      - Legacy provider IDs (e.g. jikan_anime_123, tvmaze_series_456) -> Map to new UUID v4, extract provider ID to externalIds['mal'] or externalIds['tvmaze'].
      - Legacy season IDs -> Map to new UUID v4.
   c. Assign fallback timestamps:
      - createdAt = addedAt ?? updatedAt ?? migrationTimestamp.
      - updatedAt = updatedAt ?? addedAt ?? createdAt.
      - deletedAt = null.
      - localRevision = 1.
   d. Wrap in LocalLibraryDocument(schemaVersion: 2, migratedAt: migrationTimestamp, mediaItems: items).
   e. Write envelope v2 JSON string to SharedPreferences.
   f. Read back and verify round-trip integrity.
   g. If any validation or write error occurs -> Restore original raw string to SharedPreferences and throw StorageMigrationException.
4. If JSON string starts with '{' -> Envelope Map:
   a. Check schemaVersion.
   b. If schemaVersion == 2 -> Parse document, validate items.
   c. If schemaVersion > 2 -> Throw StorageUnsupportedSchemaException without mutating storage.
```

## Retry and Rollback Safety

- **Atomic Application-Level Replacement**: SharedPreferences writes are atomic per key. The entire previous raw string is preserved in memory before writing.
- **Verification Gate**: The migrated payload is re-decoded and validated immediately after writing.
- **Rollback Execution**: If decoding, validation, or validation callback fails, the repository restores the exact original raw string to SharedPreferences before rethrowing a typed exception.
