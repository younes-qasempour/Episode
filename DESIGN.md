# OtakuLog Design System & Specification

Extracted from Stitch Project: **OtakuLog Media Tracker**

---

## 1. Vision & Brand Style
The visual style follows a **Modern / Soft-Minimalist** aesthetic with high-energy accents and rounded geometry.
- **Personality**: Approachable, vibrant, modern, energetic.
- **Aesthetic**: Soft depth, generous whitespace, tactile rounded cards, pill badges, and dual-font typography hierarchy.

---

## 2. Color Palette

### Light Mode Colors
- **Primary (Indigo)**: `#4648D4`
  - Primary Container: `#6063EE`
  - On-Primary: `#FFFFFF`
  - On-Primary Container: `#FFBFF`
  - Primary Fixed: `#E1E0FF`
  - Primary Fixed Dim: `#C0C1FF`
- **Secondary / Accent (Peach / Coral)**: `#A53B29` / `#FE7D66`
  - Secondary: `#A53B29`
  - Secondary Container (Peach Accent): `#FE7D66`
  - On-Secondary: `#FFFFFF`
  - Secondary Fixed: `#FFDAD4`
  - Secondary Fixed Dim: `#FFB4A6`
- **Tertiary (Soft Blue)**: `#4B5A9B`
  - Tertiary Container: `#6473B6`
- **Background & Surfaces**:
  - Background: `#F8F9FF`
  - Surface: `#F8F9FF`
  - Surface Container Lowest: `#FFFFFF`
  - Surface Container Low: `#EFF4FF`
  - Surface Container: `#E5EEFF`
  - Surface Container High: `#DCE9FF`
  - Surface Container Highest: `#D3E4FE`
  - Surface Dim: `#CBDBF5`
  - On-Surface: `#0B1C30`
  - On-Surface Variant: `#464554`
  - Outline: `#767586`
  - Outline Variant: `#C7C4D7`
- **Error**: `#BA1A1A` (Container: `#FFDAD6`, On-Error: `#FFFFFF`)

### Dark Mode Colors
- **Background & Surfaces**:
  - Dark Background: `#0B1C30` (Deep Navy)
  - Surface Container Low: `#122238`
  - Surface Container: `#1A2C46`
  - Surface Container High: `#213145`
  - Inverse Surface / Surface Bright: `#213145`
  - On-Surface: `#EAF1FF`
  - On-Surface Variant: `#C7C4D7`
- **Primary**: `#C0C1FF` (Soft Lavender Indigo)
- **Secondary (Peach Accent)**: `#FFB4A6` (Warm Soft Peach/Coral)
- **Outline**: `#767586`

---

## 3. Typography Specification

- **Headlines Font**: `Plus Jakarta Sans`
  - `display-lg`: Size 32px | Weight 800 (ExtraBold) | Line Height 40px | Letter Spacing -0.02em
  - `headline-lg`: Size 24px | Weight 700 (Bold) | Line Height 32px | Letter Spacing -0.01em
  - `headline-md`: Size 20px | Weight 700 (Bold) | Line Height 28px | Letter Spacing 0.0em
  - `headline-sm`: Size 18px | Weight 600 (SemiBold) | Line Height 24px | Letter Spacing 0.0em

- **Body & Labels Font**: `Be Vietnam Pro`
  - `body-lg`: Size 16px | Weight 400 (Regular) | Line Height 24px
  - `body-md`: Size 14px | Weight 400 (Regular) | Line Height 20px
  - `label-lg`: Size 14px | Weight 600 (SemiBold) | Line Height 20px | Letter Spacing 0.01em
  - `label-sm`: Size 12px | Weight 500 (Medium) | Line Height 16px

---

## 4. Geometry, Shapes & Corner Radii

- **Cards & Primary Containers**: **16px (1.0rem)** (`rounded-lg`)
- **Buttons & Input Fields**: **12px (0.75rem)** (`rounded-md`)
- **Small Containers**: **8px (0.5rem)** (`rounded-sm`)
- **Chips, Badges & Pills**: **9999px (Full)** (`rounded-full`)

---

## 5. Layout & Spacing Grid

Built on a **4px baseline grid**:
- **Screen Side Margin**: `20px`
- **Component Padding**: `16px`
- **Spacing Units**:
  - `xs`: 4px
  - `sm`: 8px
  - `md`: 16px
  - `lg`: 24px
  - `xl`: 32px
  - `xxl`: 48px
- **Gutter**: `12px`

---

## 6. Elevation & Depth System
- **Tonal Layering**: Cards use lighter surface colors in dark mode and clean white with subtle Indigo ambient shadows in light mode.
- **Shadows**: Soft, diffused shadows with primary indigo tint (`Color.fromRGBO(70, 72, 212, 0.08)`).
- **Interactive Feedback**: Press down scale (98%) and smooth state transitions.

---

## 7. App Navigation & Screen Structure

- **Main Navigation**: 3-Tab Bottom Navigation Bar
  - **Tab 1: Home (Dashboard)** - Search bar, Filter chips, Media progress carousel/grid, "Continue Watching/Reading" section, Quick stats.
  - **Tab 2: Search / Explore** - Search bar, Category filters, Trending items grid, Quick Add button.
  - **Tab 3: Profile & Settings** - User avatar & statistics, Theme toggle (Light / Dark mode switcher), Media collection breakdown, Settings list.
