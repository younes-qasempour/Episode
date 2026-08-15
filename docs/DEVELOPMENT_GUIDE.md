# Development Guide

## Prerequisites

- Flutter SDK
- Dart SDK included with Flutter
- Android Studio/SDK for Android work
- Chrome for web work
- Java 17 for the Android build
- Windows 10/11 and Visual Studio 2022 Build Tools with the **Desktop
  development with C++** workload for Windows work
- Python 3 plus Pillow when regenerating checked-in Episode brand assets

`pubspec.yaml` allows Dart `>=3.0.0 <4.0.0`, while the current lockfile reports
Dart `>=3.12.0` and Flutter `>=3.44.0`. The 2026-08-12 validation machine uses
Flutter 3.44.8 / Dart 3.12.2. Online and offline cached package resolution
succeed; Android Gradle plugin artifact resolution and debug APK builds are
verified on this machine.
Treat Flutter 3.44 / Dart 3.12 as the verified development baseline, not a
confirmed long-term product support policy.

## Setup and run

```bash
flutter --version
flutter pub get
flutter run
flutter run -d chrome
flutter run -d windows
```

There are no environment flavors or `.env` loaders. Jikan, Kitsu, and TVMaze
discovery endpoints are public. Optional account and sync features use:

```bash
flutter run -d windows --dart-define=EPISODE_API_BASE_URL=http://localhost:8000
```

Without that define, local tracking and file transfer remain available and
account/sync actions explain that the backend is not configured.

## Regenerate Episode brand assets

The approved masters are `tool/brand_sources/episode_mark_master.png` and
`tool/brand_sources/episode_icon_master.png`. From the repository root run:

```bash
python tool/generate_brand_assets.py
```

The script derives the declared Flutter mark, Android legacy/round/adaptive
launcher and splash assets, web favicon/PWA/loading assets, and Windows `.ico`
directly from the high-resolution masters. Review all generated destinations
as one change; do not hand-edit or upscale an individual output.

## Validation commands

```bash
# Apply repository Dart formatting.
dart format .

# Verify formatting without writing.
dart format --output=none --set-exit-if-changed lib test

flutter analyze
flutter test

# Common build checks when relevant.
flutter build apk --debug
flutter build web
flutter build windows
```

Run targeted tests first during development, for example:

```bash
flutter test test/local_storage_repository_test.dart
flutter test test/search_tab_test.dart
flutter test test/media_transfer_repository_test.dart
```

The Windows runner includes a small ATL compatibility header because
`flutter_secure_storage_windows` 3.x otherwise requires the optional ATL
Visual Studio component only for string conversion. Tokens still use Windows
Credential Manager through the upstream plugin.

No Dart code-generation, coverage gate, Markdown-lint, or CI command is
configured. `tool/generate_brand_assets.py` is the one project-owned asset
generation command.

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
- The service and repository return typed `SearchResult` values. Preserve the
  coordinated failure contract across service, repository, screen, and tests.
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
- Use `ResponsiveBuilder`, `ResponsiveLayoutInfo`, and
  `PageContentConstraint`; do not add feature-local breakpoint numbers.
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
| Formatting | Standard Dart style is enforced for active source and tests | The verified `lib`/`test` formatting check is clean | Keep focused formatting checks in every change. |
| Colors/spacing | Theme tokens plus `ColorScheme` | Screens contain many repeated literal colors and dimensions | Extend `AppTheme` deliberately as shared patterns stabilize. |
| Typography | Named font families in widgets/theme | Fonts are not declared as assets | Confirm licensing/assets, then bundle fonts or remove unfulfilled family claims. |
| Errors | Service/repository/UI share typed `SearchResult` failures | Partial provider failures remain hidden when another provider succeeds | Preserve the typed contract and define partial-failure UX before exposing it. |
| Persistence packages | SharedPreferences is active | Hive/path provider are declared but unused | Confirm removal or plan a documented migration; do not use both casually. |
