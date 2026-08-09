# Task Board

Only verified repository work is listed. Recommendations are not product
commitments. Last reviewed: **2026-08-09**.

## Active

None.

## Ready

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Blocked

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-005 | Complete Android release setup | Replace template identity/signing and confirm release network access | Android release | Owner application ID and signing process | `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` | Non-secret release configuration is documented and a release build is validated | 2026-07-25 |

## Needs clarification

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-006 | Confirm Profile scope | Decide whether identity, statistics, notification, sync, settings, and About rows are product requirements or visual placeholders | Profile | Product-owner decisions | `profile_tab.dart` | Each affordance is marked for implementation/removal and acceptance criteria are supplied | 2026-07-25 |
| OTAKU-007 | Confirm synopsis editing | Decide whether synopsis is provider-owned read-only text or user-editable | Media detail | Product/data ownership decision | `media_detail_screen.dart`, `media_item.dart` | Controller/display behavior is aligned with the confirmed ownership model and tested | 2026-07-25 |
| OTAKU-008 | Confirm first-run seed behavior | Decide whether sample items should populate a real user's library | Local library | Product onboarding decision | `mock_data.dart`, `local_storage_repository.dart` | Empty/first-run behavior is explicitly specified and tested | 2026-07-25 |

## Completed recently

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-000 | Agent documentation bootstrap | Establish evidence-based shared memory and workflow | Repository-wide | None | `AGENTS.md`, `docs/` | Architecture/state/maps/workflow/templates exist, links validate, and production code is unchanged | 2026-07-25 |
| OTAKU-001 | Restore Android build resolution | Produce an Android debug APK on the documented SDK | Tooling | None | Android Gradle configuration/cache | `flutter build apk --debug --no-pub` succeeds | 2026-08-09 |
| OTAKU-003 | Define API failure semantics | Distinguish transport/parse failures from valid empty results | Explore | None | `api_service.dart`, `search_repository.dart`, `search_tab.dart`, tests | Typed result contract is documented and tested; loading, empty, error, and retry states are reachable | 2026-08-09 |
| OTAKU-004 | Protect search result ordering | Prevent an older request from replacing a newer query result | Explore | None | `search_tab.dart`, `search_tab_test.dart` | Regression tests prove latest query/category wins | 2026-08-09 |
| OTAKU-012 | Flexible manual media and progress tracking | Add manual anime/manga/series/movie creation, nullable totals, explicit release status, uncapped flat progress, and multi-season tracking | Library, Explore, media details | None | `media_item.dart`, local repository, API mappings, manual/detail/card screens, tests/docs | Existing JSON remains readable; unknown totals stay unknown; progress is uncapped; manual/movie/season flows persist and render consistently | 2026-07-25 |
| OTAKU-013 | Professional local data transfer | Add native backup/restore, MAL XML import/export, CSV, preview/conflicts, safety rollback, history, and Android/web file UX | Data backup and transfer | None | transfer models/repository/services/screens, Android runner, tests/docs | Preview precedes mutation; malformed data fails safe; restore rolls back; supported exports round-trip; analyzer/tests/web build pass | 2026-08-01 |
| OTAKU-002 | Replace stale counter test | Target the real app shell and pass with the full suite | App shell/testing | None | `test/widget_test.dart`, `lib/main.dart` | Test constructs `EpisodeApp`, asserts navigation, and passes | 2026-08-01 |
| OTAKU-011 | Establish formatting baseline | Apply and verify repository formatting | Tooling | None | `lib/`, `test/`, docs unaffected | `dart format .` and no-change check exit 0 | 2026-08-01 |

## Technical debt

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-009 | Decide unused persistence dependencies | Remove unused packages or document an approved migration | Data/tooling | OTAKU-001; persistence decision if migration chosen | `pubspec.yaml` | Hive/Hive Flutter/path provider are either removed through normal resolution or used by one documented persistence strategy | 2026-07-25 |
| OTAKU-010 | Align typography implementation | Bundle licensed fonts or stop claiming unavailable families | Design system | Font/licensing assets | `pubspec.yaml`, `app_theme.dart`, screens | Typography renders consistently on target platforms and docs match | 2026-07-25 |
