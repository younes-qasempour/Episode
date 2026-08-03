# OtakuLog Backup Schema

## Format identity

Native backups are UTF-8 JSON documents with `format: "otakulog-backup"`.
The current schema version is **1**. Files are named
`otakulog-backup-YYYY-MM-DDTHHMMSSZ.json` using a UTC timestamp.

```json
{
  "format": "otakulog-backup",
  "schemaVersion": 1,
  "applicationVersion": "1.0.0+1",
  "exportedAt": "2026-08-01T12:34:56.000Z",
  "platform": "android",
  "data": {
    "mediaItems": [],
    "preferences": {}
  },
  "integrity": {
    "algorithm": "sha256",
    "checksum": "lowercase-hex-sha256",
    "itemCount": 0
  }
}
```

## Top-level fields

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `format` | string | Yes | Stable format discriminator; must equal `otakulog-backup` |
| `schemaVersion` | integer | Yes for v1 | Backup contract version |
| `applicationVersion` | string | Yes | Exporting application version |
| `exportedAt` | ISO-8601 UTC string | Yes | Export time |
| `platform` | string | Yes | Exporting runtime label |
| `data` | object | Yes | Checksum-covered payload |
| `integrity` | object | Yes for v1 | Checksum algorithm/value and expected item count |

`data.mediaItems` is the ordered list of complete `MediaItem.toMap()` objects.
It includes identity, provider IDs, title/cover/type, flat and seasonal
progress, tracking/release status, score, synopsis, notes, tags, dates, repeat
count, favorite/manual flags, and custom metadata. `data.preferences` is
reserved and is currently exported as an empty object.

## Integrity rules

The checksum is SHA-256 over the UTF-8 bytes of compact `jsonEncode(data)`.
Import recomputes that value and also requires `integrity.itemCount` to equal
`data.mediaItems.length`. Integrity detects accidental modification or
truncation; it is not a signature and does not prove who created the file.

Before preview, every media entry must be an object with a non-empty unique
`id` and non-empty `title`. The entire file is limited to 20 MB. A schema newer
than the app supports is rejected without mutation.

## Migration policy

Migrations implement `BackupMigration` and run sequentially before model
mapping. Each migration declares one `sourceVersion` and `targetVersion`.
Missing links fail closed.

Schema 0 compatibility accepts legacy objects that contain a media list in
`data.mediaItems`, top-level `mediaItems`, or top-level `items`. It wraps that
list in the schema-1 envelope and emits a migration warning. Because legacy
files did not define schema-1 integrity metadata, integrity is checked only
for files that originally declare the current schema.

For a future schema:

1. Add a migration class without changing old migrations.
2. Register it in `NativeBackupCodec.migrations`.
3. Preserve source data that the current model does not own when possible.
4. Add old-to-new, malformed-old, future-version, and round-trip tests.
5. Update this document and the feature changelog in the same change.

## Restore transaction

Restore is deliberately separate from decoding:

1. Validate and preview the backup.
2. Load the current library.
3. Retain an automatic native safety backup.
4. Build the replacement library in memory.
5. Snapshot the one active SharedPreferences value.
6. Write the complete candidate library and decode it again.
7. Restore the snapshot if writing, injected transaction validation, or
   round-trip validation fails.

SharedPreferences has no native transaction API. The one-key snapshot is an
atomic-replacement strategy at the repository boundary, not a claim of an
OS-level ACID transaction.

## Privacy and retention

Backups are portable plaintext and can include personal notes/tags. Users
should store exported files appropriately. Automatic safety backups are also
plaintext inside application preferences. OtakuLog retains the newest five;
operation history retains the newest 25 summaries. History does not duplicate
source file contents or note text.
