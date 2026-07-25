# Local Library and Home

- **Status:** Functional but incomplete
- **Last verified:** 2026-07-25

## Purpose

Maintain an on-device list of anime, manga, TV series, and movies; create
missing media manually; show flat or seasonal progress; filter the collection;
and increment trackable progress without a hard cap.

## User flow

1. App shell loads media through `LocalStorageRepository`.
2. Missing/invalid/empty storage is seeded with eight sample items.
3. Home shows tracked, active, and completed counts.
4. User filters by title or All/Anime/Manga/Series/Movie.
5. User taps `+1`, opens an item for detailed editing, or uses the manual-add
   entry point when the library is empty.

## Entry points and routes

- Bottom navigation index 0 (`Home`)
- `MainNavigationScreen` constructs `HomeTab`
- Card tap imperatively pushes `MediaDetailScreen`
- Empty-library manual add pushes `ManualMediaScreen`
- No named route/deep link exists

## Screens and widgets

- `HomeTab` — filters, stats, empty state, media list, and manual-add entry
- `MediaCard` — cover, type/status/rating badges, progress, and contextual `+1`
- `ManualMediaScreen` — validated custom-item form
- `season_editor_dialog.dart` — reusable season add/edit form
- `MainNavigationScreen` — owns the list and mutation callbacks

## State and logic

`MainNavigationScreen` owns `_items` and `_isLoading`. `HomeTab` owns
`_selectedCategory` and `_searchQuery`. Updates return a complete list from the
repository, then replace root state.

Confirmed rules:

- Add/update matches existing ID or case-insensitive title.
- New items insert at index 0.
- Flat `+1` always increments, including unknown or exceeded totals.
- Progress never changes tracking status automatically.
- Seasonal `+1` targets the highest-numbered ongoing season; if no active
  season is clear, progress is edited in details.
- Movies have no episode/chapter counter.
- Manual IDs use a persisted `manual_<time>_<sequence>` value and do not
  require a provider identifier.
- Active count includes `Watching` and `Reading`.

## Models, repositories, and persistence

- Models: `MediaItem`, `MediaSeason`, and centralized media/status/progress
  enums
- Repository: `LocalStorageRepository`
- Store: one JSON string in SharedPreferences
- Key: `otaku_log_media_items`
- Seed: `sampleMediaItems`
- Remote API: none in this feature

Legacy records decode as flat progress, unknown release status, empty seasons,
and remote/non-manual origin. Existing progress and positive totals are
preserved. New nullable/movie/manual/season values round-trip through the same
repository.

## Loading, empty, and error states

- Root spinner while local data loads.
- Home distinguishes an empty library from an empty filter result.
- Empty library includes an `Add manually` action.
- Network images have loading/error fallbacks in `MediaCard`.
- Storage errors are not shown; decode errors still reset to sample data.

## Tests

`local_storage_repository_test.dart` covers seed, manual/reload, legacy decode,
uncapped progress, seasonal persistence/targeting, update, and delete.
`media_item_test.dart`, `media_card_test.dart`, and
`manual_media_screen_test.dart` cover the new model and visible states. The
full suite has not run successfully due to the package/toolchain blocker.

## Known limitations

- Seed data may look like real user data.
- Storage corruption can overwrite data with samples.
- There is no explicit schema version, export, sync, or encrypted storage;
  this additive change relies on tolerant decoding.
- Home search is local title matching only.
- Root load/mutations have no error state.
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
- `lib/data/mock_data.dart`
- `lib/models/media_item.dart`
- `test/local_storage_repository_test.dart`
- `test/media_item_test.dart`
- `test/manual_media_screen_test.dart`
- `test/media_card_test.dart`
