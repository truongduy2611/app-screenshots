# 🎨 App Screenshots — Design System Reference

## Color System

### Creative Indigo — Primary Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| **Primary** | `#4F46E5` (Indigo 600) | `#818CF8` (Indigo 400) | Buttons, active states, FABs |
| **On Primary** | `#FFFFFF` | `#1E1B4B` (Indigo 950) | Text/icons on primary surfaces |
| **Primary Container** | `#E0E7FF` (Indigo 100) | `#312E81` (Indigo 900) | Chips, selected cards |
| **Secondary** | `#0891B2` (Cyan 600) | `#22D3EE` (Cyan 400) | Accent actions, progress |
| **Secondary Container** | `#CFFAFE` (Cyan 100) | `#164E63` (Cyan 900) | Tags, badges |
| **Tertiary** | `#C026D3` (Fuchsia 600) | `#E879F9` (Fuchsia 400) | Highlights, accent features |
| **Surface** | `#FAFAFA` | `#0F0F23` | Main background |
| **Surface Container** | `#F4F4F5` | `#1A1A2E` | Cards, panels |
| **Surface Container High** | `#E4E4E7` | `#252547` | Elevated panels, sidebars |
| **On Surface** | `#18181B` (Zinc 900) | `#F4F4F5` (Zinc 100) | Primary text |
| **On Surface Variant** | `#52525B` (Zinc 600) | `#A1A1AA` (Zinc 400) | Secondary text |
| **Outline** | `#D4D4D8` (Zinc 300) | `#3F3F46` (Zinc 700) | Borders, dividers |
| **Error** | `#DC2626` | `#F87171` | Destructive actions |

### Seed Color
```dart
const seedColor = Color(0xFF6366F1); // Indigo 500
```

### Dark Mode Default
The app defaults to **dark mode** — standard for design tools. The dark surface uses deep navy-charcoal (`#0F0F23`) with subtle blue undertones, so the editor canvas "pops" against the background.

---

## Typography

### Dual-Font System

| Role | Font | Rationale |
|------|------|-----------|
| **Display / Headline / Title** | **Sora** | Geometric, modern, distinctive at large sizes — gives the app a creative identity |
| **Body / Label** | **Inter** | Neutral, highly readable for dense UI — controls, settings, captions |

```dart
// Headlines: Sora
GoogleFonts.outfitTextTheme(base)  // applied to display, headline, title

// Body: Inter
GoogleFonts.interTextTheme(base)   // applied to body, label
```

### Type Scale

| Role | Font | Size | Weight | Usage |
|------|------|------|--------|-------|
| **Display Large** | Sora | 57 | 400 | Splash, onboarding |
| **Display Medium** | Sora | 45 | 400 | Hero sections |
| **Headline Large** | Sora | 32 | 600 | Page titles |
| **Headline Medium** | Sora | 28 | 600 | Section headers |
| **Title Large** | Sora | 22 | 600 | App bar titles |
| **Title Medium** | Sora | 16 | 600 | Card titles |
| **Title Small** | Sora | 14 | 600 | Sub-headings |
| **Body Large** | Inter | 16 | 400 | Primary content |
| **Body Medium** | Inter | 14 | 400 | Secondary content |
| **Body Small** | Inter | 12 | 400 | Captions, timestamps |
| **Label Large** | Inter | 14 | 500 | Buttons, tabs |
| **Label Medium** | Inter | 12 | 500 | Chips, badges |
| **Label Small** | Inter | 11 | 500 | Tiny labels |

---

## Iconography

### Material Symbols (Rounded)
Use `material_symbols_icons` package with the **Rounded** variant for a softer, more creative feel.

```dart
import 'package:material_symbols_icons/material_symbols_icons.dart';

// Usage
Icon(Symbols.photo_camera_rounded)
Icon(Symbols.palette_rounded)
Icon(Symbols.text_fields_rounded)
```

### Key Icons

| Action | Symbol | Variant |
|--------|--------|---------|
| New Design | `Symbols.add_photo_alternate_rounded` | Rounded |
| Settings | `Symbols.settings_rounded` | Rounded |
| Export | `Symbols.file_download_rounded` | Rounded |
| Share | `Symbols.share_rounded` | Rounded |
| Folder | `Symbols.folder_rounded` | Rounded |
| Create Folder | `Symbols.create_new_folder_rounded` | Rounded |
| Delete | `Symbols.delete_rounded` | Rounded |
| Edit | `Symbols.edit_rounded` | Rounded |
| Background | `Symbols.palette_rounded` | Rounded |
| Device Frame | `Symbols.smartphone_rounded` | Rounded |
| Text Overlay | `Symbols.text_fields_rounded` | Rounded |
| Image Overlay | `Symbols.add_photo_alternate_rounded` | Rounded |
| Grid | `Symbols.grid_on_rounded` | Rounded |
| Doodle | `Symbols.draw_rounded` | Rounded |
| Undo | `Symbols.undo_rounded` | Rounded |
| Redo | `Symbols.redo_rounded` | Rounded |
| Zoom In | `Symbols.zoom_in_rounded` | Rounded |
| Zoom Out | `Symbols.zoom_out_rounded` | Rounded |
| Orientation | `Symbols.screen_rotation_rounded` | Rounded |
| Corner Radius | `Symbols.rounded_corner_rounded` | Rounded |
| Theme Toggle | `Symbols.dark_mode_rounded` / `Symbols.light_mode_rounded` | Rounded |
| About | `Symbols.info_rounded` | Rounded |
| Color Picker | `Symbols.colorize_rounded` | Rounded |
| Font | `Symbols.font_download_rounded` | Rounded |
| Canvas | `Symbols.crop_landscape_rounded` | Rounded |
| Multi-Screenshot | `Symbols.view_carousel_rounded` | Rounded |
| Move to Folder | `Symbols.drive_file_move_rounded` | Rounded |
| Duplicate | `Symbols.content_copy_rounded` | Rounded |
| More Options | `Symbols.more_vert_rounded` | Rounded |
| Grid View | `Symbols.grid_view_rounded` | Rounded |
| List View | `Symbols.view_list_rounded` | Rounded |

---

## Components

### Buttons

| Type | Style | Usage |
|------|-------|-------|
| **Primary** | Filled + Indigo | Main actions (Save, Export) |
| **Secondary** | Tonal + Cyan | Secondary actions (Add overlay) |
| **Tertiary** | Outlined + subtle | Cancel, dismiss |
| **Icon Button** | Circle + translucent fill | Toolbar actions |
| **FAB** | Indigo gradient fill | Create new design |

### Cards
- **Corner radius**: 16dp
- **Elevation**: 0 (use border or surface color contrast)
- **Hover effect** (desktop): subtle scale + glow
- **Selection state**: Indigo border + primary container fill

### Editor Controls Panel
- **Desktop**: Right sidebar, 320dp wide, `Surface Container High` background
- **Mobile**: Bottom sheet with rounded top corners (24dp radius)
- **Glass effect**: Semi-transparent background + blur on elevated panels

### Dialogs
- **Corner radius**: 28dp (Material 3 default)
- **Background**: `Surface Container High`

---

## Spacing & Layout

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4dp | Tight inner gaps |
| `sm` | 8dp | Icon-to-text gaps |
| `md` | 16dp | Card padding, section gaps |
| `lg` | 24dp | Page padding |
| `xl` | 32dp | Section separators |
| `xxl` | 48dp | Major layout gaps |

### Grid System
- **Library grid**: 2 columns mobile, 3 columns tablet, 4+ columns desktop
- **Card aspect ratio**: 9:16 (App Store screenshot ratio)
- **Grid gap**: 12dp

---

## Animations & Motion

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| **Page transition** | 300ms | `easeInOut` | Navigation |
| **Panel slide** | 250ms | `easeOutCubic` | Side panel open/close |
| **Card hover** | 150ms | `easeOut` | Scale 1.02x + shadow glow |
| **FAB press** | 100ms | `easeIn` | Scale 0.95x |
| **Overlay drag** | 0ms | — | Direct manipulation (no delay) |
| **Snap feedback** | 50ms | — | Haptic tap on snap |
| **Theme switch** | 400ms | `easeInOut` | Color crossfade |

---

## Dark Mode Specifics

| Element | Style |
|---------|-------|
| **Editor canvas background** | `#0A0A1B` (deepest navy) |
| **Control panel** | `#1A1A2E` with 80% opacity + backdrop blur |
| **Active tool tab** | Indigo 400 text + underline |
| **Inactive tool tab** | Zinc 500 text |
| **Overlay selection handles** | Cyan 400 dots with glow |
| **Grid lines** | `rgba(255, 255, 255, 0.06)` |
| **Grid center lines** | `rgba(99, 102, 241, 0.3)` (indigo, subtle) |

---

## App Bar Styles

### Library Page
- **Style**: Transparent, blending with surface
- **Title**: "App Screenshots" in `titleLarge`
- **Actions**: Grid/List toggle, Settings gear

### Editor Page
- **Style**: Transparent, overlaid on canvas
- **Title**: Design name (editable)
- **Leading**: Back arrow
- **Actions**: Undo, Redo, Export, More menu

---

## Implementation Notes

### Material 3 Theme Configuration
```dart
ColorScheme.fromSeed(
  seedColor: Color(0xFF6366F1),
  brightness: Brightness.dark, // default
)
```

### Material Symbols Setup
Add to `pubspec.yaml`:
```yaml
dependencies:
  material_symbols_icons: ^4.2801.0
```

### Default Theme Mode
```dart
themeMode: ThemeMode.dark // dark mode as default
```
