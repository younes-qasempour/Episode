# Remote Discovery and Explore

- **Status:** Functional but incomplete
- **Last verified:** 2026-08-09

## Purpose

Discover anime, manga, and TV series through public remote APIs and add results
to the local Library.

## User flow

1. Explore loads default results on initialization.
2. User types a query (500 ms debounce) and/or selects a category.
3. Selected provider requests run with Jikan pacing while TVMaze runs
   concurrently.
4. Results display in a two-column grid.
5. User adds a result; an existing ID/title shows `In Library`.
6. A persistent `Can't find it? Add manually` action opens the shared manual
   creation flow.

## Entry point and route

- Bottom navigation index 1, user-facing label `Explore`
- `MainNavigationScreen` constructs `SearchTab`
- It is retained in the shell's `IndexedStack`
- No named route or deep link exists

## Screen and widgets

`SearchTab` contains the app bar, query field, category chips, manual-add
entry, state messages, grid, result cards, and add button. Result-card UI is a
private helper, not a shared widget.

## State management

Widget-local state holds the repository, controller, category, results,
loading/error values, and debounce timer. The timer/controller are disposed.
Repository injection supports deterministic widget tests.

## Business/data flow

`SearchTab → SearchRepository → ApiService → Jikan/TVMaze → MediaItem`

Categories are `All`, `Anime`, `Manga`, and `Series`. Empty queries request
Jikan top lists and TVMaze `drama`. Detailed endpoint/mapping behavior is in
[DATA_AND_API.md](../DATA_AND_API.md).

## Models, repositories, APIs, persistence

- Model: `MediaItem`
- Repository: `SearchRepository`
- Service: `ApiService`
- APIs: Jikan v4 with Kitsu fallback, and TVMaze
- Local persistence: none directly; add callback returns to the shell, which
  uses `LocalStorageRepository`

## Loading, empty, and error states

- Shimmer loading grid and provider text
- Empty result icon/message
- Typed, user-facing failure state with retry action
- Image fallback by media type
- Added/disabled state derived from current library
- Missing provider totals display as `Unknown`

The service returns `SearchSuccess<List<MediaItem>>` or a typed
`SearchFailure`. When at least one selected provider succeeds with results,
those results are shown; when every selected provider fails, the UI explains
the primary failure and offers retry.

## Tests

- API mapper, cover sanitization, timeout, network, rate-limit, fallback, and
  response-contract tests
- Search repository category/failure tests using a fake service
- Search tab rendering, duplicate, add callback, retry, and stale-response tests

The focused API/repository/widget suite passes 30/30 and the full Flutter suite
passes 154/154.

## Known limitations

- Stale responses are discarded, but active HTTP requests are not cancelled
- No pagination or response cache
- Partial provider failures are not surfaced when another provider returns data
- Remote movie search is not implemented; movies can be added manually
- Fixed two-column layout is not adaptive
- Clear-button visibility does not rebuild directly on controller change; it
  generally updates when search state changes

## Extension instructions

- Keep provider traffic/mapping in `ApiService`.
- Keep UI-facing search calls behind `SearchRepository`.
- Preserve injectable dependencies.
- Preserve the typed `SearchResult` contract when adding providers.
- Test asynchronous ordering and provider-specific parsing.
- Coordinate `MediaItem` changes with local persistence and detail/Home UI.

## Important files

- `lib/screens/search_tab.dart`
- `lib/repositories/search_repository.dart`
- `lib/services/api_service.dart`
- `lib/models/media_item.dart`
- `lib/screens/main_navigation_screen.dart`
- `test/api_service_test.dart`
- `test/search_repository_test.dart`
- `test/search_tab_test.dart`
