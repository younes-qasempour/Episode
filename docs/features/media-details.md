# Media Details and Editing

- **Status:** Functional but incomplete
- **Last verified:** 2026-07-25

## Purpose

Inspect one Library item and change its tracking status, completed count,
rating, and persisted data, or remove it.

## User flow

1. Tap a Home `MediaCard`.
2. Detail opens with a cover, type, title, and progress summary.
3. Select status; adjust progress and 0–10 rating.
4. Save and return, or confirm deletion and return.

## Entry point and route

`MainNavigationScreen._openDetailScreen` pushes a `MaterialPageRoute` containing
`MediaDetailScreen`. The selected item and save/delete callbacks are constructor
arguments. No route name/deep link exists.

## Screen and widgets

The feature is one stateful screen using Material dropdown, sliders, icon
buttons, dialog, and save button. It has no extracted reusable widget.

## State and business logic

Local fields copy the incoming `MediaItem`. Increasing/dragging progress to a
positive total changes status to `Completed`; moving below total does not
automatically restore a prior status. Save builds `item.copyWith(...)` and
invokes the parent callback. Delete requires confirmation and invokes the
parent by ID.

## Models, repositories, APIs, persistence

- Model: `MediaItem`
- Direct repository/service/API use: none
- Parent save/delete callbacks call `LocalStorageRepository`, then replace the
  shell's list
- Stored data: status, progress, total, rating, and synopsis are part of the
  normal `MediaItem` JSON record

## Loading, empty, and error states

- Cover image has a media-type fallback.
- No save/delete loading state or error message.
- Missing synopsis hides the section.
- There is no empty concept because a selected item is required.

## Tests

`media_detail_screen_test.dart` covers rendering/save callback and confirmed
delete callback. It does not test controls, completion status, cancellation,
failure, or synopsis behavior. Execution is currently blocked by dependencies.

## Known limitations

- Synopsis controller is never attached to an input.
- Save/delete callbacks return `void` at this boundary and are not awaited, so
  the screen closes before persistence success is known.
- Status values are raw strings.
- Total count cannot be edited despite being held as mutable screen state.
- No unsaved-changes warning.

## Extension instructions

- Keep persistence in the parent repository flow.
- Preserve callback contracts or coordinate a public-interface decision.
- Confirm synopsis ownership before changing its UI.
- Add widget tests for any control/business-rule changes.
- Check Home/card/persistence behavior for every new editable `MediaItem` field.

## Important files

- `lib/screens/media_detail_screen.dart`
- `lib/screens/main_navigation_screen.dart`
- `lib/models/media_item.dart`
- `lib/repositories/local_storage_repository.dart`
- `test/media_detail_screen_test.dart`
