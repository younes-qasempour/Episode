# Episode Local Data Schema (Schema Version 2)

This document describes the authoritative local storage schema for the Episode
Flutter application.

## Storage Keys

| Key | Purpose | Storage Format | Scope |
| --- | --- | --- | --- |
| `episode_media_items` | Active media library store | JSON Object (schema-v2 envelope) | Local authoritative library |
| `episode_automatic_backups_v1` | Rolling safety backups (max 5) | JSON Array | Device-local safety history |
| `episode_transfer_history_v1` | Import/export transfer log (max 25) | JSON Array | Device-local audit log |

For upgrade compatibility, first access falls back from
`otaku_log_media_items`, `otaku_log_automatic_backups_v1`, and
`otaku_log_transfer_history_v1` respectively. Episode copies the legacy value
to the matching active key and removes the old key only after a successful
copy. These `otaku_log_*` names are migration identifiers, not active product
keys.

## Active Store Envelope (Schema Version 2)

The active media library stored under `episode_media_items` is serialized as a
versioned JSON envelope object:

```json
{
  "schemaVersion": 2,
  "migratedAt": "2026-08-03T08:00:00.000Z",
  "mediaItems": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Jujutsu Kaisen Season 2",
      "coverUrl": "https://example.com/cover.jpg",
      "currentProgress": 18,
      "totalCount": 23,
      "flatCurrentProgress": 18,
      "flatTotalCount": 23,
      "mediaType": "anime",
      "status": "Watching",
      "releaseStatus": "finished",
      "progressMode": "flat",
      "seasons": [],
      "isManual": false,
      "synopsis": "...",
      "rating": 9.0,
      "externalIds": {
        "mal": "5114"
      },
      "notes": "Great arc",
      "tags": ["shonen", "supernatural"],
      "startedAt": "2026-01-01T00:00:00.000Z",
      "completedAt": null,
      "addedAt": "2026-01-01T00:00:00.000Z",
      "createdAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-08-03T08:00:00.000Z",
      "deletedAt": null,
      "localRevision": 1,
      "repeatCount": 0,
      "isFavorite": true,
      "customMetadata": {}
    }
  ]
}
```

## Entity Fields

### `MediaItem`

- `id`: Non-empty UUID v4 string (e.g., `550e8400-e29b-41d4-a716-446655440000`).
- `title`: Non-empty string.
- `coverUrl`: String URL.
- `currentProgress`: Nonnegative integer.
- `totalCount`: Nullable integer (null means unknown/unlimited).
- `mediaType`: String enum (`anime`, `manga`, `series`, `movie`).
- `status`: Tracking status string (`Plan to Watch`, `Watching`, `Reading`, `On Hold`, `Completed`, `Dropped`, `Unknown`).
- `releaseStatus`: Release status string (`ongoing`, `finished`, `upcoming`, `hiatus`, `cancelled`, `unknown`).
- `progressMode`: Progress mode string (`flat`, `seasonal`).
- `seasons`: List of `MediaSeason` embedded objects.
- `isManual`: Boolean.
- `synopsis`: Nullable string.
- `rating`: Double in range `[0.0, 10.0]`.
- `externalIds`: Map of provider identifiers (`mal`, `jikan`, `tvmaze`, etc.).
- `notes`: Nullable string.
- `tags`: List of strings.
- `startedAt`: Nullable ISO-8601 UTC string.
- `completedAt`: Nullable ISO-8601 UTC string.
- `addedAt`: Nullable ISO-8601 UTC string.
- `createdAt`: Non-null ISO-8601 UTC string (immutable after creation).
- `updatedAt`: Non-null ISO-8601 UTC string (updated on every user mutation).
- `deletedAt`: Nullable ISO-8601 UTC string (non-null represents a soft-deleted tombstone).
- `localRevision`: Non-null integer (`>= 1`, incremented on every local mutation).
- `repeatCount`: Nonnegative integer.
- `isFavorite`: Boolean.
- `customMetadata`: Map of extra metadata.

### `MediaSeason`

- `id`: Non-empty UUID v4 string.
- `seasonNumber`: Integer (`>= 1`, unique within active seasons of parent).
- `title`: Nullable custom season title.
- `currentProgress`: Nonnegative integer.
- `totalCount`: Nullable nonnegative integer.
- `releaseStatus`: Release status string.
- `createdAt`: Non-null ISO-8601 UTC string.
- `updatedAt`: Non-null ISO-8601 UTC string.
- `deletedAt`: Nullable ISO-8601 UTC string.
- `localRevision`: Non-null integer (`>= 1`).

## Soft Deletion and Tombstone Behavior

1. **Deletion**: Deleting a record sets `deletedAt = clock.nowUtc()`, `updatedAt = clock.nowUtc()`, and `localRevision = localRevision + 1`.
2. **UI Filtering**: Default UI loads filter out records where `deletedAt != null`.
3. **Storage Persistence**: Tombstones are retained in local storage to support future snapshot synchronization.
4. **Export Behavior**: Native Episode JSON backups preserve tombstones for
   lossless restore. External exports (CSV, MyAnimeList XML) filter out
   tombstones.
5. **Purging**: `purgeDeletedMediaItemsBefore(cutoff)` explicitly purges tombstones older than the specified cutoff date.
