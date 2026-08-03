# Local Library and Home

- **Status:** Complete
- **Last verified:** 2026-08-01

## Purpose

Maintain an on-device list of anime, manga, TV series, and movies; create
missing media manually; show flat or seasonal progress; search and filter the collection;
sort by recently updated, title, rating, or completion %; toggle favorites; and increment trackable progress.

## User flow

1. App shell loads media through `LocalStorageRepository`.
2. Home displays total tracked, active, and completed stats.
3. User performs fast in-library title search using the search bar with clear action.
4. User applies instant filter chips by Media Type (*All, Anime, Manga, Series, Movie*) and Status (*All Status, Watching, Completed, Favorites*).
5. User selects sorting options from dropdown (*Recently Updated, Title A-Z, Rating High → Low, Completion %*).
6. User taps heart icon on cards or detail view to toggle Favorites.
7. User taps `+1`, opens an item for detailed editing, or uses the manual-add
   entry point when the library is empty or filtering returns no matches.

## Entry points and routes

- Bottom navigation index 0 (`Home`)
- `MainNavigationScreen` constructs `HomeTab`
- Card tap imperatively pushes `MediaDetailScreen`
- Empty-library manual add pushes `ManualMediaScreen`
- No named route/deep link exists

## Screens and widgets

- `HomeTab` — fast search input, multi-axis filter chips, sort options selector, stats, empty state with reset button, media list, and manual-add entry
- `MediaCard` — cover, type/status/rating badges, favorite heart button, progress, and contextual `+1`
- `ManualMediaScreen` — validated custom-item form
- `season_editor_dialog.dart` — reusable season add/edit form
- `MainNavigationScreen` — owns the list, mutation callbacks, and favorite toggles

## State and logic

`MainNavigationScreen` owns `_items` and `_isLoading`. `HomeTab` owns
`_selectedCategory`, `_selectedStatus`, `_sortOption`, and `_searchQuery`. Updates return a complete list from the
repository, then replace root state.

Confirmed rules:

- Add/update matches existing ID or case-insensitive title.
- New items insert at index 0.
- `isFavorite` (bool) and `updatedAt` (DateTime) fields track favorite status and update timestamps.
- Sorting supports *Recently Updated*, *Title (A-Z)*, *Rating (High → Low)*, and *Completion %*.
- Flat `+1` always increments, including unknown or exceeded totals.
- Progress never changes tracking status automatically.
- Seasonal `+1` targets the highest-numbered ongoing season; if no active
  season is clear, progress is edited in details.
- Movies have no episode/chapter counter.
- Manual IDs use a persisted `manual_<time>_<sequence>` value and do not
  require a provider identifier.
- Active count includes `Watching` and `Reading`.

## Models, repositories, and persistence

- Models: `MediaItem` (with `isFavorite` and `updatedAt`), `MediaSeason`, and centralized media/status/progress
  enums
- Repository: `LocalStorageRepository` (with `toggleFavorite`)
- Store: one JSON string in SharedPreferences
- Key: `otaku_log_media_items`
- Seed: `sampleMediaItems`
- Recovery: validated whole-library snapshot/write/round-trip/rollback
- Remote API: none in this feature

Legacy records decode as flat progress, unknown release status, empty seasons,
non-manual origin, un-favorited, and null updatedAt. Existing progress and positive totals are
preserved. New nullable/movie/manual/season/favorite/timestamp values round-trip through the same
repository.

## Loading, empty, and error states

- Root spinner while local data loads.
- Home distinguishes an empty library from an empty filter/search result.
- Empty library includes an `Add manually` action.
- Empty search/filter result includes a `Reset filters & search` action.
- Network images have loading/error fallbacks in `MediaCard`.
- Corrupt storage is shown by the shell without changing the stored raw value.
- Whole-library transfer failures restore the prior JSON snapshot.

## Tests

- `local_storage_repository_test.dart` covers seed, manual/reload, legacy decode, uncapped progress, seasonal persistence/targeting, favorite toggling, update, and delete.
- `home_tab_test.dart` covers in-library title search, clear button, Media Type chips, Status/Favorites chips, sorting options, card favorite toggles, and empty reset action.
- `media_item_test.dart`, `media_card_test.dart`, `media_detail_screen_test.dart`, and `manual_media_screen_test.dart` cover models and visible states. All tests pass cleanly.

## Known limitations

- Storage corruption displays recovery guidance without modifying stored raw values.
- Home search is local title matching only.
- A seasonal card without an ongoing season requires detail-screen editing.

## Extension instructions

- Put collection rules in `LocalStorageRepository` or `MediaItem`, not
  `HomeTab`.
- Preserve stored JSON compatibility when changing `MediaItem`.
- Reuse `MediaCard`, the season editor, and root callbacks.
- Do not add Hive/another store without an approved migration decision.
- Add repository tests for rules and widget tests for visible interaction.

## Important files

- `lib/screens/main_navigation_screen.dart`
- `lib/screens/home_tab.dart`
- `lib/screens/manual_media_screen.dart`
- `lib/widgets/media_card.dart`
- `lib/widgets/season_editor_dialog.dart`
- `lib/repositories/local_storage_repository.dart`
- `lib/models/media_item.dart`
- `test/local_storage_repository_test.dart`
- `test/home_tab_test.dart`
- `test/media_item_test.dart`
- `test/manual_media_screen_test.dart`
- `test/media_card_test.dart`

