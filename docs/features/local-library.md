# Local Library and Home

- **Status:** Functional but incomplete
- **Last verified:** 2026-07-25

## Purpose

Maintain an on-device list of anime, manga, and TV series, show progress and
summary counts, filter it, and increment progress.

## User flow

1. App shell loads media through `LocalStorageRepository`.
2. Missing/invalid/empty storage is seeded with eight sample items.
3. Home shows tracked, active, and completed counts.
4. User filters by title or All/Anime/Manga/Series.
5. User taps `+1` or opens an item for detailed editing.

## Entry points and routes

- Bottom navigation index 0 (`Home`)
- `MainNavigationScreen` constructs `HomeTab`
- Card tap imperatively pushes `MediaDetailScreen`
- No named route/deep link exists

## Screens and widgets

- `HomeTab` — filters, stats, empty state, media list
- `MediaCard` — cover, type/status/rating badges, progress, `+1`
- `MainNavigationScreen` — owns the list and mutation callbacks

## State and logic

`MainNavigationScreen` owns `_items` and `_isLoading`. `HomeTab` owns
`_selectedCategory` and `_searchQuery`. Updates return a complete list from the
repository, then replace root state.

Confirmed rules:

- Add/update matches existing ID or case-insensitive title.
- New items insert at index 0.
- `+1` stops at total count.
- Reaching a positive total marks the item `Completed`.
- Active count includes `Watching` and `Reading`.

## Models, repositories, and persistence

- Model: `MediaItem`
- Repository: `LocalStorageRepository`
- Store: one JSON string in SharedPreferences
- Key: `otaku_log_media_items`
- Seed: `sampleMediaItems`
- Remote API: none in this feature

## Loading, empty, and error states

- Root spinner while local data loads.
- Home distinguishes an empty library from an empty filter result.
- Network images have loading/error fallbacks in `MediaCard`.
- Storage errors are not shown; decode errors silently reset to sample data.

## Tests

`local_storage_repository_test.dart` covers seed, add, progress completion,
update, and delete. No Home/shell/card widget test exists. The full suite has
not been run successfully due to the package/toolchain blocker.

## Known limitations

- Seed data may look like real user data.
- Storage corruption can overwrite data with samples.
- No schema version, migration, export, sync, or encrypted storage.
- Home search is local title matching only.
- Root load/mutations have no error state.

## Extension instructions

- Put collection rules in `LocalStorageRepository`, not `HomeTab`.
- Preserve stored JSON compatibility when changing `MediaItem`.
- Reuse `MediaCard` and root callbacks.
- Do not add Hive/another store without an approved migration decision.
- Add repository tests for rules and widget tests for visible interaction.

## Important files

- `lib/screens/main_navigation_screen.dart`
- `lib/screens/home_tab.dart`
- `lib/widgets/media_card.dart`
- `lib/repositories/local_storage_repository.dart`
- `lib/data/mock_data.dart`
- `lib/models/media_item.dart`
- `test/local_storage_repository_test.dart`
