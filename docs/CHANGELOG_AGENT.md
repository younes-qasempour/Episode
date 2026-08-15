# Agent Changelog

This records work performed by coding agents. It is not a product release
changelog.

## 2026-08-12 - Indigo navigation rail selection

- **Agent/tool:** Codex
- **Task:** Replace the muddy red-brown selected navigation-rail color shown in
  the dark desktop sidebar.
- **Summary:** Scoped the active rail state to the existing Episode indigo
  token with a high-contrast white icon in both light and dark themes, without
  changing the secondary palette used by other components. Added focused theme
  coverage for the adaptive rail.
- **Files changed:** `lib/theme/app_theme.dart`,
  `test/responsive_layout_test.dart`, `docs/features/profile-and-theme.md`, and
  `docs/CHANGELOG_AGENT.md`.
- **Validation:** `dart format --output=none --set-exit-if-changed lib test`
  checked 81 files with zero changes; `flutter analyze --no-pub` reported no
  issues; the focused responsive suite passed 6/6; and
  `flutter test --no-pub` passed 163/163.

## 2026-08-12 - Episode brand and logo integration

- **Agent/tool:** Codex
- **Task:** Complete the product rename to Episode and apply the approved logo
  consistently across Flutter, Android, web, and Windows surfaces.
- **Summary:** Added a canonical accessible `EpisodeBrand` widget and declared
  runtime mark; integrated it into app chrome, authentication, and loading
  states; generated Android legacy/round/adaptive launcher icons and pre-/post-
  Android-12 splash artwork; updated web title/metadata, favicon, Apple touch
  icon, PWA regular/maskable icons, and pre-first-frame loading splash; updated
  Windows executable identity/icon; and added high-resolution masters plus
  `tool/generate_brand_assets.py` for reproducible outputs. Updated active
  product documentation to Episode while preserving and explicitly labeling
  stable legacy storage, backup-format, repository-folder, and backend
  deployment identifiers, and synchronized the internal file-transfer channel
  to the Episode name across all native implementations. Unified sync safety
  snapshots with the restorable native Episode backup codec, added download-
  time conversion for retained legacy local snapshots, and made the web splash
  cleanup reliable when reduced motion disables CSS transitions.
- **Compatibility:** Active library, automatic-backup, and transfer-history
  preferences use `episode_media_items`, `episode_automatic_backups_v1`, and
  `episode_transfer_history_v1` with one-time `otaku_log_*` fallbacks. The
  `otakulog-backup` payload discriminator remains stable to avoid breaking
  existing files; the non-persistent native channel is now
  `episode/file_transfer` across Dart, Android, and Windows.
- **Validation:** Asset generator completed with 29 deterministic outputs;
  `flutter analyze --no-pub` reported no issues; the focused brand/shell tests
  passed, and the full suite (including transfer/backup coverage) passed
  162/162 with `flutter test --no-pub`; Android debug, web release, and Windows
  release builds succeeded. Browser
  smoke checks at 390x844 and 1440x900 verified the loading splash, app chrome,
  manifest/favicon assets, responsive brand placement, and zero console errors.

## 2026-08-12 — Responsive Web and Windows platform support

- **Agent/tool:** Codex
- **Task:** Evolve Episode's mobile-first Flutter UI into a responsive Android,
  web, and Windows application without changing its business architecture.
- **Summary:** Added centralized intent breakpoints, max-width/page/grid helpers,
  adaptive bottom/rail navigation, responsive Home and Explore grids, two-pane
  media details, constrained forms and transfer screens, denser analytics,
  desktop dialog constraints, and pointer scrolling. Generated the official
  Windows runner, reused the transfer MethodChannel for native Win32 open/save
  dialogs, and preserved secure token storage with an ATL-free compatibility
  include for the existing plugin. Added live-resize and representative
  viewport widget tests.
- **Files changed:** `lib/layout/responsive_layout.dart`, root shell and major
  screens/widgets, `lib/services/file_transfer_io.dart`, `windows/`,
  `test/responsive_layout_test.dart`, and affected project documentation.
- **Validation:** See the 2026-08-12 command matrix in `CURRENT_STATE.md`.

## 2026-08-09 — Resolved Episode mobile integration conflicts

- **Agent/tool:** Codex
- **Task:** Resolve the diverged `main` branch conflicts, validate the combined mobile changes, commit, and push.
- **Summary:** Preserved the typed `SearchResult` failure contract and ten-second request timeout from the local search-hardening commit while integrating the incoming Episode package rename, required API user-agent header, and cover URL sanitization. Updated conflicted tests to use the renamed `episode` package without losing error, fallback, retry, and stale-request coverage. Fixed analyzer issues in the incoming profile dashboard by using typed `MediaItem` getters, removing unused values, and making constant declarations explicit; made the chart-mode widget test scroll its target onscreen before tapping.
- **Files changed:** Conflict resolutions in `lib/services/api_service.dart`, `test/api_service_test.dart`, `test/search_repository_test.dart`, and `test/search_tab_test.dart`; integration fixes in `lib/screens/main_navigation_screen.dart`, `lib/widgets/donut_chart.dart`, `lib/widgets/profile_stats_dashboard.dart`, and `test/profile_stats_dashboard_test.dart`; formatting normalized across incoming Dart files.
- **Validation:** `flutter pub get` succeeded; focused API/search tests passed 30/30; formatting completed; `flutter analyze --no-pub` found no issues; the full Flutter suite passed 154/154; `flutter build web --no-pub --no-wasm-dry-run` succeeded after refreshing stale pre-rename build metadata; `flutter build apk --debug --no-pub` produced the debug APK successfully.

## 2026-08-08 — Favorites, Smart Collections, Binge Mode & Glassmorphism Visual Polish

- **Agent/tool:** Antigravity
- **Task:** Implement Smart Collections, Binge Mode (+5/+10 increments), Activity History & 30-Day Heatmap, Hero image transitions, Adaptive ambient color headers, and Shimmer skeleton loading on branch `feat/favorites-binge-polish`.
- **Summary:** Added **Smart Collections** filter bar on `HomeTab` (*Favorites, Top Rated ≥8.0, Binge Worthy, On-Going Series, Classics*). Added `ActivityLogEntry` and `StreakCalculator` for daily watching/reading activity logging and streak calculation. Created `StreakHeatmap` 30-day contribution grid and streak badge in `ProfileStatsDashboard`. Added Binge Mode batch progress buttons (`+1`, `+5`, `+10`) in `MediaDetailScreen`, `MediaCard`, and `ProfileTab`. Wrapped cover images in `Hero(tag: 'media_cover_${item.id}')` for smooth card-to-detail page transitions. Implemented frosted glass (`BackdropFilter`) ambient color headers in `MediaDetailScreen`. Created zero-dependency `ShimmerSkeletonGrid` widget replacing spinners in `SearchTab`. Added unit test suites (`activity_log_test.dart` and `smart_collections_test.dart`).
- **Files changed:** `lib/models/activity_log_entry.dart`, `lib/widgets/shimmer_skeleton.dart`, `lib/widgets/streak_heatmap.dart`, `lib/repositories/local_storage_repository.dart`, `lib/screens/home_tab.dart`, `lib/screens/media_detail_screen.dart`, `lib/screens/search_tab.dart`, `lib/screens/profile_tab.dart`, `lib/screens/main_navigation_screen.dart`, `lib/widgets/media_card.dart`, `lib/widgets/profile_stats_dashboard.dart`, `test/activity_log_test.dart`, `test/smart_collections_test.dart`, `docs/CURRENT_STATE.md`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter test` (139/139 tests passed cleanly).

## 2026-08-08 — Personal Dashboard & Viewing Analytics Hub (Profile Tab Upgrade)

- **Agent/tool:** Antigravity
- **Task:** Transform Profile tab into a visual analytics hub on branch `feat/profile-stats-dashboard` with milestone counters, estimated watch/read time, mean score indicator, custom animated Donut Chart (Type & Status modes), top genres, favorites showcase shelf, quick progress strip, personal bio customization, and shareable stats card.
- **Summary:** Created `LibraryStats` domain calculator for episodes watched, chapters read, movies watched, estimated watch/read hours, mean score, and type/status segment percentages. Created `UserProfileData` customization model with avatar accent color tint and quote. Implemented zero-dependency `DonutChart` widget powered by `CustomPainter` with smooth animated sweep angles and interactive legend. Integrated `ProfileStatsDashboard` into `ProfileTab` and `MainNavigationScreen`. Added `saveUserProfileData` and `loadUserProfileData` in `LocalStorageRepository`. Added unit and widget test suites (`library_stats_test.dart` and `profile_stats_dashboard_test.dart`).
- **Files changed:** `lib/models/library_stats.dart`, `lib/models/user_profile_data.dart`, `lib/widgets/donut_chart.dart`, `lib/widgets/profile_stats_dashboard.dart`, `lib/repositories/local_storage_repository.dart`, `lib/screens/profile_tab.dart`, `lib/screens/main_navigation_screen.dart`, `test/library_stats_test.dart`, `test/profile_stats_dashboard_test.dart`, `docs/CURRENT_STATE.md`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter test` (129/129 tests passed cleanly).

## 2026-08-08 — Renamed Application and Project from OtakuLog to Episode

- **Agent/tool:** Antigravity
- **Task:** Rename the application, project branding, package name, class names, UI titles, storage keys, and documentation to Episode.
- **Summary:** Updated `pubspec.yaml` to `name: episode`. Migrated all package imports from `package:otaku_log/...` to `package:episode/...`. Renamed root app widget `OtakuLogApp` to `EpisodeApp`. Updated storage keys in `LocalStorageRepository` to `episode_media_items`, `episode_automatic_backups_v1`, and `episode_transfer_history_v1` with automatic migration fallbacks to preserve existing user library data seamlessly. Updated web metadata, app headers, dialogs, user-agent headers, and unit/widget tests.
- **Files changed:** `pubspec.yaml`, `web/index.html`, `lib/main.dart`, `lib/config/app_config.dart`, `lib/repositories/local_storage_repository.dart`, `lib/repositories/media_transfer_repository.dart`, `lib/services/api_service.dart`, `lib/services/native_backup_service.dart`, `lib/services/mal_xml_service.dart`, `lib/services/device_identity_service.dart`, `lib/models/data_transfer.dart`, UI screens (`home_tab.dart`, `profile_tab.dart`, `login_screen.dart`, `register_screen.dart`, `data_management_screen.dart`, `import_preview_screen.dart`), test files under `test/`, `README.md`, `AGENTS.md`, `docs/PROJECT_OVERVIEW.md`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter test` (127/127 tests passed cleanly).

## 2026-08-08 — Fixed Explore Search Image & Web CORS Rendering Bug

- **Agent/tool:** Antigravity
- **Task:** Diagnose and resolve missing cover images when searching media items in Explore tab and when adding searched items to the local library.
- **Summary:** Added client `User-Agent: OtakuLog/1.0` header in `_getWithRetry` in `ApiService` to prevent Jikan search API gateway timeouts/blocks (504/403). Added `sanitizeCoverUrl` helper to sanitize and proxy non-CORS image hosts (like Kitsu API's `media.kitsu.app`) via `https://images.weserv.nl/?url=...` for Flutter Web cross-origin compatibility. Applied `sanitizeCoverUrl` across all provider mappers (`mapJikanAnimeToMediaItem`, `mapJikanMangaToMediaItem`, `mapKitsuAnimeToMediaItem`, `mapKitsuMangaToMediaItem`, `mapTvMazeToShowItem`). Added 2 unit tests in `test/api_service_test.dart`.
- **Files changed:** `lib/services/api_service.dart`, `test/api_service_test.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter test` (127/127 tests passed cleanly).

## 2026-08-04 — Automatic Completion Progress & Status Synchronization

- **Agent/tool:** Antigravity
- **Task:** Implement production-ready automatic completion progress for flat media and multi-season media, per-season completion actions, and automatic tracking status synchronization.
- **Summary:** Added `isComplete` & `completeSeason` to `MediaSeason`, and `isFullyCompleted`, `applyCompletedStatus`, `completeSeason`, and `syncStatusWithProgress` to `MediaItem`. Flat and multi-season items automatically max known totals when setting status to `Completed`. Multi-season items support per-season completion actions in `MediaDetailScreen` with visual `Completed ✓` badges and automatic overall item status completion when all seasons finish. Manually reducing progress from `Completed` automatically reverts tracking status to active status (`Watching` or `Reading` for Manga) without altering release status. Preserved unknown total safety. Added 10 new unit and widget test cases.
- **Files changed:** `lib/models/media_item.dart`, `lib/screens/media_detail_screen.dart`, `test/media_item_test.dart`, `test/media_detail_screen_test.dart`, `docs/CHANGELOG_AGENT.md`, `docs/CURRENT_STATE.md`, `docs/ARCHITECTURE.md`.
- **Validation:** `dart format .` (exit 0), `flutter analyze` (0 issues), `flutter test` (125/125 tests passed).

## 2026-08-01 - Professional media import, export, and backup

- **Agent/tool:** Codex
- **Task:** Implement production-oriented local import/export, native backup
  and restore, MyAnimeList XML interoperability, CSV export, recovery, tests,
  and developer documentation.
- **Summary:** Added provider-based inspection/export contracts, canonical
  imported entries, deterministic external-ID/Unicode-title matching, four
  strategies, four existing-entry policies, preview and result reporting,
  schema-v1 native backups with SHA-256 integrity and v0 migration, MAL
  anime/manga XML/XML.GZ import and XML export, UTF-8 CSV, automatic safety
  snapshots, verified single-key rollback, retained history, and Android/web
  file adapters. Wired a focused responsive Material data dashboard through
  Profile and surfaced corrupt active storage without destructive reseeding.
- **Files changed:** Transfer models/repository/services/screens; `MediaItem`
  metadata and API provider IDs; local storage transaction/recovery/history;
  Android `MainActivity`; Profile/shell/theme presentation; fixtures/tests;
  dependencies and affected repository documentation.
- **Backward compatibility:** Existing `MediaItem` constructors remain valid
  and missing metadata defaults to empty/null values. Existing library JSON
  remains a list. Missing storage still seeds samples, while valid empty
  storage remains empty and corrupt raw data is preserved. Legacy native
  backup schema 0 migrates to schema 1 before preview.
- **Validation:** Online/offline package resolution, formatting, targeted
  33-test transfer suite, full 79-test suite, static analysis, and web build
  pass. A release-web browser smoke check navigated through Profile to the data
  dashboard, completed a native backup download, and showed the saved operation
  in transfer history. Android debug build
  is blocked before Kotlin compilation because Gradle cannot resolve Android
  application plugin 9.0.1; no source failure was reported.
- **Documentation updated:** Project/current-state/architecture/codebase/data,
  decision/issues/glossary/task/profile/feature indexes; new transfer feature
  guide and native backup schema reference.
- **Unresolved:** Verify MAL compatibility with fresh real account exports;
  restore Android plugin resolution and perform device SAF checks; OAuth,
  per-entry uncertain-match override, streaming XML, encryption, iOS/desktop
  adapters, and CSV import are not implemented.

## 2026-07-29 — Added Smart Library Filtering, Sorting & Search (Home Tab)

- **Agent/tool:** Antigravity
- **Task:** Added Smart Library Filtering (Media Type & Status/Favorites chips), 4-way Sorting (Recently Updated, Title A-Z, Rating, Completion %), Fast In-Library Search with clear action, and 1-tap Favorites toggle.
- **Summary:** Extended `MediaItem` with `isFavorite` and `updatedAt` fields. Added `toggleFavorite` method to `LocalStorageRepository`. Rewrote `HomeTab` to feature fast title search, dual filter chip rows (Media Type & Status/Favorites), sort options selector dropdown, 1-tap card heart toggles, and an empty state reset button. Added `test/home_tab_test.dart` and updated `media_item_test.dart` and `local_storage_repository_test.dart`.
- **Files changed:** `lib/models/media_item.dart`, `lib/repositories/local_storage_repository.dart`, `lib/screens/home_tab.dart`, `lib/widgets/media_card.dart`, `lib/screens/main_navigation_screen.dart`, `lib/screens/media_detail_screen.dart`, `test/media_item_test.dart`, `test/local_storage_repository_test.dart`, `test/home_tab_test.dart`, `docs/features/local-library.md`, `docs/CURRENT_STATE.md`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` 0 errors/warnings. `flutter test` passed 56/56 tests cleanly. `flutter build web --release` compiled `build/web`.

## 2026-07-29 — Purged legacy sample items on load & added Clear Library Data button

- **Agent/tool:** Antigravity
- **Task:** Purged existing browser-stored sample items (IDs '1'-'8') automatically on app startup and added a 1-tap "Clear All Library Data" button in Profile/Settings.
- **Summary:** Updated `loadMediaItems` in `LocalStorageRepository` to filter out legacy sample items and persist clean empty storage. Added `clearAllMediaItems` method, wired `_clearLibrary` in `MainNavigationScreen`, and added a "Clear All Library Data" tile with a confirmation dialog in `ProfileTab`.
- **Files changed:** `lib/repositories/local_storage_repository.dart`, `lib/screens/profile_tab.dart`, `lib/screens/main_navigation_screen.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` 0 errors. `flutter test` 46/46 passed cleanly. `flutter build web --release` compiled `build/web`.

## 2026-07-29 — Removed sample items for clean fresh install library

- **Agent/tool:** Antigravity
- **Task:** Updated local storage repository so brand new app installations start with a completely empty library instead of loading default sample items.
- **Summary:** Updated `loadMediaItems` in `LocalStorageRepository` to return an empty list (`[]`) when no saved library items exist. Removed unused `mock_data.dart` import and updated test assertions.
- **Files changed:** `lib/repositories/local_storage_repository.dart`, `test/local_storage_repository_test.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` 0 errors. `flutter test` 46/46 passed cleanly. `flutter build web --release` compiled `build/web`.

## 2026-07-29 — Enhanced TVMaze season enrichment & human-friendly card labels

- **Agent/tool:** Antigravity
- **Task:** Enriched TV series search results with embedded season breakdowns and total episode counts; eliminated cold "Ch count: Unknown" card labels in favor of contextual status/count badges.
- **Summary:** Updated `_searchSeries` and `_enrichTvMazeShow` in `ApiService` to fetch TVMaze embedded seasons (`/shows/$id?embed=seasons`), populating `seasons` and `totalCount` by default. Enhanced `MediaCard` `progressText` logic to show clean status badges (e.g. `Ongoing · Publishing`, `Ongoing · Airing`, `5 Seasons · 62 Ep`, `272 chapters`) for unstarted or search items.
- **Files changed:** `lib/services/api_service.dart`, `lib/widgets/media_card.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` 0 errors. `flutter test` 46/46 passed cleanly. `flutter build web --release` compiled `build/web`.

## 2026-07-29 — Added Kitsu API fallback for Anime & Manga searches

- **Agent/tool:** Antigravity
- **Task:** Diagnosed and resolved Jikan API 504 Gateway Timeout errors on manga search queries by integrating Kitsu API fallback for Anime and Manga.
- **Summary:** Added `kitsuBaseUrl` (`https://kitsu.io/api/edge`) and mapping methods (`mapKitsuMangaToMediaItem`, `mapKitsuAnimeToMediaItem`) in `ApiService`. If Jikan API times out or returns 504/404/empty error states, `_searchManga` and `_searchAnime` automatically fall back to Kitsu, ensuring reliable search results for queries like "Jujutsu Kaisen", "JoJo", "One Piece", and "Naruto".
- **Files changed:** `lib/services/api_service.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` 0 errors. `flutter test` 46/46 passed cleanly. `flutter build web --release` compiled `build/web`.

## 2026-07-29 — Fixed Manga search 429 rate limits, search race conditions & custom cover editing

- **Agent/tool:** Antigravity
- **Task:** Resolved Manga search failure when searching "All", added custom cover URL editing for users in detail & manual views, prevented search race conditions, and handled API rate limits defensively.
- **Summary:** Added `_getWithRetry` and pacing delay between consecutive Jikan API calls in `ApiService` to prevent Jikan HTTP 429 rate limiting. Implemented `_searchRequestId` in `SearchTab` to discard stale out-of-order responses. Added custom cover URL editing via dialog and interactive header thumbnail in `MediaDetailScreen`. Updated test coverage.
- **Files changed:** `lib/services/api_service.dart`, `lib/screens/search_tab.dart`, `lib/screens/media_detail_screen.dart`, `test/media_detail_screen_test.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` 0 errors. `flutter test` 46/46 passed cleanly. `flutter build web --release` compiled `build/web`.

## 2026-07-29 — Fixed test suite & Material card assertion, verified web build

- **Agent/tool:** Antigravity
- **Task:** Pulled remote updates, fixed test suite assertion in `_sectionCard` and obsolete smoke test in `widget_test.dart`, ran analysis & 45/45 tests, built release web app.
- **Summary:** Updated `widget_test.dart` to test `OtakuLogApp` smoke test instead of obsolete `MyApp` template counter. Wrapped `_sectionCard` in a `Material` widget in `lib/screens/media_detail_screen.dart` to resolve Flutter Framework assertion regarding `ListTile` ink splashes on `DecoratedBox`.
- **Files changed:** `lib/screens/media_detail_screen.dart`, `test/widget_test.dart`, `docs/CHANGELOG_AGENT.md`.
- **Validation:** `flutter analyze` ran with 0 errors. `flutter test` passed all 45 tests cleanly. `flutter build web --release` compiled successfully (`build/web`).

## 2026-07-25 — Manual media and flexible progress tracking

- **Agent/tool:** Codex
- **Task:** Add manual anime/manga/series/movie creation, genuine unknown
  totals, uncapped progress, separate tracking/release status, and multi-season
  tracking while preserving existing SharedPreferences JSON.
- **Summary:** Extended `MediaItem` with nullable totals, typed domain parsing,
  `MediaSeason`, flat/seasonal modes, manual origin, derived aggregates, and
  reversible conversion. Removed provider fallback totals and automatic
  completion. Added manual creation, season editing, movie-specific UI,
  unknown/exceeded-total states, and contextual accessible card increments.
- **Files changed:** Shared model/repositories/API mapper; Home, Explore,
  manual, detail, theme, and card presentation; focused tests; affected
  architecture/data/feature/current-state/decision/issue/task documentation.
- **Backward compatibility:** Old records default to flat progress, unknown
  release status, empty seasons, and non-manual origin while preserving
  progress and positive totals. New seasonal records keep seasons
  authoritative and write aggregate legacy keys plus inactive flat snapshots.
- **Validation:** `dart format lib test` and its no-change check exit 0 across
  24 files. `dart analyze lib/models/media_item.dart` exits 0. A direct
  dependency-free model smoke script exits 0. Targeted Flutter tests,
  `flutter analyze`, and `flutter test` all exit 1 during package resolution
  because pub.dev rejects access to `flutter_lints`; no Flutter test discovery
  or source analysis runs.
- **Documentation updated:** `PROJECT_OVERVIEW.md`, `CURRENT_STATE.md`,
  `ARCHITECTURE.md`, `CODEBASE_MAP.md`, `DATA_AND_API.md`, `DECISIONS.md`,
  `GLOSSARY.md`, `KNOWN_ISSUES.md`, `TASK_BOARD.md`, all affected feature docs,
  and new `features/manual-media-and-progress.md`.
- **Unresolved:** The pre-existing package/toolchain blocker prevents
  trustworthy Flutter analysis/tests; storage corruption still falls back to
  samples; save/delete errors are not surfaced; remote movie search is out of
  scope; the stale unrelated template smoke test remains.

## 2026-07-25 — Agent-driven repository bootstrap

- **Agent/tool:** Codex
- **Task:** Inspect the existing OtakuLog repository and create an
  evidence-based shared-memory and workflow system.
- **Summary:** Documented product state, architecture, code ownership, design,
  data/API behavior, testing, decisions, issues, terminology, feature flows,
  task coordination, maintenance rules, and reusable templates. Corrected the
  root README's stale architecture claims and clarified the status of the
  original design specification. Production Dart/platform behavior was not
  changed.
- **Files changed:** `AGENTS.md`, `README.md`, `DESIGN.md`, and documentation
  under `docs/`.
- **Inspection/validation:** Flutter/Dart versions, Git state/history,
  repository files, dependency usage, TODOs, format check, package resolution,
  analyzer, tests, web build, link/path checks, and final diff. Exact baseline
  results are recorded in `CURRENT_STATE.md` and the task handoff.
- **Documentation updated:** Initial documentation system and four verified
  feature documents.
- **Unresolved:** Package registry/toolchain mismatch blocks trustworthy
  analysis/tests/build; stale template test; Android release configuration;
  placeholder Profile behavior; API/persistence error semantics; formatting
  baseline.
