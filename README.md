# OtakuLog 🌸

OtakuLog is a Flutter media-tracking prototype for anime, manga, and TV series.
It provides an on-device library, progress/status/rating editing, remote
discovery through Jikan and TVMaze, and light/dark themes.

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

The repository snapshot verified on 2026-07-25 has a package/toolchain blocker;
consult [DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md) before treating these
commands as a passing baseline.

## Source layout

```text
lib/
  data/          static first-run sample data
  models/        MediaItem and serialization
  repositories/  local-library and search boundaries
  screens/       app shell, tabs, and detail screen
  services/      Jikan/TVMaze HTTP integration
  theme/         Material light/dark themes and tokens
  widgets/       reusable MediaCard
```

See [CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for task-to-file guidance.

## Collaboration

Inspect current Git state, create a focused branch/worktree when appropriate,
keep implementation/tests/documentation together, and do not commit or push
secrets. Suggested commit prefixes are `feat:`, `fix:`, `refactor:`, `test:`,
`docs:`, and `chore:`.
