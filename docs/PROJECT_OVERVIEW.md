# Project Overview

## Product

OtakuLog is a Flutter media-tracking prototype for a person who follows anime,
manga, and TV series. The current application lets a user maintain an on-device
library, discover media from public APIs, and edit progress and metadata.

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
5. **Edit an item:** the detail screen changes status, progress, rating, and
   saves the current synopsis value; it can also delete the item.
6. **Change appearance:** the Profile tab toggles between light and dark
   themes for the current process.

## Current capabilities

- Material 3 light and dark themes
- Three-tab bottom navigation: Home, Explore, Profile
- Local JSON persistence through `shared_preferences`
- Jikan anime and manga search
- TVMaze series search
- Progress/status/rating editing and deletion
- Loading, empty, image-fallback, and selected feedback states
- Unit and widget test files around API mapping, repositories, search, and
  details

## Current modules

The code is organized by technical responsibility rather than feature:
`screens`, `widgets`, `models`, `repositories`, `services`, `data`, and
`theme`. See [CODEBASE_MAP.md](CODEBASE_MAP.md).

## Platform targets

- **Android:** native project exists. Release application identity, signing,
  and network permission require attention.
- **Web:** `web/index.html` exists. A web build was attempted but blocked before
  compilation by unresolved dependencies.
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

## Visible scope boundaries

The repository does not implement authentication, user accounts, cloud sync,
notifications, backup/export, pagination, offline API caching, localization,
or analytics. Profile statistics and identity are fixed presentation data.

## Unknown requirements

- Whether TV series are a permanent product category or a prototype extension
- Whether sample data should remain in a real user's library after first run
- Account, synchronization, notification, and backup requirements
- Production API rate-limit, attribution, privacy, and caching requirements
- Supported device/OS matrix and accessibility targets
- Whether theme preference should persist
- Whether users should edit synopsis text (a controller exists, but no editor
  is rendered)
