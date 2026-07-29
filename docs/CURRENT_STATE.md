# Current State

Snapshot verified on **2026-07-25** against base Git commit `9e7c995` and the
current manual-media/progress-tracking working-tree change.

## Feature status

| Area | Status | Evidence | Important files | Notes |
| --- | --- | --- | --- | --- |
| App shell and tabs | Complete | `MaterialApp`, `IndexedStack`, and three bottom-nav items are wired | `lib/main.dart`, `lib/screens/main_navigation_screen.dart` | “Complete” describes the current three-tab scope, not final product navigation. |
| Local library load/save | Functional but incomplete | CRUD, nullable totals, manual/movie fields, and seasonal data serialize in one backward-compatible JSON list | `lib/repositories/local_storage_repository.dart`, `lib/models/media_item.dart` | Decode failures still silently reset to seeded sample data; there is no explicit schema version. |
| Home library | Complete | In-library search, Media Type & Status filter chips, sorting (Recently Updated, Title, Rating, Completion %), Favorites toggle, stats, state-aware cards, detail navigation, manual add, and uncapped `+1` | `lib/screens/home_tab.dart`, `lib/widgets/media_card.dart` | Supports multi-axis filtering, 4-way sorting, fast search, and 1-tap favorites. |
| Remote discovery | Functional but incomplete | Jikan anime/manga (with Kitsu fallback) and TVMaze requests map to `MediaItem` | `lib/services/api_service.dart`, `lib/screens/search_tab.dart` | TVMaze embedded season enrichment and Jikan 429 rate limit pacing included. |
| Add to library | Complete | Remote results and manually created anime, manga, series, or movies use the same repository and root callback | `lib/screens/main_navigation_screen.dart`, `lib/screens/manual_media_screen.dart` | Duplicate matching uses ID or case-insensitive title. |
| Media detail editing | Functional but incomplete | Tracking/release status, unknown totals, flat/seasonal progress, season CRUD, rating, synopsis, custom cover URL, favorite toggle, save, and delete are implemented | `lib/screens/media_detail_screen.dart`, `lib/widgets/season_editor_dialog.dart` | Save/delete callbacks remain synchronous at the screen boundary and are not awaited. |
| Profile | Functional | Identity, theme switch, version display, clear all library data action | `lib/screens/profile_tab.dart` | Clear library data feature and clean empty start implemented. |
| Theme switching | Functional but incomplete | Light/dark themes and an in-memory switch work | `lib/main.dart`, `lib/theme/app_theme.dart` | System mode is lost after choosing a mode; choice is not persisted. |
| Localization | Not implemented | No ARB files, localization delegates, or localization dependency | `lib/` | User-visible strings are English literals. |
| Authentication/cloud sync | Not implemented | No auth/client/account or sync implementation | Repository-wide search | Profile text suggesting backup/sync is placeholder UI only. |
| Tests | Complete | Ten test files contain 56 passing unit and widget tests | `test/` | Full suite passes 56/56 cleanly with zero failures. |
| Android release | Blocked | Template application ID/signing TODOs; INTERNET permission is debug/profile-only | `android/app/` | Release behavior was not built. |
| Web build | Complete | `build/web` release build verified | `web/index.html` | Release compilation tested with `flutter build web --release`. |

Status vocabulary: **Complete**, **Functional but incomplete**, **In progress**,
**Placeholder**, **Not implemented**, **Unknown**, and **Blocked**.

## Mocked and hard-coded data

- Eight `sampleMediaItems` seed first-run storage.
- Profile identity, rank, join date, episode total, chapter total, and version
  display are hard-coded.
- Profile settings actions are empty callbacks.
- Unknown Jikan/TVMaze counts remain `null` and render as `?`.
- API base URLs and all user-visible strings are source constants.
- Avatar and sample cover images use public Unsplash URLs.

## TODO/FIXME inventory

No Dart `TODO` or `FIXME` comments were found. Android contains two template
TODOs:

- choose a production application ID;
- configure release signing instead of the debug key.

Incomplete behavior is mostly represented by no-op callbacks and fixed UI
content rather than TODO comments.

## Tooling and validation snapshot

| Command | Result |
| --- | --- |
| `flutter --version` | Exit 0. Flutter 3.41.6 stable, Dart 3.11.4, DevTools 2.54.2. |
| `dart --version` | Exit 0. Dart 3.11.4 on Windows x64. |
| `flutter pub get` | Exit 1. Pub reports authorization failure for `https://pub.dev` while resolving `flutter_lints`. |
| `flutter pub get --offline` | Exit 1. Cached package metadata cannot satisfy `flutter_lints ^3.0.0`. |
| `dart format lib test` | Exit 0. Twenty-four Dart files formatted; seven required changes, including the pre-existing formatting baseline requested by this task. Package-lint resolution warnings were emitted. |
| `dart format --output=none --set-exit-if-changed lib test` | Exit 0. Twenty-four Dart files checked; zero changes required. Package-lint resolution warnings were emitted. |
| `flutter analyze` | Exit 1 during dependency resolution with the same pub.dev authorization failure; source analysis did not start. |
| `flutter analyze --no-pub` | Exit 1 with 1,293 issues because package configuration and Flutter/package URIs are unavailable; this result is not a reliable source-code lint count. It also exposes the stale `MyApp` reference. |
| `flutter test` | Exit 1 during dependency resolution with the same pub.dev authorization failure; tests did not start. |
| `flutter test --no-pub` | Exit 1 before discovery because the unresolved package configuration hides `flutter_test`. |
| `flutter build web --debug --no-pub` | Exit 1 before compilation because `.dart_tool/package_config.json` does not exist. |

`pubspec.lock` was generated with constraints reporting Dart `>=3.12.0` and
Flutter `>=3.44.0`, newer than the installed SDK. Online package authorization
failed before a normal solve could confirm the full compatibility outcome.

## Existing technical debt

- UI widgets own orchestration and asynchronous state; this is manageable at
  current scale but has no structured state-test seam.
- Service methods catch every failure and return `[]`, so the search screen's
  exception error branch is normally unreachable with the real service.
- Debounced searches do not cancel or order in-flight requests; older results
  can replace newer ones.
- Persistence has no corruption signal, explicit schema version, or atomic
  domain migration strategy. New fields use tolerant defaults instead.
- Typography names are referenced but fonts are not bundled in `pubspec.yaml`.
- Hive, Hive Flutter, and path provider are unused dependencies.
- Source formatting is clean for `lib/` and `test/`; lint packages still
  cannot resolve.

## Recommended next implementation areas

These are recommendations, not confirmed product requirements:

1. Restore a reproducible Flutter/package environment and establish a valid
   analyzer/test baseline.
2. Replace or repair the stale template widget test.
3. Define explicit API failure semantics so loading, empty, and error states
   are distinguishable.
4. Confirm which Profile/settings affordances are real requirements before
   implementing them.
5. Complete Android release configuration before distribution work.
