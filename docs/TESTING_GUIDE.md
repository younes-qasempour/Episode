# Testing Guide

## Current structure

All automated tests are under `test/`; no integration-test or golden-test
directory exists. Twenty-two Dart files currently pass **154 tests**.

| Area | Primary files | Coverage |
| --- | --- | --- |
| API/search | `api_service_test.dart`, `search_repository_test.dart`, `search_tab_test.dart` | Provider mapping, typed failures, retry/fallback, result ordering, Explore rendering/add state |
| Library/model | `media_item_test.dart`, `local_storage_repository_test.dart` | Serialization, legacy/defaults, seed/empty/corrupt storage, CRUD/progress/seasons |
| Manual/detail/card/shell | manual/detail/card/widget test files | Visible forms, progress states, callbacks, real app shell |
| Native backup | `native_backup_service_test.dart` | Full-field round trip, checksum, v0 migration, future schema, invalid entry |
| MAL transfer | `mal_xml_service_test.dart`, `test/fixtures/` | Anime/manga, gzip, empty/malformed/unsafe/status/ID cases, Unicode export |
| CSV | `csv_export_service_test.dart` | BOM, escaping, Unicode, filtering |
| Planning/orchestration | `import_planner_test.dart`, `media_transfer_repository_test.dart` | Matching, strategies, safe merge, full restore, rollback, safety retention |
| Transfer UI | `data_management_screen_test.dart` | Actions, cancellation, conflict warning, explicit empty restore |
| Analytics/activity | stats/dashboard/activity/smart-collection test files | Derived stats, chart modes, activity streaks, smart filters, binge progress |

## Test techniques

- `SharedPreferences.setMockInitialValues` isolates local preference state.
- Constructor injection supplies repositories, services, file adapters, and
  HTTP fakes.
- MAL fixtures include official-style anime/manga, gzip source generation,
  malformed, empty, missing-ID, and unknown-status examples.
- Repository transaction validation is injectable to force a deterministic
  critical-write failure and prove rollback.
- Widget tests resize/scroll only when interaction requires it and avoid live
  image success assumptions.

## Commands

```bash
flutter test --no-pub
flutter test --no-pub test/native_backup_service_test.dart
flutter test --no-pub test/mal_xml_service_test.dart
flutter test --no-pub test/media_transfer_repository_test.dart
flutter test --coverage
```

Offline package resolution must have produced `.dart_tool/package_config.json`
before `--no-pub` commands. Coverage has no enforced threshold.

## Verified status

On 2026-08-09 with Flutter 3.44.8/Dart 3.12.2:

- six transfer-focused files declare 33 tests; all pass in the full suite (the
  initial targeted command passed 30/30 before three final regressions);
- focused API/search suite: 30/30 passed;
- full `flutter test --no-pub`: 154/154 passed;
- `flutter analyze --no-pub`: no issues;
- web release build: passed;
- release-web browser smoke: Home -> Profile -> Data, Backup & Transfer rendered
  and a native backup action reported `Backup saved.`; transfer history showed
  the completed backup with eight processed items;
- Android debug build: passed and produced `app-debug.apk`.

The application-shell test constructs `EpisodeApp` and verifies the
actual three-destination shell.

## Coverage limitations

- No end-to-end platform picker/save automation or device integration tests
- No fresh real-account MAL export fixture checked in (release manual check is
  required)
- No CSV import, MAL OAuth, or per-entry uncertain-conflict UI because those
  behaviors are not implemented
- No accessibility, golden, platform integration, or broad responsive-layout
  suite

## Expectations for new work

- Business/model/repository changes require unit tests.
- State changes require a focused widget test using constructor seams.
- Every import provider needs valid, malformed, empty, Unicode, duplicate,
  oversized, and representative round-trip cases where export exists.
- Persistence changes need backward-compatibility, failure, and rollback tests.
- Keep tests deterministic: inject dependencies and never require live API or
  image responses.

## Naming

Use sentence-style behavior names grouped by unit. State the condition and
observable result rather than the implementation detail.
