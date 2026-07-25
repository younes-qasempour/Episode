# Known Issues

All entries are verified from code or commands and predate this documentation
bootstrap unless stated otherwise.

## Functional

| Issue | Severity | Evidence / reproduction | Affected files | Suggested next investigation |
| --- | --- | --- | --- | --- |
| Real API failures appear as empty results | Medium | Every provider method catches all exceptions and returns `[]`; non-200 responses do the same. Search's exception branch is therefore normally unreachable. | `lib/services/api_service.dart`, `lib/screens/search_tab.dart` | Define one typed result/error contract and test network, non-200, and parse failures. |
| Older searches can overwrite newer results | Medium | Debounce cancels only timers, not active futures; every completion writes `_searchResults`. | `lib/screens/search_tab.dart` | Add request-generation/cancellation logic and an out-of-order regression test. |
| Invalid local JSON silently becomes sample data | Medium | `loadMediaItems` catches every decode/read error, then saves seed items. | `lib/repositories/local_storage_repository.dart` | Separate first-run, empty-library, and corruption recovery behavior. |
| Synopsis editing path is incomplete | Low | A `TextEditingController` is created and saved, but no input uses it; the screen renders the original synopsis string. | `lib/screens/media_detail_screen.dart` | Confirm read-only vs editable ownership, then remove or complete the controller flow. |
| Profile/settings actions are placeholders | Medium | Settings icon and every settings tile use empty callbacks; identity/statistics/version are fixed strings. | `lib/screens/profile_tab.dart` | Confirm product scope before implementing or removing affordances. |
| Theme preference is session-only | Low | Root state starts at `ThemeMode.system`; switch changes only memory. | `lib/main.dart`, `lib/screens/profile_tab.dart` | Confirm persistence/system-mode requirements. |

## UI/UX and accessibility

| Issue | Severity | Evidence / reproduction | Affected files | Suggested next investigation |
| --- | --- | --- | --- | --- |
| Intended fonts are not bundled | Medium | Font family names are used, but `pubspec.yaml` declares no fonts. | `pubspec.yaml`, `lib/theme/app_theme.dart`, screens/widgets | Confirm assets/licensing or use supported platform typography. |
| Explore layout is not responsive | Low | Fixed two-column grid and aspect ratio; no breakpoints. | `lib/screens/search_tab.dart` | Test phone/tablet/web widths and define column breakpoints. |
| Custom `+1` control lacks standard button semantics | Low | It is a small `GestureDetector`/`Container`, not an `IconButton`/`Semantics` control. | `lib/widgets/media_card.dart` | Audit tap target, keyboard, and screen-reader behavior. |
| No explicit accessibility validation | Unknown | No semantic, contrast, text-scale, or focus tests exist. | Presentation/test code | Define target standard and add focused widget checks. |

## Architecture and data

| Issue | Severity | Evidence / reproduction | Affected files | Suggested next investigation |
| --- | --- | --- | --- | --- |
| Unused persistence dependencies | Low | Hive, Hive Flutter, and path provider are declared but never imported. | `pubspec.yaml` | Remove after resolution or document a single migration plan. |
| No storage schema/migrations | Medium | One unversioned JSON array is decoded with permissive defaults. | `media_item.dart`, `local_storage_repository.dart` | Define schema versioning before incompatible model fields. |
| Provider total counts use fabricated fallbacks | Medium | Anime=12, manga=50, TV series=10 when data is absent. | `lib/services/api_service.dart` | Confirm UI behavior for unknown totals; avoid presenting fallbacks as facts. |
| No API timeout/retry/rate-limit/pagination | Medium | Plain `client.get`; fixed limits; response metadata ignored. | `lib/services/api_service.dart` | Confirm provider constraints and desired user feedback. |

## Testing

| Issue | Severity | Evidence / reproduction | Affected files | Suggested next investigation |
| --- | --- | --- | --- | --- |
| Default smoke test references missing `MyApp` | High | `test/widget_test.dart` constructs `MyApp`; production class is `OtakuLogApp`. | `test/widget_test.dart`, `lib/main.dart` | Replace template assertions with a real shell behavior test. |
| Suite cannot currently run | High | `flutter test --no-pub` exits before discovery; normal package resolution fails. | Toolchain, `pubspec.*` | Resolve OTAKU-001, then run all 19 tests and record actual failures. |
| Significant behaviors are uncovered | Medium | No Home/shell/profile/model/error/race/accessibility/integration tests. | `test/` | Add tests alongside changes, prioritizing data loss and async ordering. |

## Build and tooling

| Issue | Severity | Evidence / reproduction | Affected files | Suggested next investigation |
| --- | --- | --- | --- | --- |
| Online dependency resolution is blocked | High | `flutter pub get` reports authorization failure for pub.dev. | Local pub configuration | Inspect host/token/proxy configuration without exposing credentials. |
| Offline resolution is incomplete | High | `flutter pub get --offline` cannot satisfy `flutter_lints ^3.0.0`. | Local package cache | Restore registry access or a complete approved cache. |
| SDK and lockfile constraints differ | High | Installed Flutter/Dart are 3.41.6/3.11.4; lockfile reports minima 3.44.0/3.12.0. | `pubspec.lock`, developer SDK | Establish and document the supported SDK; regenerate lock only through pub. |
| Analyzer result is not trustworthy | High | `flutter analyze --no-pub` reports 1,293 missing-package cascade issues. | Entire Dart tree | Re-run after package configuration exists. |
| Source format baseline is dirty | Low | Format check reports 17 of 19 Dart files would change. | `lib/`, `test/` | Make a reviewed format-only change after tooling is restored. |
| Android release setup is template-grade | High | Example application ID, debug signing for release, and TODO comments remain. | `android/app/build.gradle.kts` | Obtain owner identity/signing requirements. |
| Android release manifest lacks INTERNET permission | High for remote search | INTERNET is present only in debug/profile manifests, while production uses HTTP APIs/images. | `android/app/src/*/AndroidManifest.xml` | Add/verify permission in release-capable manifest and build/test release. |
| Web build not validated | Medium | Build exits because package config is missing. | `web/`, toolchain | Re-run after OTAKU-001. |

## Security

No committed secrets were found. Current local library data is stored
unencrypted in application preferences. Whether that is acceptable for future
account/profile data is **Needs confirmation**.

## Documentation

Before this bootstrap, architecture, API, current-state, testing, decision, and
handoff documentation did not exist. The root README also named unimplemented
AniList/UserProfile/SearchBar elements; it is updated by this task.
