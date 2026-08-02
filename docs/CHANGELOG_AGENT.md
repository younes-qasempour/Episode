# Agent Changelog

This records work performed by coding agents. It is not a product release
changelog.

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
