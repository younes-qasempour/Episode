# Agent Changelog

This records work performed by coding agents. It is not a product release
changelog.

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
