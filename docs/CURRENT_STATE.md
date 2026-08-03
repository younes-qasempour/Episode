# Current State

Snapshot verified on **2026-08-01** on branch
`feature/media-import-export-v2` with Flutter 3.44.8 and Dart 3.12.2.

## Feature status

| Area | Status | Evidence | Important files | Notes |
| --- | --- | --- | --- | --- |
| App shell and tabs | Complete for current scope | Material root, IndexedStack, three destinations, and pushed detail/manual/data routes | `lib/main.dart`, `lib/screens/main_navigation_screen.dart` | No deep links or named router. |
| Local library load/save | Functional | Backward-compatible whole-list JSON CRUD, valid empty library, visible corruption errors, verified replacement rollback | `lib/repositories/local_storage_repository.dart`, `lib/models/media_item.dart` | Active storage is still plaintext SharedPreferences without an envelope schema. |
| Home library | Functional but incomplete | Search/type filters, stats, state-aware cards, details, manual add, and uncapped `+1` | `lib/screens/home_tab.dart`, `lib/widgets/media_card.dart` | Seasonal card increment targets the latest ongoing season. |
| Remote discovery | Functional but incomplete | Jikan anime/manga and TVMaze map to `MediaItem` with provider IDs | `lib/services/api_service.dart`, `lib/screens/search_tab.dart` | No pagination, timeout, retry, rate-limit handling, or visible transport error. |
| Manual add and detail editing | Functional | Anime/manga/series/movie, unknown totals, flat/seasonal progress, statuses, seasons, score, synopsis, save/delete | manual/detail screens and tests | Save/delete callbacks remain synchronous at the detail-screen boundary. |
| Native backup/restore | Functional on Android/web | Schema v1 JSON, SHA-256, v0 migration, preview, full restore, safety backup, rollback | transfer repository, native codec, data screens | Portable files and local snapshots are unencrypted. |
| MAL file transfer | Functional with release verification needed | Anime/manga XML and XML.GZ import, XML export for known MAL IDs, warnings and limits | `lib/services/mal_xml_service.dart`, fixtures/tests | Live official MAL export documentation was inaccessible; verify a fresh real export before release. |
| CSV export | Functional | UTF-8 BOM, stable headers, escaping, Unicode and metadata coverage | `lib/services/csv_export_service.dart` | CSV re-import is not implemented. |
| Transfer history/recovery | Functional | Latest 25 summaries; latest five automatic safety backups can be saved | history screen, local/transfer repositories | Retention is count-based, local, and unencrypted. |
| Profile | Partially functional | Theme and data-management actions work | `lib/screens/profile_tab.dart` | Identity/statistics, notification, and About content remain fixed/no-op. |
| Theme switching | Functional but incomplete | Light/dark themes and in-memory switch | `lib/main.dart`, `lib/theme/app_theme.dart` | Choice is not persisted; system mode cannot be reselected in UI. |
| Tests | Passing | Fifteen Dart files declare 79 tests | `test/` | `flutter test --no-pub` passes 79/79. |
| Android debug build | Environment-blocked | Gradle cannot resolve Android application plugin 9.0.1 | Android Gradle configuration/cache | Dart analysis/tests pass; Android platform code did not reach compilation in this environment. |
| Web build | Passing | Browser file adapter compiles in release web build | `web/`, file transfer web service | `flutter build web --no-pub` succeeds. |
| iOS/desktop | Not implemented | No runner directories | repository roots | File-transfer adapter reports unsupported platform. |

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
