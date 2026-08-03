# Media Details and Editing

- **Status:** Functional but incomplete
- **Last verified:** 2026-08-01

## Purpose

Inspect one Library item and edit tracking status, release status, flat or
seasonal progress, totals, rating, synopsis/personal description, or delete
the item.

## User flow

1. Tap a Home `MediaCard`.
2. Detail opens with cover, media type, title, and active progress summary.
3. Edit tracking status independently from media release status.
4. For flat progress, change the current count and set a known total or leave
   it unknown.
5. For seasonal anime/series, add, edit, increment, decrement, or delete
   seasons.
6. Save and return, or confirm deletion and return.

## Entry point and route

`MainNavigationScreen._openDetailScreen` pushes a `MaterialPageRoute`
containing `MediaDetailScreen`. The selected item and save/delete callbacks
are constructor arguments. No route name/deep link exists.

## Screens and widgets

- `MediaDetailScreen` — editable item state and save/delete orchestration
- `season_editor_dialog.dart` — shared validated season editor

The screen continues to use Material dropdowns, segmented controls, form
fields, switches, buttons, dialogs, and sliders within the existing design
system.

## State and business logic

Local fields copy the incoming `MediaItem`. Confirmed rules:

- Incrementing is not capped by a known total.
- Reducing/editing a total never reduces progress.
- Exceeded totals display a warning and save unchanged.
- Completion is explicit through tracking status; progress changes never
  auto-complete an item.
- Unknown totals are `null` and display as `?`.
- Seasonal aggregate progress comes from `MediaSeason` values.
- Flat-to-seasonal conversion creates Season 1 with the existing progress.
- Seasonal-to-flat conversion copies aggregate progress and retains inactive
  season data so conversion is reversible.
- Duplicate season numbers are rejected.
- Season deletion requires confirmation.
- Movies hide episodic controls and use status/rating/metadata only.

## Models, repositories, APIs, persistence

- Models: `MediaItem` and `MediaSeason`
- Direct repository/service/API use: none
- Parent save/delete callbacks call `LocalStorageRepository`, then replace the
  shell's list
- All new fields use the normal backward-compatible `MediaItem` JSON record

In flat mode, flat values are authoritative. In seasonal mode, seasons are
authoritative. Legacy aggregate keys remain serialized for compatibility but
must not be treated as a second seasonal source of truth.

## Loading, empty, and error states

- Missing/failed cover images render a media-type fallback.
- Invalid/negative numeric input renders form validation messages.
- Missing synopsis renders an empty editable description field.
- No save/delete loading state or storage error message exists.

## Tests

`media_detail_screen_test.dart` covers legacy rendering/save, confirmed
deletion, unknown totals, progress beyond total without auto-completion,
season add/edit, and movie-specific presentation. All seven focused tests and
the full 79-test suite pass on Flutter 3.44.8.

## Known limitations

- Save/delete callbacks return `void` at this boundary and are not awaited, so
  the screen closes before persistence success is known.
- There is no unsaved-changes warning.
- Seasonal card incrementing requires an ongoing season; otherwise detail is
  the progress-editing surface.

## Extension instructions

- Keep persistence in the parent repository flow.
- Preserve callback contracts or coordinate a public-interface decision.
- Keep progress/status rules in `MediaItem` or the repository rather than
  duplicating them in new widgets.
- Reuse the shared season editor.
- Check Home/card/persistence behavior for every new editable `MediaItem`
  field.

## Important files

- `lib/screens/media_detail_screen.dart`
- `lib/widgets/season_editor_dialog.dart`
- `lib/screens/main_navigation_screen.dart`
- `lib/models/media_item.dart`
- `lib/repositories/local_storage_repository.dart`
- `test/media_detail_screen_test.dart`
- `test/media_item_test.dart`
