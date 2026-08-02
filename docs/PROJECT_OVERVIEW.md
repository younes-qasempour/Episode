# Project Overview

## Product

OtakuLog is a Flutter media-tracking prototype for a person who follows anime,
manga, TV series, and movies. The current application lets a user maintain an
on-device library, discover supported media from public APIs, manually create
missing media, and edit flat or seasonal progress and metadata. It can also
import, export, back up, and restore the local library using local files
without requiring an account.

The target user is **inferred from current implementation**: an individual
media fan managing one local collection. Accounts, multi-user behavior, social
features, and cloud synchronization are not implemented.

## Primary flows

1. **Open the library:** the app loads a JSON-encoded collection from local
   preferences. A first run is seeded with eight sample items.
2. **Filter and track:** the Home tab filters by title/type and increments
   episode or chapter progress.
3. **Discover media:** the Explore tab searches Jikan anime/manga and TVMaze
   series, including initial popular/default results.
4. **Add to the library:** a remote result is saved locally unless its ID or
   case-insensitive title already exists.
5. **Add manually:** a focused form creates anime, manga, series, or movies
   without a provider ID.
6. **Edit an item:** the detail screen changes separate tracking/release
   status, nullable totals, flat or seasonal progress, rating, and synopsis; it
   can also delete the item.
7. **Change appearance:** the Profile tab toggles between light and dark
   themes for the current process.
8. **Move or protect data:** Profile opens a preview-first data screen for
   native JSON backup/restore, MAL XML transfer, CSV export, automatic safety
   snapshots, and transfer history.

## Current capabilities

- Material 3 light and dark themes
- Three-tab bottom navigation: Home, Explore, Profile
- Local JSON persistence through `shared_preferences`
- Jikan anime and manga search
- TVMaze series search
- Manual anime/manga/series/movie creation
- Unknown and exceeded totals
- Flat and multi-season progress
- Separate tracking/release status, rating, synopsis editing, and deletion
- Versioned native JSON backup and restore with checksum validation
- MAL anime/manga XML and XML.GZ import, MAL XML export, and UTF-8 CSV export
- Deterministic matching, merge/add/replace/restore strategies, rollback, and
  retained safety backups/history
- Loading, empty, image-fallback, and selected feedback states
- Unit and widget test files around API mapping, repositories, search, and
  details

## Current modules

The code is organized by technical responsibility rather than feature:
`screens`, `widgets`, `models`, `repositories`, `services`, `data`, and
`theme`. See [CODEBASE_MAP.md](CODEBASE_MAP.md).

## Platform targets

- **Android:** native project and Storage Access Framework file adapter exist.
  Release application identity, signing, and network permission require
  attention. The debug build remains blocked by unavailable Android Gradle
  Plugin 9.0.1 resolution in the current environment.
- **Web:** browser pick/download adapter exists and `flutter build web --no-pub`
  succeeds.
- **iOS, macOS, Windows, Linux:** not present. Support is **Unknown** and must
  not be claimed.

## Important dependencies

- Flutter Material — UI and navigation
- `http` — Jikan and TVMaze requests
- `shared_preferences` — active library persistence
- `hive`, `hive_flutter`, `path_provider` — declared but unused
- `flutter_test` — test framework
- `flutter_lints` — analyzer rules, currently unavailable in the local package
  resolution environment

The transfer subsystem additionally uses `xml` for MAL parsing/generation,
`archive` for gzip input, `crypto` for SHA-256 integrity metadata, and `web`
for browser file selection/download.

## Visible scope boundaries

The repository does not implement authentication, user accounts, cloud sync,
notifications, pagination, offline API caching, localization, or analytics.
Profile statistics and identity are fixed presentation data. MyAnimeList
account/OAuth import is not enabled; transfer is local-file based.

## Unknown requirements

- Whether TV series are a permanent product category or a prototype extension
- Whether sample data should remain in a real user's library after first run
- Account, synchronization, notification, and cloud-backup requirements
- Production API rate-limit, attribution, privacy, and caching requirements
- Supported device/OS matrix and accessibility targets
- Whether theme preference should persist
- Whether users should edit synopsis text (a controller exists, but no editor
  is rendered)
