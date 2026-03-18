# 📸 Screenshot Studio — Development Documentation

## Architecture

Clean Architecture (without use cases) with `flutter_bloc` for state management.

```
lib/features/screenshot_editor/
├── data/
│   ├── models/
│   │   ├── screenshot_design.dart      # Core design model (all canvas properties)
│   │   ├── saved_design.dart           # Persisted design with metadata
│   │   └── design_folder.dart          # Folder model for organization
│   └── services/
│       └── screenshot_persistence_service.dart  # JSON + file-system persistence
├── domain/
│   └── repositories/
│       └── screenshot_repository.dart  # Repository interface
├── presentation/
│   ├── cubit/
│   │   ├── screenshot_editor_cubit.dart   # Editor state management
│   │   ├── screenshot_editor_state.dart   # Editor state
│   │   └── screenshot_library_cubit.dart  # Library (list/folder) management
│   ├── models/
│   │   └── screenshot_studio_item.dart    # Union type for grid items
│   ├── pages/
│   │   ├── screenshot_studio_page.dart    # Library/home page
│   │   └── screenshot_editor_page.dart    # Editor page
│   └── widgets/
│       ├── controls/
│       │   ├── background_controls.dart   # Color + gradient picker
│       │   ├── frame_controls.dart        # Device frame selection
│       │   ├── text_controls.dart         # Text overlay styling
│       │   ├── doodle_controls.dart       # Doodle pattern config
│       │   ├── grid_controls.dart         # Grid + snap settings
│       │   ├── font_picker_sheet.dart     # Google Fonts picker
│       │   ├── gradient_editor.dart       # Multi-stop gradient editor
│       │   └── desktop_editor_controls.dart  # Desktop sidebar layout
│       ├── editor_canvas.dart             # Main canvas widget
│       ├── grid_overlay.dart              # Grid line rendering
│       ├── doodle_background.dart         # Doodle pattern rendering
│       ├── design_card.dart               # Grid view design card
│       ├── design_list_tile.dart          # List view design tile
│       ├── folder_card.dart               # Grid view folder card
│       ├── folder_list_tile.dart          # List view folder tile
│       ├── device_selection_dialog.dart   # Device type picker
│       ├── library_manager_dialog.dart    # Move-to-folder dialog
│       ├── screenshot_studio_empty_state.dart
│       ├── screenshot_studio_grid_view.dart
│       └── screenshot_studio_list_view.dart
└── utils/
    └── screenshot_utils.dart              # Device dimensions + category
```

---

## Key Models

### `ScreenshotDesign`
The core data model for a design. Contains:

| Field | Type | Description |
|-------|------|-------------|
| `backgroundColor` | `Color` | Solid fill color |
| `backgroundGradient` | `Gradient?` | Linear gradient (nullable) |
| `deviceFrame` | `DeviceInfo?` | Device bezel from `device_frame` |
| `overlays` | `List<TextOverlay>` | Text labels |
| `imageOverlays` | `List<ImageOverlay>` | Image layers |
| `padding` | `double` | Canvas padding |
| `imagePosition` | `Offset` | Screenshot position offset |
| `displayType` | `String?` | Device category identifier |
| `orientation` | `Orientation` | Portrait or landscape |
| `frameRotation` | `double` | Device frame tilt angle |
| `gridSettings` | `GridSettings` | Grid configuration |
| `cornerRadius` | `double` | Canvas corner radius |
| `doodleSettings` | `DoodleSettings?` | Icon pattern background |

Serializes to/from JSON for persistence.

### `SavedDesign`
Wraps `ScreenshotDesign` with library metadata: `id`, `name`, `lastModified`, `thumbnailPath`, `imagePath`, `folderId`.

### `DesignFolder`
Folder with `id`, `name`, `createdAt`, `parentId` for nesting.

---

## Key Cubits

### `ScreenshotEditorCubit`
Manages the active editor session:
- Image loading (file picker, drag & drop, URL download)
- All design property updates (background, frame, padding, overlays, etc.)
- Overlay CRUD (add, update, delete, select text/image overlays)
- Grid snap logic
- Save and load designs via `ScreenshotPersistenceService`

### `ScreenshotLibraryCubit`
Manages the design library:
- Load all designs and folders
- Filter by current folder (supports nested navigation)
- CRUD operations: create/rename/delete folders, delete/move designs

---

## Persistence

Uses `path_provider` + JSON files stored in the app documents directory:
- `screenshot_designs/` — Individual design JSON + thumbnail + original image files
- `screenshot_folders/folders.json` — All folder definitions
- Grid settings persisted to `SharedPreferences` for cross-session defaults

---

## Export Pipeline

1. **Capture**: `screenshot` package captures the `EditorCanvas` widget as `Uint8List`
2. **Resize**: `image` package resizes to exact App Store dimensions
3. **Save**: Written to temp directory as PNG
4. **Share**: `share_plus` opens system share sheet with the exported file

---

## Responsive Layout

| Breakpoint | Behavior |
|------------|----------|
| **≥ 600px** (desktop) | Editor canvas + sidebar control panel |
| **< 600px** (mobile) | Full canvas, controls in modal bottom sheets |

Desktop controls use `DesktopEditorControls` widget (vertical tab-like sidebar).
Mobile controls use `showModalBottomSheet`.

---

## New Feature: Multi-Screenshot Canvas

### Concept
A single long canvas composed of up to 10 screenshot slots arranged vertically. Each slot has:
- Its own screenshot image
- Independent image position within its slot
- Optional per-slot text overlays

Shared across all slots:
- Background color/gradient/doodle
- Device frame selection
- Grid settings

### Export
On export, the long canvas is sliced into 10 individual images at the target device dimensions.

### Data Model Extension
```dart
class MultiScreenshotDesign {
  final List<ScreenshotSlot> slots; // max 10
  final ScreenshotDesign sharedDesign; // shared background, frame, grid
}

class ScreenshotSlot {
  final String id;
  final File? imageFile;
  final Offset imagePosition;
  final List<TextOverlay> overlays;
  final List<ImageOverlay> imageOverlays;
}
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `device_frame` | ^1.4.0 | Device bezel rendering |
| `screenshot` | ^3.0.0 | Widget capture to image |
| `flutter_colorpicker` | ^1.1.0 | Color picker dialog |
| `google_fonts` | ^6.3.3 | Google Fonts for text overlays |
| `desktop_drop` | ^0.7.0 | Drag & drop on desktop |
| `file_picker` | ^10.3.7 | File selection |
| `image` | ^4.5.4 | Image resizing for export |
| `share_plus` | ^12.0.1 | System share sheet |
| `uuid` | ^4.5.2 | Unique IDs for overlays |
| `path_provider` | any | App documents directory |
| `http` | ^1.6.0 | Image download from URL |

---

## Roadmap — Implementation Notes

### 1. Clone Design via Device Change
- **Action Flow:** Library grid context menu → `DeviceSelectionDialog` → `CloneDesignWithFormat` event to `ScreenshotLibraryCubit`
- **Scaling Logic:** Calculate `Size(newWidth / oldWidth, newHeight / oldHeight)` ratio, apply to overlay `position`, `fontSize`, `scale`
- **State Impact:** Creates a new `SavedDesign` with a new UUID

### 2. Layer Management (Z-Index)
- **Option A (Unified List):** Base `CanvasLayer` interface with `List<CanvasLayer> layers`
- **Option B (Z-Index Prop):** Add `int zIndex` to `TextOverlay` and `ImageOverlay`, merge and sort before rendering
- **Cubit Events:** `BringOverlayForward(id)`, `SendOverlayBackward(id)`

### 3. Library Multi-Select & Batch Operations
- **State:** Add `Set<String> selectedDesignIds` and `bool isSelectionMode` to `ScreenshotLibraryState`
- **Cubit Events:** `ToggleSelectionMode`, `SelectDesign`, `BatchDelete`, `BatchMoveToFolder`
- **UI:** Contextual `SliverAppBar` with Trash/Move/Export actions when `isSelectionMode == true`

### 4. Custom Templates / Presets
- **Data Model:** `CustomTemplate` — a `ScreenshotDesign` with `imagePath` cleared
- **Persistence:** `screenshot_templates/` directory
- **UI:** Tab split in `PresetPickerDialog` — "System Presets" vs "My Templates"

### 5. Drag-to-Reorder Canvas Slots
- Replace static `ListView` with `ReorderableListView(scrollDirection: Axis.horizontal)` in `multi_page_canvas.dart`
- Add `ReorderCanvasSlots(oldIndex, newIndex)` to `MultiScreenshotCubit`

### 6. 3D Device Transforms
- Add `double rotateX/Y/Z` to `ScreenshotDesign`
- Wrap `DeviceFrame` in `Transform` with perspective `Matrix4.identity()..setEntry(3, 2, 0.001)`
- New "3D Transform" sidebar panel with rotation sliders

### 7. Global Undo/Redo History
- `List<ScreenshotDesign> _undoStack/_redoStack` capped at 20 entries
- Push snapshot on every mutative cubit method; clear redo stack
- Debounce continuous gestures — push only on `onPanStart`/`onChangeEnd`
