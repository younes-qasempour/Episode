# Testing Guide

## Current structure

All tests are under `test/`; no integration-test or golden-test directory
exists.

| File | Scope | Declared tests |
| --- | --- | ---: |
| `api_service_test.dart` | Jikan/TVMaze mapping helpers | 3 |
| `local_storage_repository_test.dart` | Seed, add, progress, update, delete with mocked preferences | 5 |
| `search_repository_test.dart` | Category delegation and thrown failure through a fake service | 5 |
| `search_tab_test.dart` | Explore rendering, duplicate state, add callback | 3 |
| `media_detail_screen_test.dart` | Detail save and confirmed delete callbacks | 2 |
| `widget_test.dart` | Stale Flutter counter-template test | 1 |

Total declared: **19**.

## Test techniques

- `SharedPreferences.setMockInitialValues` resets local preference state.
- Test subclasses override `ApiService.searchMedia`.
- Constructor injection supplies repositories/services to widgets.
- Widget tests resize the test view when scrolling/tapping requires space.
- No general mocking library or fixture directory is used.

## Commands

```bash
flutter test
flutter test test/api_service_test.dart
flutter test test/local_storage_repository_test.dart
flutter test test/search_tab_test.dart
```

Coverage can be requested with `flutter test --coverage`, but no threshold or
reporting tool is configured.

## Current status

Tests were **not successfully executed** on 2026-07-25. Package resolution is
blocked, and `flutter test --no-pub` stops before test discovery because
`.dart_tool/package_config.json` does not exist.

Separately, `test/widget_test.dart` references `MyApp`, while production defines
`OtakuLogApp`. That template test will not compile after dependencies are
restored. Do not report the suite as passing until both conditions are resolved
and the full command succeeds.

## Coverage limitations

- No direct `MediaItem` serialization/progress tests
- No `HomeTab`, `MainNavigationScreen`, `ProfileTab`, `MediaCard`, or theme tests
- No HTTP request/response tests with an injected mock client
- No malformed storage/response, non-200, or timeout tests
- No search debounce/out-of-order request test
- No persistence failure UI tests
- No accessibility, golden, responsive, integration, or build smoke tests
- No Android/web platform test

## Expectations for new work

- Business/model/repository logic changes require unit tests.
- State changes require a focused widget/state test using existing constructor
  seams.
- Reusable widgets require widget tests when behavior is non-trivial.
- Bug fixes should add a regression test when feasible.
- API parsing changes require mapper or repository tests, including missing or
  malformed fields.
- Persistence-field changes require backward-compatibility tests.
- New asynchronous search behavior must cover stale results and failure states.

Keep tests deterministic: inject clients/repositories, avoid live API requests,
and do not rely on external image success.

## Naming

Existing tests use readable sentence-style names and group by class. Continue
that pattern, stating behavior and condition rather than implementation detail.
