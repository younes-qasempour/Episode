# Profile and Theme

- **Status:** Theme and data-management entry point functional; remaining Profile content placeholder
- **Last verified:** 2026-08-01

## Purpose

Provide the current appearance control and a visual location for profile,
collection summary, and settings concepts.

## User flow

1. Open Profile at bottom navigation index 2.
2. Toggle Dark Mode.
3. Open **Data, Backup & Transfer** from the settings icon or preference row.
4. Other identity/statistics/preferences remain presentation placeholders.

## Entry point and route

`MainNavigationScreen` constructs `ProfileTab` inside its `IndexedStack`.
`OtakuLogApp` supplies `ThemeMode` and a change callback.
`MainNavigationScreen` supplies the data-management callback, which pushes
`DataManagementScreen` using `MaterialPageRoute`.

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

Profile identity/statistics/version are string literals. Notifications and
user accounts have no model, repository, service, or API. Backup/import/export
is a local-file feature owned by `MediaTransferRepository`; it does not add an
account or cloud synchronization.

## Loading, empty, and error states

The profile avatar has a local icon fallback. Data-management loading, errors,
previews, results, and recovery are documented in
[data-backup-and-transfer.md](data-backup-and-transfer.md).

## Tests

The app-shell test covers Profile construction and the data-management screen
has focused action, cancellation, conflict-warning, and empty-restore widget
tests. Theme persistence/selection remains uncovered.

## Known limitations

- Hard-coded user identity, rank, member date, activity totals, and version
- Notification and About preference rows remain no-ops
- No notification, cloud, or account implementation
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
- `lib/screens/data_management_screen.dart`
- `lib/theme/app_theme.dart`
- `DESIGN.md`
- `docs/DESIGN_SYSTEM.md`
