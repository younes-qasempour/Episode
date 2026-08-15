# Project Overview

## Product

Episode is a Flutter media-tracking prototype for a person who follows anime,
manga, TV series, and movies. The current application lets a user maintain an
on-device library, discover supported media from public APIs, manually create
missing media, and edit flat or seasonal progress and metadata. It can also
import, export, back up, and restore the local library using local files
without requiring an account.

The target user is **inferred from current implementation**: an individual
media fan managing a collection locally, with optional authentication and
multi-device cloud snapshot synchronization. Social features are not
implemented.

## Primary flows

1. **Open the library:** the app loads a schema-v2 JSON library envelope from
   local preferences. A first run starts empty; legacy bare-array data is
   migrated on load.
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
- Unified Episode identity in app chrome, auth/loading surfaces, Android
  launcher/splash assets, web metadata/PWA/loading surfaces, and Windows icon
- Adaptive three-destination navigation: bottom navigation in compact layouts,
  a compact rail at medium widths, and an extended rail on desktop
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
- Responsive Home/library grids, Explore cards, two-pane media details,
  constrained forms, and multi-column analytics
- Optional authentication, secure token storage, device identity, and cloud
  snapshot synchronization
- Unit and widget test files around API mapping, repositories, search, and
  details

## Current modules

The code is organized by technical responsibility rather than feature:
`screens`, `widgets`, `models`, `repositories`, `services`, `data`, and
`theme`. See [CODEBASE_MAP.md](CODEBASE_MAP.md).

## Platform targets

- **Android:** native project and Storage Access Framework file adapter exist.
  The debug APK builds successfully. Production application identity and
  release signing still require attention.
- **Web:** browser pick/download adapter exists and `flutter build web --no-pub`
  succeeds.
- **Windows:** official Flutter runner, secure credential storage, responsive
  desktop navigation, and native open/save file dialogs are implemented;
  `flutter build windows --debug --no-pub` succeeds with the Microsoft C++
  desktop toolchain.
- **iOS, macOS, Linux:** runner projects are not present. Support is **Unknown**
  and must not be claimed.

## Important dependencies

- Flutter Material — UI and navigation
- `http` — Jikan and TVMaze requests
- `shared_preferences` — active library persistence
- `hive`, `hive_flutter`, `path_provider` — declared but unused
- `flutter_test` — test framework
- `flutter_lints` — analyzer rules, resolved by the current lockfile and used
  by the passing analyzer configuration

The transfer subsystem additionally uses `xml` for MAL parsing/generation,
`archive` for gzip input, `crypto` for SHA-256 integrity metadata, and `web`
for browser file selection/download.

## Visible scope boundaries

The repository does not implement notifications, pagination, offline API
caching, localization, social behavior, or MyAnimeList OAuth import. Account
and cloud sync UI are functional when `EPISODE_API_BASE_URL` points to the
companion backend. Profile identity/rank copy remains partly fixed, while
analytics are calculated from the local library.

## Unknown requirements

- Whether TV series are a permanent product category or a prototype extension
- Whether the now-unused static sample-data fixture should be removed or
  repurposed for previews/tests
- Notification and broader cloud-backup requirements
- Production API rate-limit, attribution, privacy, and caching requirements
- Supported device/OS matrix and accessibility targets
- Whether theme preference should persist
- Whether users should edit synopsis text (a controller exists, but no editor
  is rendered)
