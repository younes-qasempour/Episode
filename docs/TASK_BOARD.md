# Task Board

Only verified repository work is listed. Recommendations are not product
commitments. Last reviewed: **2026-07-25**.

## Active

None.

## Ready

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-002 | Replace stale counter test | Make the default smoke test target the real app behavior | App shell/testing | OTAKU-001 | `test/widget_test.dart`, `lib/main.dart` | Test compiles against `OtakuLogApp`, asserts current behavior, and passes with the full suite | 2026-07-25 |
| OTAKU-003 | Define API failure semantics | Distinguish transport/parse failures from valid empty results | Explore | Product copy/error behavior confirmation | `api_service.dart`, `search_repository.dart`, `search_tab.dart`, tests | One result/error contract is documented and tested; loading, empty, and error states are reachable | 2026-07-25 |
| OTAKU-004 | Protect search result ordering | Prevent an older request from replacing a newer query result | Explore | OTAKU-001 | `search_tab.dart`, `search_tab_test.dart` | Regression test proves latest query/category wins | 2026-07-25 |

## Blocked

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-001 | Restore reproducible toolchain | Resolve packages and establish trustworthy analyze/test/build baselines | Tooling | Valid pub.dev access; compatible Flutter/Dart SDK | `pubspec.yaml`, `pubspec.lock`, local SDK/cache | `flutter pub get`, `flutter analyze`, and `flutter test` complete; supported SDK is documented | 2026-07-25 |
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

## Technical debt

| ID | Title | Objective | Related feature | Dependencies | Important files | Acceptance criteria | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OTAKU-009 | Decide unused persistence dependencies | Remove unused packages or document an approved migration | Data/tooling | OTAKU-001; persistence decision if migration chosen | `pubspec.yaml` | Hive/Hive Flutter/path provider are either removed through normal resolution or used by one documented persistence strategy | 2026-07-25 |
| OTAKU-010 | Align typography implementation | Bundle licensed fonts or stop claiming unavailable families | Design system | Font/licensing assets | `pubspec.yaml`, `app_theme.dart`, screens | Typography renders consistently on target platforms and docs match | 2026-07-25 |
| OTAKU-011 | Establish formatting baseline | Apply one reviewed formatting-only change after the toolchain is healthy | Tooling | OTAKU-001 | `lib/`, `test/` | `dart format --output=none --set-exit-if-changed lib test` exits 0 | 2026-07-25 |
