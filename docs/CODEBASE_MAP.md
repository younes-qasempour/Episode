# Codebase Map

## Repository roots

| Path | Purpose | Notes |
| --- | --- | --- |
| `lib/` | Application source | Organized by technical responsibility. |
| `test/` | Unit and widget tests | Nine files, 45 declared tests; execution is currently toolchain-blocked. |
| `android/` | Android runner/build configuration | Template identity/signing TODOs remain. |
| `web/` | Web bootstrap | Only `index.html` is tracked. |
| `docs/` | Agent and developer shared memory | Keep synchronized with implementation. |
| `DESIGN.md` | Original visual specification | Intent, not a complete statement of implemented UI. |

No `ios/`, `macos/`, `windows/`, `linux/`, `integration_test/`, `assets/`,
`l10n/`, `scripts/`, or CI configuration directory is present.

## `lib/` map

| Directory/file | Purpose and contents | Do not place here | Depends on |
| --- | --- | --- | --- |
| `main.dart` | Process entry, root `MaterialApp`, theme-mode ownership | Feature business logic, API calls | `theme/`, main shell |
| `data/` | Static seed data; currently `sampleMediaItems` | Runtime repositories or remote clients | `models/` |
| `models/` | Shared data/domain shape and serialization | Widgets or provider-specific request execution | Dart core |
| `repositories/` | UI-facing boundaries for local storage and search | Widget layout, direct visual state | models, services/data |
| `services/` | Low-level HTTP requests and provider mapping | Screen state or local persistence | `http`, models |
| `screens/` | Full screens/tabs, local UI state, orchestration callbacks | New persistence engines or duplicated API clients | models, repositories, widgets, theme |
| `theme/` | Material themes, shared colors/radii, status colors | Feature state or data logic | Flutter Material |
| `widgets/` | Reusable presentation components; currently `MediaCard` | Repository access or application navigation ownership | models, theme |

## Notable files

- `lib/main.dart` — application entry and theme state
- `lib/screens/main_navigation_screen.dart` — composition root for library
  dependencies and callbacks
- `lib/models/media_item.dart` — single media model and JSON contract
- `lib/repositories/local_storage_repository.dart` — library persistence
- `lib/repositories/search_repository.dart` — remote-search boundary
- `lib/services/api_service.dart` — all confirmed endpoints and mapping
- `lib/theme/app_theme.dart` — implemented theme source of truth
- `lib/widgets/media_card.dart` — reusable library item presentation
- `lib/screens/manual_media_screen.dart` — manual anime, manga, series, and
  movie creation
- `lib/widgets/season_editor_dialog.dart` — shared season add/edit validation
  used by manual creation and media details

## Task-to-location guide

| Task type | Start here | Related files |
| --- | --- | --- |
| Change app startup or root theme mode | `lib/main.dart` | `app_theme.dart`, `profile_tab.dart` |
| Add/change a primary tab | `main_navigation_screen.dart` | target screen, navigation tests |
| Add a pushed screen | existing `_openDetailScreen` flow | screen constructor, callbacks, widget tests |
| Change library behavior | `local_storage_repository.dart` | `MediaItem`, shell callbacks, Home/detail tests |
| Change Home filtering/cards | `home_tab.dart` | `media_card.dart`, `AppTheme` |
| Add/change manual media creation | `manual_media_screen.dart` | `MediaItem`, shell add callback, `season_editor_dialog.dart` |
| Add/change an API call | `api_service.dart` | `search_repository.dart`, `MediaItem`, mapping tests |
| Change Explore behavior | `search_tab.dart` | search repository/service, search widget tests |
| Change media fields | `media_item.dart` | sample data, API mappers, persistence, all display widgets/tests |
| Change theme/tokens | `app_theme.dart` | `DESIGN.md`, screens with literal colors, design docs |
| Add local storage | existing `LocalStorageRepository` | migration/backward compatibility decision; do not create a parallel store |
| Add tests | closest file under `test/` | constructor injection seams in service/repository/screens |
| Change Android release config | `android/app/build.gradle.kts` | main manifest, signing secrets outside Git |

## Dependency direction

The dominant direction is:

`screens/widgets → repositories → services/data → models`

`theme` is presentation-only and imported by screens/widgets. `main.dart` and
`MainNavigationScreen` compose the application. Keep low-level layers free of
Flutter widget dependencies.
