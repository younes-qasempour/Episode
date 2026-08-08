# Current State

Snapshot verified on **2026-08-01** on branch
`feature/media-import-export-v2` with Flutter 3.44.8 and Dart 3.12.2.

## Feature status

| Area | Status | Evidence | Important files | Notes |
| --- | --- | --- | --- | --- |
| App shell and tabs | Complete | Material root, IndexedStack, three destinations, and pushed detail/manual/data/auth routes | `lib/main.dart`, `lib/screens/main_navigation_screen.dart` | Auth drawer, device management, and data management integrated. |
| Local library load/save | Functional | Schema V2 envelope, backward-compatible whole-list JSON CRUD, soft deletes, tombstones, and snapshot transactions | `lib/repositories/local_storage_repository.dart`, `lib/models/media_item.dart` | V1 to V2 migration support with rollback protection. |
| Home library | Complete | In-library search, Media Type & Status filter chips, sorting (Recently Updated, Title, Rating, Completion %), Favorites toggle, stats, state-aware cards, detail navigation, manual add, and uncapped `+1` | `lib/screens/home_tab.dart`, `lib/widgets/media_card.dart` | Multi-axis filtering, 4-way sorting, fast search, and 1-tap favorites. |
| Remote discovery | Functional | Jikan anime/manga (with Kitsu fallback) and TVMaze requests map to `MediaItem` | `lib/services/api_service.dart`, `lib/screens/search_tab.dart` | TVMaze embedded season enrichment, Kitsu fallback, and Jikan 429 rate limit pacing. |
| Manual add and detail editing | Complete | Anime/manga/series/movie, unknown totals, flat/seasonal progress, automatic completion progress, per-season completion, status sync, custom cover URL, save/delete | manual/detail screens, `MediaItem`, and tests | Automatic completion maxes known totals; per-season completion supported; status syncs on progress changes. |
| Native backup/restore | Functional on Android/web | Schema v1 JSON, SHA-256, v0 migration, preview, full restore, safety backup, rollback | transfer repository, native codec, data screens | Portable files and local snapshots are unencrypted. |
| MAL file transfer | Functional | Anime/manga XML and XML.GZ import, XML export for known MAL IDs, warnings and limits | `lib/services/mal_xml_service.dart`, fixtures/tests | Local XML parsing and export supported. |
| CSV export | Functional | UTF-8 BOM, stable headers, escaping, Unicode and metadata coverage | `lib/services/csv_export_service.dart` | CSV re-import is not implemented. |
| Profile & Personal Analytics | Complete | Milestone counters, estimated watch/read time, mean score indicator, interactive Donut Chart (Type/Status), top genres, favorites shelf, quick progress strip, 30-day activity heatmap & streak counter, personal bio customization, shareable stats flex card, auth/cloud sync, dark/light theme | `lib/screens/profile_tab.dart`, `lib/widgets/profile_stats_dashboard.dart`, `lib/widgets/streak_heatmap.dart`, `lib/widgets/donut_chart.dart` | Complete visual analytics hub with zero-dependency CustomPainter donut chart, contribution heatmap grid, and profile customization persistence. |
| Smart Collections & Binge Mode | Complete | Smart Collections filter bar (Favorites, Top Rated ≥8.0, Binge Worthy, On-Going, Classics), Binge Mode quick batch progress (+1, +5, +10), activity history logging, Hero cover animations, Adaptive ambient color headers, Shimmer Skeleton loading | `lib/screens/home_tab.dart`, `lib/screens/media_detail_screen.dart`, `lib/widgets/media_card.dart`, `lib/widgets/shimmer_skeleton.dart`, `lib/models/activity_log_entry.dart` | Full Smart Collections filtering, binge batch increments, hero cover transitions, and shimmer skeleton loading states. |

## Data-transfer behavior

- Entry matching order is exact external ID, exact Unicode-normalized title and
  type, then cautious similar-title detection.
- Uncertain or ambiguous title matches are previewed and skipped automatically.
- Strategies are merge safely, add only, replace matching, and native-only full
  restore; conflict policies are safe merge, keep local, use imported, and skip.
- Safe merge never lowers progress, overwrites local notes, or flattens local
  seasonal progress.
- All imports/restores create a retained native safety backup before mutation.
- Native backup input is capped at 20 MB; MAL input at 10 MB compressed and
  25 MB expanded. XML entity/doctype declarations are rejected.
- Large native/MAL input uses `compute` (a background isolate where the platform
  supports isolates). Parsing is bounded but DOM-based for XML; Flutter web
  still executes compute work on its main event loop.

See [features/data-backup-and-transfer.md](features/data-backup-and-transfer.md)
and [BACKUP_SCHEMA.md](BACKUP_SCHEMA.md).

## Mocked and hard-coded data

- Eight `sampleMediaItems` seed only a genuinely missing first-run storage key.
- Profile identity, rank, join date, activity totals, and version are fixed.
- Notification and About profile actions are non-functional.
- API base URLs and user-visible strings are source constants.
- The profile avatar and sample covers use public URLs with visual fallbacks.

## Tooling and validation snapshot

| Command | Result |
| --- | --- |
| `flutter --version` | Exit 0. Flutter 3.44.8 stable; Dart 3.12.2. |
| `flutter pub get` | Exit 0. Online dependency resolution completed. |
| `flutter pub get --offline` | Exit 0 using the approved local cache; generated `pubspec.lock`/package configuration. |
| Transfer-focused tests | Six new files declare 33 tests; all are included in the passing full suite. The initial targeted command passed 30/30 before three final regression cases were added. |
| `flutter analyze --no-pub` | Exit 0. No issues found. |
| `flutter test --no-pub` | Exit 0. 79/79 tests passed. |
| `flutter build apk --debug --no-pub` | Exit 1 after 185.9 s because Gradle could not resolve `com.android.application` 9.0.1 from configured repositories. |
| `flutter build web --no-pub` | Exit 0 after 34.8 s on the final run; `build/web` produced successfully and Wasm dry run succeeded. |

| `dart format .` | Exit 0. 44 files formatted; zero changes required. |
| `dart format --output=none --set-exit-if-changed .` | Exit 0. 44 files checked; zero changes required. |
| `flutter analyze` | Exit 0. No issues found. |
| `flutter test` | Exit 0. 79/79 tests passed. |

Manual browser smoke validation opened the release web artifact, navigated
Home -> Profile -> Data, Backup & Transfer, verified the responsive dashboard,
and created a native backup; the UI reported **Backup saved.** Transfer history
then displayed the completed full-backup record with eight processed items.

## Existing technical debt

- Remote API errors remain indistinguishable from valid empty results.
- Debounced searches do not cancel/order in-flight requests.
- The active library JSON has tolerant additive decoding but no explicit
  versioned envelope; portable native backups do have a schema/migration chain.
- SharedPreferences, automatic snapshots, and exported files are unencrypted.
- Individual override of uncertain import matches is not implemented.
- MAL OAuth/account import is not implemented.
- Typography names are referenced but fonts are not bundled.
- Hive, Hive Flutter, and path provider remain unused dependencies.
- Android release identity/signing/network-permission work remains.

## Recommended next implementation areas

These are recommendations, not confirmed product requirements:

1. Verify MAL import/export with fresh real anime and manga account exports.
2. Restore Android Gradle plugin resolution and run an emulator/device manual
   backup-import-restore cycle.
3. Add per-entry resolution for uncertain import matches if product scope
   requires manual conflict editing.
4. Define API failure semantics and request-order protection.
5. Decide encryption/cloud/account requirements before storing account data.
