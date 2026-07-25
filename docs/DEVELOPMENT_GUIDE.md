# Development Guide

## Prerequisites

- Flutter SDK
- Dart SDK included with Flutter
- Android Studio/SDK for Android work
- Chrome for web work
- Java 17 for the Android build

`pubspec.yaml` allows Dart `>=3.0.0 <4.0.0`, but the current lockfile reports
Dart `>=3.12.0` and Flutter `>=3.44.0`. The machine used for the 2026-07-25
bootstrap has Flutter 3.41.6 / Dart 3.11.4 and cannot currently resolve
packages. Until the environment is repaired, treat Flutter 3.44 / Dart 3.12 as
the lockfile-derived reproducibility target, not a confirmed product support
policy.

## Setup and run

```bash
flutter --version
flutter pub get
flutter run
flutter run -d chrome
```

There are no environment flavors, `.env` loaders, build-time variables, or
API credentials. Jikan and TVMaze base URLs are public constants in
`lib/services/api_service.dart`.

## Validation commands

```bash
# Apply Dart formatting.
dart format lib test

# Verify formatting without writing.
dart format --output=none --set-exit-if-changed lib test

flutter analyze
flutter test

# Common build checks when relevant.
flutter build apk --debug
flutter build web --debug
```

Run targeted tests first during development, for example:

```bash
flutter test test/local_storage_repository_test.dart
flutter test test/search_tab_test.dart
```

No code-generation, coverage, Markdown-lint, CI, or project script command is
configured.

## Current conventions

### Naming and files

- Dart files use `lower_snake_case.dart`.
- Public types use `UpperCamelCase`.
- Variables, methods, and callbacks use `lowerCamelCase`.
- Implementation-only widget/state members use a leading underscore.
- Screens end in `Screen` or `Tab`; repositories end in `Repository`; the
  remote client ends in `Service`.

### Imports

The dominant pattern is package imports for external dependencies and relative
imports for internal files:

```dart
import 'package:flutter/material.dart';
import '../models/media_item.dart';
```

Keep `dart:` imports first, then `package:`, then relative project imports.
The repository is not consistently auto-formatted; use `dart format` for
touched Dart files rather than performing unrelated mass formatting.

### Widgets and state

- Stateful behavior uses `StatefulWidget` + `setState`.
- Parent-owned data is changed through callbacks.
- Keep full-screen layout in `screens/`; move a component to `widgets/` when it
  is genuinely reused or independently testable.
- Check `MediaCard` and theme components before adding a new reusable widget.
- After `await`, check `mounted` before `setState` or context-dependent UI.
- Dispose controllers and timers in `dispose`.

### Dependency injection

Use optional constructor injection with a production default. This is how
repositories, HTTP clients, and screens are currently made testable. Do not add
a service locator or DI package for a single dependency.

### Models and persistence

- `MediaItem` is immutable and uses a `const` constructor and `copyWith`.
- Serialization is handwritten through `toMap`, `fromMap`, `toJson`, and
  `fromJson`.
- Stored fields must remain backward-compatible with existing JSON. Add
  tolerant defaults or a documented migration.
- Strings currently represent media types and statuses. Preserve accepted
  spellings in [GLOSSARY.md](GLOSSARY.md) until a coordinated model change is
  approved.

### API and errors

- All remote traffic belongs in `ApiService`; screens call repositories.
- Map provider responses at the service boundary.
- The current service returns an empty list on all failures. This is a known
  limitation, not a recommended new standard. A change to typed failures must
  update repository/screen behavior and tests together.
- There is no logging framework. Do not add `print`/`debugPrint` as permanent
  diagnostics without a logging decision.
- Add timeouts, retry, headers, or pagination only with explicit behavior and
  tests; do not hide them in UI code.

### Null safety and async work

- The project uses sound null safety.
- Prefer explicit nullable fields only when absence is meaningful.
- Keep network and storage APIs asynchronous.
- Avoid fire-and-forget mutations when the UI must report success/failure.

### Theme and user-visible text

- Use `Theme.of(context).colorScheme` and `AppTheme` tokens before literal
  colors.
- Reuse `AppTheme.cardRadius`, `buttonRadius`, `chipRadius`, and
  `paddingMargin` where the matching concept exists.
- Localization is not implemented. Do not introduce a second string system in
  one widget; a localization task should establish the project-wide approach.

### Accessibility and performance

- Add tooltips/semantic labels for non-obvious icon-only controls.
- Preserve Material tap targets and verify text scaling for new layouts.
- Do not assume the current fixed two-column search grid is responsive.
- Keep expensive filtering/mapping outside deeply repeated builders.
- Cancel timers/controllers and guard stale asynchronous results when adding
  search-like behavior.

### Dependencies and generated files

- Search for an existing dependency before adding one.
- Explain why an SDK/existing package cannot satisfy the need.
- Update `pubspec.yaml` through a focused change and let Flutter regenerate
  `pubspec.lock`; never edit the lockfile manually.
- `hive`, `hive_flutter`, and `path_provider` are currently unused. Their
  presence is not authorization to create a second persistence system.
- Do not edit `.metadata`, plugin registrants, or other generated output
  manually.

## Inconsistencies

| Area | Dominant pattern | Inconsistency | Recommended future standard |
| --- | --- | --- | --- |
| Formatting | Standard Dart style is intended | 17 of 19 Dart files would be reformatted | Format only touched files now; agree on a repository-wide format-only change separately. |
| Colors/spacing | Theme tokens plus `ColorScheme` | Screens contain many repeated literal colors and dimensions | Extend `AppTheme` deliberately as shared patterns stabilize. |
| Typography | Named font families in widgets/theme | Fonts are not declared as assets | Confirm licensing/assets, then bundle fonts or remove unfulfilled family claims. |
| Errors | UI has loading/empty/error branches | Real API client collapses errors into empty results | Introduce a single explicit result/error contract. |
| Persistence packages | SharedPreferences is active | Hive/path provider are declared but unused | Confirm removal or plan a documented migration; do not use both casually. |
