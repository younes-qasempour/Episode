# Episode 🎬

Episode is a responsive Flutter media tracker for anime, manga, TV series, and
movies.
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
- Adaptive compact, medium, expanded, and large layouts
- Android, web, and Windows project targets

Accounts and snapshot sync are optional and require an
`EPISODE_API_BASE_URL`; the local library remains usable without them. The app
does not currently contain notifications, localization, code generation, or a
Hive-backed database. Some Profile/settings rows remain placeholders. See
[CURRENT_STATE.md](docs/CURRENT_STATE.md) for evidence and validation status.

## Setup

```bash
flutter --version
flutter pub get
flutter run
```

## Episode branding

The approved high-resolution logo masters live in `tool/brand_sources/`.
Regenerate every checked-in runtime logo/icon from those masters with Pillow:

```bash
python tool/generate_brand_assets.py
```

The deterministic generator updates the in-app mark under `assets/branding/`,
Android legacy/round/adaptive launcher icons and splash artwork, web favicon,
PWA/maskable icons and loading mark, and the Windows runner icon. Do not resize
a generated small icon to create another target; update the masters and rerun
the generator.

Run on web:

```bash
flutter run -d chrome
```

Run on Windows from a Developer PowerShell with the Desktop development with
C++ workload installed:

```bash
flutter run -d windows
```

Build platform artifacts:

```bash
flutter build web
flutter build windows
flutter build apk --debug
```

Validate:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The 2026-08-12 responsive snapshot passes static analysis and the full test
suite, and produces Android, web, and Windows artifacts. Consult
[DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md) for exact results.

## Source layout

```text
lib/
  layout/        centralized breakpoints, grids, page widths, scroll behavior
  data/          static first-run sample data
  models/        MediaItem, transfer contracts, and serialization
  repositories/  local-library, search, and transfer boundaries
  screens/       app shell, media, and data-management screens
  services/      HTTP, sync, import/export formats, platform file adapters
  theme/         Material light/dark themes and tokens
  widgets/       reusable MediaCard, EpisodeBrand, and presentation components
assets/
  branding/      generated in-app Episode mark
tool/
  brand_sources/ approved high-resolution logo masters
  generate_brand_assets.py  reproducible platform-asset generator
```

See [CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for task-to-file guidance.

## Collaboration

Inspect current Git state, create a focused branch/worktree when appropriate,
keep implementation/tests/documentation together, and do not commit or push
secrets. Suggested commit prefixes are `feat:`, `fix:`, `refactor:`, `test:`,
`docs:`, and `chore:`.
