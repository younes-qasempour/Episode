# Profile and Theme

- **Status:** Theme functional but incomplete; Profile placeholder
- **Last verified:** 2026-07-25

## Purpose

Provide the current appearance control and a visual location for profile,
collection summary, and settings concepts.

## User flow

1. Open Profile at bottom navigation index 2.
2. Toggle Dark Mode.
3. Profile identity/statistics/settings are visible but not interactive beyond
   the theme switch.

## Entry point and route

`MainNavigationScreen` constructs `ProfileTab` inside its `IndexedStack`.
`OtakuLogApp` supplies `ThemeMode` and a change callback. No settings subroute
is implemented.

## Screen and widgets

- `ProfileTab` — profile header, theme `SwitchListTile`, overview cards,
  settings tiles
- `AppTheme` — brand tokens and light/dark `ThemeData`
- Helper cards/tiles are private to `ProfileTab`

## State and logic

`OtakuLogApp` starts with `ThemeMode.system` and stores the selected mode in
widget state. Profile derives `isDark` from the resolved theme and changes the
root to explicit light/dark. It cannot select system mode again and does not
persist the choice.

## Models, repositories, APIs, persistence

None. Profile identity/statistics/version are string literals. Notifications,
backup/sync, settings, and user accounts have no model, repository, service, or
API.

## Loading, empty, and error states

None are implemented because all Profile content is static. The avatar is a
network image without a feature-specific error builder.

## Tests

No Profile or theme test exists. Test execution is currently blocked by package
resolution.

## Known limitations

- Hard-coded user identity, rank, member date, activity totals, and version
- Settings app-bar action and all preference rows are no-ops
- No notification, backup, cloud, account, or About implementation
- Theme preference is not persisted and system mode is not selectable after a
  manual choice
- Fonts named by the theme are not bundled

## Extension instructions

- Confirm product scope before creating profile/account/sync infrastructure.
- Keep theme ownership at the root unless a project-wide state decision is
  approved.
- Use `AppTheme`/`ColorScheme` and update design docs when tokens change.
- Do not represent fixed placeholder statistics as real user data.
- Add widget tests for theme persistence/selection or interactive settings.

## Important files

- `lib/main.dart`
- `lib/screens/profile_tab.dart`
- `lib/theme/app_theme.dart`
- `DESIGN.md`
- `docs/DESIGN_SYSTEM.md`
