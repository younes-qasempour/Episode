# Profile and Theme

- **Status:** Functional analytics, customization, theme, auth/sync, and data-management hub
- **Last verified:** 2026-08-09

## Purpose

Provide personal library analytics, profile customization, activity streaks,
appearance control, account/sync access, and local data management.

## User flow

1. Open Profile at bottom navigation index 2.
2. Toggle Dark Mode.
3. Review milestones, viewing/reading time, mean score, distributions,
   favorites, quick progress, and activity streaks.
4. Edit the local profile or open account, sync, and data tools.

## Entry point and route

`MainNavigationScreen` constructs `ProfileTab` inside its `IndexedStack`.
`EpisodeApp` supplies `ThemeMode` and a change callback. The shell supplies
account, sync, progress, and data-management callbacks; pushed screens use
`MaterialPageRoute`.

## Screen and widgets

- `ProfileTab` — analytics dashboard, theme control, account/sync actions, and
  data/settings entry points
- `ProfileStatsDashboard` — milestones, donut chart, favorites, quick progress,
  activity heatmap, share card, and profile customization
- `DonutChart` and `StreakHeatmap` — reusable analytics visualizations
- `AppTheme` — brand tokens and light/dark `ThemeData`

## State and logic

`EpisodeApp` starts with `ThemeMode.system` and stores the selected mode in
widget state. Profile derives `isDark` from the resolved theme and changes the
root to explicit light/dark. It cannot select system mode again and does not
persist the choice.

`LibraryStats` derives analytics from `MediaItem` values. `UserProfileData` and
activity logs persist through `LocalStorageRepository`. Authentication and
cloud snapshot sync use their existing controller/service seams, while local
backup/import/export remains owned by `MediaTransferRepository`.

## Loading, empty, and error states

The profile avatar has a local icon fallback, analytics support an empty
library, and account/sync actions surface their current controller state.
Data-transfer states are documented in
[data-backup-and-transfer.md](data-backup-and-transfer.md).

## Tests

Focused tests cover derived statistics, dashboard rendering/chart mode,
activity streaks, app-shell construction, and data-management actions. Theme
persistence/selection remains uncovered.

## Known limitations

- Rank, member date, and version remain fixed presentation values
- Notification and About preference rows remain no-ops
- Theme preference is not persisted and system mode is not selectable after a
  manual choice
- Fonts named by the theme are not bundled

## Extension instructions

- Extend the existing auth/sync seams rather than creating parallel account
  infrastructure.
- Keep theme ownership at the root unless a project-wide state decision is
  approved.
- Derive new statistics through `LibraryStats` rather than fixed UI values.
- Use `AppTheme`/`ColorScheme` and add tests for interactive settings.

## Important files

- `lib/main.dart`
- `lib/screens/profile_tab.dart`
- `lib/widgets/profile_stats_dashboard.dart`
- `lib/widgets/donut_chart.dart`
- `lib/widgets/streak_heatmap.dart`
- `lib/models/library_stats.dart`
- `lib/models/user_profile_data.dart`
- `lib/screens/data_management_screen.dart`
- `lib/theme/app_theme.dart`
