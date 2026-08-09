# Episode 🎬

Episode is a Flutter media-tracking prototype for anime, manga, and TV series.
It provides an on-device library, progress/status/rating editing, remote
discovery through Jikan and TVMaze, light/dark themes, and local native/MAL/CSV
data transfer with previewed backup and restore.

## Start here

Coding agents must read [AGENTS.md](AGENTS.md) first. Humans and agents can use
the [documentation index](docs/README.md) for the verified product state,
architecture, code map, development workflow, feature guides, decisions, and
known issues.

## Current stack

- Flutter Material 3
- Widget-local `setState` and callbacks
- `SharedPreferences` JSON persistence
- `http` with repository/service boundaries
- Provider-based native JSON, MAL XML/XML.GZ, and CSV transfer
- Android and web project directories

The app does not currently contain authentication, cloud sync, notifications,
localization, code generation, or a Hive-backed database. Profile/settings
content is largely placeholder UI. See
[CURRENT_STATE.md](docs/CURRENT_STATE.md) for evidence and validation status.

## Setup

```bash
flutter --version
flutter pub get
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

Validate:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The 2026-08-09 snapshot resolves packages online, passes static analysis and
154 tests, and produces an Android debug APK. Consult
[DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md) for exact results.

## Source layout

```text
lib/
  data/          static first-run sample data
  models/        MediaItem, transfer contracts, and serialization
  repositories/  local-library, search, and transfer boundaries
  screens/       app shell, media, and data-management screens
  services/      HTTP, import/export formats/planning, platform file adapters
  theme/         Material light/dark themes and tokens
  widgets/       reusable MediaCard
```

See [CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for task-to-file guidance.

## Collaboration

Inspect current Git state, create a focused branch/worktree when appropriate,
keep implementation/tests/documentation together, and do not commit or push
secrets. Suggested commit prefixes are `feat:`, `fix:`, `refactor:`, `test:`,
`docs:`, and `chore:`.
