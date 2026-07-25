# Manual Media and Flexible Progress

- **Status:** Functional
- **Last verified:** 2026-07-25

## Scope

This feature adds custom anime, manga, series, and movies to the same local
Library used by provider results. It also defines nullable totals, explicit
tracking/release status, flat versus seasonal progress, and uncapped progress
rules.

## Manual creation

Explore always exposes `Can't find it? Add manually`; Home exposes
`Add manually` when the Library is empty. Both push `ManualMediaScreen` and
return the completed item through `MainNavigationScreen._addToLibrary`.

Required input:

- title;
- media type.

Optional/configurable input:

- cover URL with preview;
- synopsis or personal description;
- tracking and release status;
- flat or seasonal progress when supported;
- nullable total;
- rating;
- seasons with unique positive numbers, optional names, nullable totals, and
  release status.

Manual IDs use `MediaItem.createManualId`, producing a local
`manual_<time>_<sequence>` identifier. The value is persisted and does not
depend on any provider.

## Authoritative progress

- Flat mode: `flatCurrentProgress` and `flatTotalCount` are authoritative.
- Seasonal mode: `MediaSeason` entries are authoritative; aggregate
  current/total getters are derived.
- Movie: progress is not applicable.

Known total is an `int`; unknown total is `null`. Zero is never used by
provider mapping to mean unknown. Progress may exceed a known total, and
neither the model, repository, cards, nor details clamp it.

Tracking status represents the user's relationship to the item. Release
status represents the work or season. No progress operation automatically
changes tracking status.

## Conversion

Changing flat to seasonal progress creates Season 1 from the current flat
values unless retained season data already exists. Changing seasonal to flat
copies aggregate values and retains the inactive season list. This avoids
silent progress deletion and makes the conversion reversible.

## Persistence compatibility

Old JSON without new fields decodes as:

- flat progress;
- unknown release status;
- empty seasons;
- non-manual origin.

Existing positive totals and progress are preserved. New JSON continues to
write legacy aggregate keys for older readers and adds flat snapshots,
release/progress mode, season data, and manual origin.

## Remaining limitations

- There is no explicit schema version or migration runner.
- Card `+1` for seasonal media requires a clearly ongoing season.
- Remote movie search is not implemented.
- Save/storage errors are not surfaced in the form or detail screen.

## Tests

- `test/media_item_test.dart`
- `test/local_storage_repository_test.dart`
- `test/api_service_test.dart`
- `test/manual_media_screen_test.dart`
- `test/media_detail_screen_test.dart`
- `test/media_card_test.dart`
