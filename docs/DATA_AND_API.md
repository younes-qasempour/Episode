# Data and API

## Ownership boundaries

- `MediaItem` owns the shared application shape and JSON conversion.
- `ApiService` owns HTTP URLs, response decoding, and provider-to-model mapping.
- `SearchRepository` is the UI-facing remote-search boundary.
- `LocalStorageRepository` owns the saved library and its mutation rules.
- `MediaTransferRepository` owns import/export orchestration and history.
- Format providers own parsing/serialization; `ImportPlanner` owns matching,
  strategies, conflicts, and merge rules.
- `FileTransferService` owns the platform file boundary.
- Screens own transient presentation state and invoke repositories.

Do not call `http.Client` or `SharedPreferences` directly from a screen.

## Remote client

`ApiService` uses an injectable `http.Client`. Base URLs are compile-time public
constants:

- `https://api.jikan.moe/v4`
- `https://api.tvmaze.com`

No authentication, custom headers, interceptors, request body models, timeout,
retry, rate-limit handling, or pagination is implemented.

## Confirmed endpoints

| Method | Endpoint | Purpose | Request model | Response model | Used by |
| --- | --- | --- | --- | --- | --- |
| GET | `/top/anime?limit=10` | Default/top anime when query is empty | Query parameters only | Jikan object with `data` list, mapped to `MediaItem` | Explore → All/Anime |
| GET | `/anime?q={query}&limit=12` | Anime title search | Query parameters only | Jikan `data` list → `MediaItem` | Explore → All/Anime |
| GET | `/top/manga?limit=10` | Default/top manga when query is empty | Query parameters only | Jikan `data` list → `MediaItem` | Explore → All/Manga |
| GET | `/manga?q={query}&limit=12` | Manga title search | Query parameters only | Jikan `data` list → `MediaItem` | Explore → All/Manga |
| GET | `/search/shows?q={query}` | TV series search | Query parameter; empty UI query becomes `drama` | TVMaze result list; each `show` → `MediaItem` | Explore → All/Series |

Endpoints are relative to their provider base URL. Behavior beyond the parsed
fields is environment-dependent and unconfirmed.

## Mapping

### Jikan anime

- ID: `jikan_anime_{mal_id}`
- Title: English title, then default title
- Cover: large JPG, then regular JPG
- Total: positive `episodes`; missing, null, zero, or invalid values become
  unknown (`null`)
- Type/tracking status: `anime` / `Plan to Watch`
- Release status: Jikan airing status maps to ongoing, finished, upcoming, or
  unknown

### Jikan manga

- ID: `jikan_manga_{mal_id}`
- Total: positive `chapters`; missing, null, zero, or invalid values become
  unknown (`null`)
- Type/tracking status: `manga` / `Plan to Watch`
- Release status: publishing/finished/hiatus/discontinued/upcoming values map
  to the shared release-status enum
- Other title/image/synopsis mapping mirrors anime

### TVMaze

- ID: `tvmaze_series_{id}`
- Cover: original, then medium
- HTML tags are removed from summary with a regular expression
- Search records do not supply an authoritative episode total, so total remains
  unknown (`null`)
- Type/tracking status: `series` / `Plan to Watch`
- Release status: running/ended/upcoming/cancelled values map defensively;
  unexpected values become unknown

No provider mapper fabricates a fallback total.

## Error and concurrency behavior

Provider calls selected by category run concurrently through `Future.wait`.
Each private provider method catches all exceptions and returns `[]`; non-200
responses also return `[]`. The caller cannot distinguish no results from
network, parse, rate-limit, or server failures.

Explore debounces input for 500 ms but does not cancel or sequence active
requests. A slower old request can overwrite newer results.

## Local persistence

`LocalStorageRepository` uses the active `SharedPreferences` key
`episode_media_items`. Its value is a schema-v2 `LocalLibraryDocument` envelope
containing `schemaVersion`, `migratedAt`, and the complete `mediaItems` list.

If the active key is absent, the repository checks the legacy
`otaku_log_media_items` key, copies its raw value to the Episode key, and
removes the legacy key after the successful copy. If neither key exists, the
library starts empty. Legacy bare arrays are migrated to the schema-v2 envelope
with UUID/timestamp metadata and rollback protection. A valid empty library
remains empty. Invalid JSON, wrong root shapes, invalid required fields, and
duplicate IDs throw `StorageCorruptionException` without replacing the stored
raw value. CRUD methods load the whole document, mutate its list, and save the
whole envelope.

Existing records without new fields decode as flat progress, unknown release
status, no seasons, and non-manual origin. Existing positive totals and
progress are preserved. A legacy zero total is treated as unknown because the
old model used zero as an absence fallback.

New records serialize nullable totals, release status, progress mode, seasons,
manual origin, external provider IDs, notes, tags, dates, repeat/favorite
state, and custom metadata. Seasonal records keep their season list as the
authoritative progress source. Aggregate current/total values remain in the
legacy keys for older readers, while inactive flat snapshots support
reversible mode changes.

Duplicate add behavior matches either:

- exact `id`, or
- case-insensitive exact `title`.

Flat progress increments by one regardless of a known total and never changes
tracking status. Seasonal increments change only an explicit season or the
highest-numbered ongoing season. Movies do not increment.

Whole-library transfer writes use `replaceAllMediaItemsAtomically`: validate
the candidate list, snapshot the previous single-key JSON value, write the
candidate, decode/compare the round trip, and restore the snapshot on any
failure. The newest five automatic native backups are stored under
`episode_automatic_backups_v1`; the newest 25 transfer summaries are stored
under `episode_transfer_history_v1`. Each has a one-time fallback from its
matching legacy `otaku_log_*` key.

## Transfer formats

Native Episode backups are UTF-8 JSON schema v1 with application/platform/time
metadata and a SHA-256 checksum over the data object. A migration maps legacy
schema-0 media lists into v1. The stable format discriminator remains
`otakulog-backup` for compatibility, while newly exported filenames use the
`episode-backup-` prefix and retained safety snapshots use
`episode-safety-backup-`. New pre-import and pre-sync snapshots use the same
restorable codec; retained snapshots from the former local-envelope shape are
upgraded when downloaded. See [BACKUP_SCHEMA.md](BACKUP_SCHEMA.md).

MAL imports accept anime or manga XML and gzip-compressed XML. They map provider
IDs, title, progress/count, status, score, comments, tags, dates, repeat state,
release state, and manga volume metadata into `ImportedMediaEntry`. Unsafe
DOCTYPE/entity declarations, malformed/mixed documents, oversized files,
duplicate provider IDs, invalid entries, and invalid scores/progress are
rejected or reported before mutation. Native JSON and XML at or above 128 KB
use Flutter `compute` after size checks; this is a background isolate on
isolate-capable platforms and the main event loop on web.

MAL export writes separate anime/manga XML and omits entries without a usable
MAL/Jikan ID while reporting them. CSV export is UTF-8 with a BOM, fixed column
order, RFC-style quoting, and full current metadata. Platform adapters use
Android Storage Access Framework, browser selection/download APIs, or Windows
native open/save dialogs.

## Caching, offline, and migrations

- Remote response cache: not implemented
- Offline remote behavior: typed network failure with a retry action
- Active library schema/migration: explicit schema-v2 envelope; legacy bare
  arrays and the legacy library key migrate with rollback protection
- Portable backup schema/migration: explicit schema v1 plus v0-to-v1 migration
- Database: not implemented
- Hive usage: not implemented, despite declared packages
- Secure storage: implemented for optional account tokens; local library and
  transfer snapshots remain plaintext
- Encryption: not implemented
- Shared-preference migrations: legacy `otaku_log_*` library/backup/history
  keys migrate to Episode keys on first access

Do not introduce Hive or another database beside the active store. A
persistence change must define data migration, rollback/recovery, and ownership
before implementation.

## Secrets and privacy

No tokens or secrets are present or required by the confirmed APIs. Do not add
credentials to source control. The library and automatic backups are plain
application preference data, and exported JSON/XML/CSV may contain personal
notes. Whether future account/profile data requires stronger storage is
**Needs confirmation**. MyAnimeList OAuth is intentionally absent until a
registered client, redirect URI, and secure token storage are available.
