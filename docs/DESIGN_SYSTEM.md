# Implemented Design System

`DESIGN.md` records the intended soft-minimalist design direction.
This document records what is verifiably implemented. Where they disagree,
`lib/theme/app_theme.dart` and rendered widgets describe current behavior.

## Theme structure

`AppTheme` exposes `lightTheme`, `darkTheme`, shared brand colors, surface
colors, radii, padding, and status-color mapping. Both themes use Material 3.
`EpisodeApp` selects a `ThemeMode`; the Profile switch changes it for the
current app process.

### Implemented tokens

| Token | Light | Dark |
| --- | --- | --- |
| Primary | `#4648D4` | `#C0C1FF` |
| Primary container | `#6063EE` | `#4648D4` |
| Secondary/accent | `#FE7D66` | `#FFB4A6` |
| Background | `#F8F9FF` | `#0B1C30` |
| Surface | `#FFFFFF` | `#16253B` |
| Surface container | `#E5EEFF` | `#1A2C46` |
| On-surface | `#0B1C30` | `#EAF1FF` |
| On-surface variant | `#464554` | `#C7C4D7` |
| Outline | `#767586` | `#566075` |

Status colors are peach for Watching/Reading, green for Completed, indigo for
Plan to Watch, and amber for On Hold.

### Geometry and spacing

- Card radius: 16
- Button/input radius: 12
- Pill/chip radius: 999
- Standard screen side padding: usually 20
- Common component spacing: 4, 6, 8, 12, 14, 16, 20, and 24

Spacing is not represented by a complete token scale. Screens still contain
literal values.

## Brand identity and logo assets

`EpisodeBrand` is the canonical accessible in-app mark/optional wordmark. It
loads `assets/branding/episode_mark.png`, supplies the semantic label
`Episode`, and falls back to a Material play icon if the asset cannot load.
Home, the adaptive navigation rail, app loading, login, and registration reuse
this widget instead of independently embedding logo files.

Approved masters live in `tool/brand_sources/`. Running
`python tool/generate_brand_assets.py` reproducibly generates:

- the declared Flutter asset under `assets/branding/`;
- Android legacy and round launcher icons, adaptive foreground rasters, and
  splash artwork on the brand navy background; checked-in XML resources wire
  those generated files into adaptive icons and pre-/post-Android-12 themes;
- the web favicon, Apple touch icon, regular/maskable PWA icons, manifest-linked
  assets, and the pre-first-frame loading mark;
- `windows/runner/resources/app_icon.ico`, consumed by runner metadata.

Generated targets should not be edited independently. Change the approved
master artwork or generator parameters, rerun the script, and validate the
platform surfaces together.

## Typography

Widgets reference `Plus Jakarta Sans` for headings and `Be Vietnam Pro` for
body/labels, matching `DESIGN.md` intent. No font assets or font package are
declared in `pubspec.yaml`; platforms therefore fall back when those fonts are
not installed. Implemented font sizes range roughly from 10 to 26.

## Reusable components and patterns

- `EpisodeBrand` - canonical logo mark/wordmark for app chrome, loading, and
  authentication surfaces
- `MediaCard` — library item cover, type/status/rating badges, title, progress,
  progress bar, and animated `+1` action
- `AppTheme` — themes and shared presentation tokens
- Material `ChoiceChip`/`FilterChip` — category filters
- Material `ElevatedButton` — primary/add/save actions
- Material `Card`-like decorated `Container` — profile and detail groupings
- `Image.network` error builders — media-type icon fallback

Check these before creating an equivalent component. Private helpers such as
Profile overview cards and setting tiles are feature-local, not repository-wide
components.

## Forms and actions

- Search uses a themed filled `TextField` with leading search icon.
- Status uses a decorated `DropdownButton`.
- Progress and rating use Material sliders.
- Destructive deletion requires an `AlertDialog` confirmation.
- Add/save actions use `ElevatedButton`.

There is no validation component, form object, disabled/loading button pattern,
or editable synopsis field.

## State presentation

| State | Current pattern |
| --- | --- |
| Initial library load | Full-screen centered `CircularProgressIndicator` |
| Remote search load | Centered indicator plus provider text |
| Image load | Small circular progress indicator in `MediaCard`; search/detail lack an explicit loader |
| Empty library/filter | Icon, title, and guidance copy |
| Empty remote results | Search icon and query-specific message |
| Remote error | Red error icon and message branch exists |
| Image error | Media-type icon on tinted surface |
| Mutation success | Floating `SnackBar` |
| Persistence mutation error | Not implemented |

Provider failures are mapped to typed errors when every selected provider
fails; partial failures remain hidden when another provider returns results.

## Cards, shadows, and motion

Light cards use subtle indigo-tinted shadows and light outlines; dark cards
usually remove shadows and use a dark outline. `MediaCard` has ripple feedback.
The `+1` control scales to 0.85 on press for 100 ms. No global motion tokens or
reduced-motion behavior exist.

## Responsive behavior

`lib/layout/responsive_layout.dart` is the presentation-wide source of truth.
It defines intent-based classes: compact below 600 px, medium from 600 px,
expanded from 1024 px, and large from 1440 px. It also owns horizontal padding,
content maximums, grid density, and desktop pointer scrolling.

- Compact uses bottom navigation and stacked mobile compositions.
- Medium uses a compact navigation rail and selectively denser grids.
- Expanded/large use an extended rail, two-pane media details, wider library
  and Explore grids, and multi-column analytics.
- Forms cap at 640 px; focused transfer content at 900 px; details at 1200 px;
  standard content at 1320 px; dashboards at 1480 px.
- Global dialogs cap at 560 px and retain scrolling behavior from their
  Material content.

## Dark mode

Supported. The switch chooses explicit light/dark mode; it does not restore
system mode and the selection is not persisted.

## Accessibility

Material controls provide baseline semantics, and delete has a tooltip.
No accessibility audit, contrast test, text-scale test, focus-order test, or
screen-reader-specific labels are present. Several dense badges use 10–11 px
text, and the custom `+1` control is a `GestureDetector` rather than a standard
button, so tap-target and semantics verification is recommended.

## Known inconsistencies

- `DESIGN.md` lists a larger palette and typography scale than `AppTheme`
  implements.
- `DESIGN.md` contains `#FFBFF`, which is not a valid six-digit color value.
- Font-family intent is not backed by bundled assets.
- Repeated surface/border colors and dimensions remain literal in screens.
- Accessibility and very large text scaling still need a dedicated audit.
