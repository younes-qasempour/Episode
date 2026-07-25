# Data and API

## Ownership boundaries

- `MediaItem` owns the shared application shape and JSON conversion.
- `ApiService` owns HTTP URLs, response decoding, and provider-to-model mapping.
- `SearchRepository` is the UI-facing remote-search boundary.
- `LocalStorageRepository` owns the saved library and its mutation rules.
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

`LocalStorageRepository` uses `SharedPreferences` key
`otaku_log_media_items`. The value is a JSON array of `MediaItem.toMap()`
objects.

On missing, empty, invalid, or decoded-empty storage, the repository copies
eight `sampleMediaItems`, saves them, and returns them. CRUD methods load the
whole list, mutate it, and save the whole list.

Existing records without new fields decode as flat progress, unknown release
status, no seasons, and non-manual origin. Existing positive totals and
progress are preserved. A legacy zero total is treated as unknown because the
old model used zero as an absence fallback.

New records serialize nullable totals, release status, progress mode, seasons,
and manual origin. Seasonal records keep their season list as the authoritative
progress source. Aggregate current/total values remain in the legacy keys for
older readers, while inactive flat snapshots support reversible mode changes.

Duplicate add behavior matches either:

- exact `id`, or
- case-insensitive exact `title`.

Flat progress increments by one regardless of a known total and never changes
tracking status. Seasonal increments change only an explicit season or the
highest-numbered ongoing season. Movies do not increment.

## Caching, offline, and migrations

- Remote response cache: not implemented
- Offline remote behavior: empty results, indistinguishable from errors
- Local schema version/migration: no explicit version; tolerant additive
  decoding provides compatibility for this change
- Database: not implemented
- Hive usage: not implemented, despite declared packages
- Secure storage: not implemented
- Encryption: not implemented
- Shared-preference migrations: not implemented

Do not introduce Hive or another database beside the active store. A
persistence change must define data migration, rollback/recovery, and ownership
before implementation.

## Secrets and privacy

No tokens or secrets are present or required by the confirmed APIs. Do not add
credentials to source control. The local library is plain application
preference data; whether future profile/user data requires stronger storage is
**Needs confirmation**.
