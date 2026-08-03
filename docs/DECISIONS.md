# Architecture Decisions

These records describe implementation choices confirmed by the repository.
Unless noted, the original date and rationale are unknown.

## ADR-001 — Widget-local state and callbacks

- **Date:** Unknown
- **Status:** Accepted (inferred from current implementation)
- **Context:** Theme, navigation, library, filters, search, and detail-edit state
  must be coordinated in a small Flutter app.
- **Decision:** Use `StatefulWidget`, `setState`, constructor values, and
  callbacks; do not use an external state-management package.
- **Evidence:** `lib/main.dart` and every stateful screen.
- **Consequences:** Low dependency/abstraction cost; async and cross-screen
  state remain manually coordinated and state-specific tests use widget seams.
- **Alternatives:** Unknown.
- **Affected files:** `lib/main.dart`, `lib/screens/`.

The repository confirms this implementation choice, but the original rationale
is not documented.

## ADR-002 — Flutter-native navigation

- **Date:** Unknown
- **Status:** Accepted (inferred)
- **Context:** The app currently has three primary destinations and one detail
  screen.
- **Decision:** Use `MaterialApp.home`, `BottomNavigationBar` with
  `IndexedStack`, and `Navigator.push(MaterialPageRoute)` for detail.
- **Evidence:** `main.dart`, `main_navigation_screen.dart`.
- **Consequences:** Navigation is direct and simple; named routing, deep links,
  URL state, and route guards are absent.
- **Alternatives:** No other router is present.
- **Affected files:** `lib/main.dart`, `lib/screens/main_navigation_screen.dart`.

## ADR-003 — Repository boundaries for data access

- **Date:** Unknown
- **Status:** Accepted (inferred)
- **Context:** UI needs remote discovery and local library mutations.
- **Decision:** Screens call `SearchRepository` and
  `LocalStorageRepository`; remote request details remain in `ApiService`.
- **Evidence:** `lib/repositories/`, `lib/services/api_service.dart`, shell and
  Explore screens.
- **Consequences:** Data access has test seams, although repositories are thin
  and there is no separate domain/use-case layer.
- **Alternatives:** Direct UI access is not used.
- **Affected files:** `lib/repositories/`, `lib/services/`, `lib/screens/`.

## ADR-004 — SharedPreferences JSON as the active local store

- **Date:** Unknown
- **Status:** Accepted (current state)
- **Context:** A local media collection must survive restarts.
- **Decision:** Store the entire `MediaItem` list as one JSON string under
  `otaku_log_media_items`; seed sample data only when the key is absent. Keep a
  valid empty list empty and surface invalid data without overwriting it.
- **Evidence:** `local_storage_repository.dart`, `mock_data.dart`.
- **Consequences:** Simple CRUD and tests; no active-store envelope schema or
  query capability. Transfer replacement adds snapshot rollback and corruption
  feedback at the repository boundary.
- **Alternatives:** Hive packages are declared but no Hive implementation or
  migration decision exists.
- **Affected files:** `lib/repositories/local_storage_repository.dart`,
  `lib/data/mock_data.dart`, `lib/models/media_item.dart`.

## ADR-005 — Manual constructor injection

- **Date:** Unknown
- **Status:** Accepted (inferred)
- **Context:** Production defaults and test doubles are both required.
- **Decision:** Accept optional clients/repositories/services in constructors
  and instantiate defaults when omitted.
- **Evidence:** `ApiService`, `SearchRepository`, `SearchTab`,
  `MainNavigationScreen`, and related tests.
- **Consequences:** No container dependency; composition is explicit but
  defaults are distributed among constructors.
- **Alternatives:** No DI container is present.
- **Affected files:** service, repositories, shell, Explore, tests.

## ADR-006 — Technical-responsibility folder structure

- **Date:** Initial implementation; exact date unknown
- **Status:** Accepted
- **Context:** The repository is a compact application with shared model/data
  flows.
- **Decision:** Organize `lib/` into `screens`, `widgets`, `models`,
  `repositories`, `services`, `data`, and `theme`.
- **Evidence:** Current directory tree.
- **Consequences:** Responsibilities are easy to find at current scale;
  feature changes often cross several directories.
- **Alternatives:** A feature-first layout is not present.
- **Affected files:** all `lib/` paths.

## ADR-007 — Central Material 3 theme with local literals

- **Date:** Unknown
- **Status:** Accepted, partially centralized
- **Context:** Light/dark brand presentation is required.
- **Decision:** Define base `ThemeData`, core colors/radii, and status colors in
  `AppTheme`; screens may currently contain feature-specific literals.
- **Evidence:** `lib/theme/app_theme.dart` and screen/widget styling.
- **Consequences:** Global theme switching works, but design tokens and
  typography assets are incomplete.
- **Alternatives:** Unknown.
- **Affected files:** `lib/theme/app_theme.dart`, presentation files,
  `DESIGN.md`.

## ADR-008 — Additive flexible-progress model on SharedPreferences

- **Date:** 2026-07-25
- **Status:** Accepted
- **Context:** Provider counts can be absent or stale; manual media and
  multi-season tracking must coexist with existing flat library JSON.
- **Decision:** Keep `MediaItem` and SharedPreferences as the shared
  model/store. Represent unknown totals as `null`, add typed release/progress
  concepts and `MediaSeason`, keep legacy tracking-status strings compatible,
  and use tolerant additive decoding. Flat values are authoritative in flat
  mode; seasons are authoritative in seasonal mode. Legacy aggregate JSON keys
  remain for compatibility, while inactive flat snapshots make conversion
  reversible. Progress never auto-completes or clamps to a total.
- **Rationale:** This satisfies the data-integrity and user-flow requirements
  without a parallel model, database migration, state package, router, or API
  client.
- **Consequences:** Existing records load without migration and new values
  survive restart. There is still no explicit schema version, and callers must
  use active aggregate getters rather than treating flat snapshots and seasons
  as simultaneous authorities.
- **Alternatives considered:** Fabricated totals and hard caps were rejected
  as incorrect. One library item per season was rejected because the requested
  default is one item containing seasons. A second persistence engine was
  rejected by the existing architecture and migration risk.
- **Affected files:** `lib/models/media_item.dart`,
  `lib/repositories/local_storage_repository.dart`,
  `lib/services/api_service.dart`, presentation flows, tests, and data docs.

## ADR-009 - Provider-based preview-first local data transfer

- **Date:** 2026-08-01
- **Status:** Accepted
- **Context:** Users need reliable local backup/restore and interoperability
  without introducing an account, second persistence engine, or format logic
  in widgets. Import can overwrite valuable progress and notes, so parsing and
  persistence must not be one step.
- **Decision:** Keep `LocalStorageRepository` as the only persistence boundary.
  Add `ImportProvider`/`ExportProvider` format contracts, a canonical
  `ImportedMediaEntry`, `ImportPlanner` for deterministic matching/policy, and
  `MediaTransferRepository` for inspect/preview/safety-backup/apply/history.
  Native backups use a versioned schema with migrations and SHA-256 integrity.
  Whole-library changes use snapshot, full write, round-trip verification, and
  rollback. Android/web file I/O stays behind conditional adapters.
- **Rationale:** Providers make formats extensible while preview and a retained
  native snapshot keep all destructive behavior explicit and recoverable.
  Reusing the one-key SharedPreferences library avoids a risky parallel store.
- **Consequences:** Native JSON, MAL XML/XML.GZ, and CSV export share one
  orchestration flow; uncertain matches fail safe; history and five safety
  backups add local storage. SharedPreferences is still plaintext and does not
  offer OS-level transactions. XML parsing is bounded and offloaded for large
  inputs but remains DOM-based.
- **Alternatives considered:** Direct parsing/writing in screens was rejected
  because it bypasses repositories and is difficult to test. A new database or
  state package was rejected by current architecture. Blind title merge was
  rejected as unsafe. Account-based MAL import was deferred because client and
  secure-token requirements are unavailable.
- **Affected files:** transfer models/repository/services/screens, local
  repository, Android runner, `MediaItem`, tests, and backup/feature docs.
