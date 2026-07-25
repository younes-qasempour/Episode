# Remote Discovery and Explore

- **Status:** Functional but incomplete
- **Last verified:** 2026-07-25

## Purpose

Discover anime, manga, and TV series through public remote APIs and add results
to the local Library.

## User flow

1. Explore loads default results on initialization.
2. User types a query (500 ms debounce) and/or selects a category.
3. Selected provider requests run concurrently.
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
- APIs: Jikan v4 and TVMaze
- Local persistence: none directly; add callback returns to the shell, which
  uses `LocalStorageRepository`

## Loading, empty, and error states

- Loading spinner and provider text
- Empty result icon/message
- Red exception error branch
- Image fallback by media type
- Added/disabled state derived from current library
- Missing provider totals display as `Unknown`

The real service catches failures and returns `[]`, so most remote failures
appear as empty results rather than the error branch.

## Tests

- API mapper tests for anime, manga, and TVMaze
- Search repository category/failure tests using a fake service
- Search tab rendering, duplicate, and add callback tests

No real request construction, non-200, malformed response, debounce, race, or
error-state widget test exists. Tests are currently blocked from execution.

## Known limitations

- No cancellation/ordering of active searches
- No pagination, timeout, retry, rate-limit handling, headers, or cache
- Errors collapse into empty lists
- Remote movie search is not implemented; movies can be added manually
- Fixed two-column layout is not adaptive
- Clear-button visibility does not rebuild directly on controller change; it
  generally updates when search state changes

## Extension instructions

- Keep provider traffic/mapping in `ApiService`.
- Keep UI-facing search calls behind `SearchRepository`.
- Preserve injectable dependencies.
- Define result/error semantics before adding more providers.
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
