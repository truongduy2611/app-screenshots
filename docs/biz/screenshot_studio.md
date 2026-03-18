# 📸 Screenshot Studio

## Overview

The Screenshot Studio is the core feature of App Screenshots. It enables users to design beautiful, professional App Store screenshots with device frames, text overlays, image overlays, custom backgrounds, and export capabilities. Designs are organized in a folder-based library and persisted locally.

---

## Features

### F1: Design Creation
Create new screenshot designs by selecting a target device type (iPhone, iPad, etc.) and entering the editor canvas.

### F2: Screenshot Editor
Full-featured visual editor with:
- Background customization (solid color, gradient, doodle patterns)
- Device frame selection and configuration
- Screenshot image import (file picker + drag & drop)
- Text overlays with rich styling
- Image overlays with resize/rotate
- Grid and snap-to-grid alignment tools
- Orientation toggle (portrait/landscape)
- Corner radius adjustment
- Frame rotation

### F3: Design Library
Browse, manage, and organize saved designs in a grid or list view. Supports folders for grouping.

### F4: Folder Management
Create, rename, delete, and nest folders. Move designs between folders.

### F5: Multi-Screenshot Canvas (NEW)
A long canvas mode that supports composing up to 10 screenshots in a single design — export all at once for a complete App Store listing.

### F6: Export & Share
Export designs as high-resolution PNG images. Share directly from the app.

---

## Design Properties

| Property | Description | Required |
|----------|-------------|----------|
| **Background Color** | Solid color behind the canvas | ✅ |
| **Background Gradient** | Linear gradient (multi-stop) | ❌ |
| **Device Frame** | Device bezel around the screenshot | ❌ |
| **Screenshot Image** | The app screenshot to showcase | ❌ |
| **Text Overlays** | Draggable, styled text labels (max 10) | ❌ |
| **Image Overlays** | Draggable, resizable images (max 10) | ❌ |
| **Padding** | Space between canvas edge and content | ✅ |
| **Image Position** | Offset of the screenshot within the frame | ✅ |
| **Orientation** | Portrait or Landscape | ✅ |
| **Frame Rotation** | Angle of device frame tilt | ❌ |
| **Corner Radius** | Rounded corners on the canvas | ❌ |
| **Grid Settings** | Show grid, snap-to-grid, center lines | ❌ |
| **Doodle Settings** | Pattern-fill background with icons | ❌ |

---

## Text Overlay Properties

| Property | Description |
|----------|-------------|
| **Text** | Content string |
| **Font** | Google Fonts selection |
| **Font Size** | Size in px |
| **Font Weight** | Bold, normal, etc. |
| **Font Style** | Normal, italic |
| **Color** | Text color |
| **Position** | Drag offset on canvas |
| **Rotation** | Angle in degrees |
| **Scale** | Pinch-to-zoom scale factor |
| **Text Align** | Left, center, right |
| **Decoration** | Underline, overline, line-through |
| **Background Color** | Container fill behind text |
| **Border** | Color, width, radius |
| **Padding** | Horizontal and vertical |

---

## Image Overlay Properties

| Property | Description |
|----------|-------------|
| **File Path** | Source image file |
| **Position** | Drag offset on canvas |
| **Scale** | Scale factor |
| **Rotation** | Angle in degrees |
| **Width / Height** | Resize handles |

---

## Doodle Background Properties

| Property | Description |
|----------|-------------|
| **Icon Source** | SF Symbols or Material Symbols |
| **Icon Code Points** | Selected icon set |
| **Icon Color / Gradient** | Solid or gradient fill |
| **Opacity** | Transparency (default 8%) |
| **Icon Size** | Size in px |
| **Spacing** | Distance between icons |
| **Rotation** | Base rotation angle |
| **Randomize Rotation** | Randomized icon angles |

---

## Saved Design Properties

| Property | Description | Required |
|----------|-------------|----------|
| **Name** | Display name | ✅ |
| **Thumbnail** | Auto-generated preview image | ✅ |
| **Image Path** | Original screenshot file path | ❌ |
| **Folder ID** | Organization folder | ❌ |
| **Design** | Full ScreenshotDesign data | ✅ |

---

## User Stories

### Design Creation

#### US-SS1: Create New Screenshot Design
```gherkin
Feature: Create New Screenshot Design
  As a user
  I want to create a screenshot design for a specific device
  So that I can produce App Store-ready screenshots

  Scenario: Create design for iPhone
    Given I am on the design library page
    When I tap "New Design"
    And I select "iPhone 16 Pro Max" from the device picker
    Then I enter the editor with the correct canvas size

  Scenario: Import screenshot image
    Given I am in the editor
    When I pick an image from the file picker
    Then the image appears on the canvas within the device frame

  Scenario: Desktop drag & drop
    Given I am on desktop
    When I drag an image file onto the editor canvas
    Then the image is imported automatically
```

#### US-SS2: Customize Design Background
```gherkin
Feature: Customize Design Background
  As a user
  I want to set a background color, gradient, or doodle pattern
  So that my screenshot stands out

  Scenario: Set solid background color
    Given I am in the editor
    When I open background controls
    And I pick a color
    Then the canvas background updates

  Scenario: Apply gradient background
    Given I am in the editor
    When I open the gradient editor
    And I configure a multi-stop gradient
    Then the gradient is applied to the background

  Scenario: Enable doodle pattern
    Given I am in the editor
    When I open doodle controls
    And I select icons and configure spacing
    Then a repeating icon pattern appears behind the screenshot
```

#### US-SS3: Add Text Overlay
```gherkin
Feature: Add Text Overlay
  As a user
  I want to add styled text to my screenshot design
  So that I can highlight features

  Scenario: Add and style text
    Given I am in the editor
    When I add a text overlay
    And I type "Fast & Secure"
    And I set font, size, and color
    Then the styled text appears on the canvas

  Scenario: Move and rotate text
    Given I have a text overlay on the canvas
    When I drag it to a new position
    And I rotate it
    Then the text remains in the new position and angle
```

#### US-SS4: Add Image Overlay
```gherkin
Feature: Add Image Overlay
  As a user
  I want to add logos or badges on top of my design
  So that I can brand my screenshots

  Scenario: Add image overlay
    Given I am in the editor
    When I add an image overlay
    Then it appears on the canvas with resize handles

  Scenario: Resize image overlay
    Given I have an image overlay selected
    When I drag a corner handle
    Then the overlay resizes proportionally
```

### Design Library

#### US-SS5: Manage Design Library
```gherkin
Feature: Manage Design Library
  As a user
  I want to save, browse, and organize my designs
  So that I can reuse and update them

  Scenario: Save design to library
    Given I am in the editor
    When I tap "Save" and enter a name
    Then the design appears in my library

  Scenario: Open saved design
    Given I have saved designs
    When I tap a design card
    Then it opens in the editor with all settings restored

  Scenario: Delete design
    Given I have a saved design
    When I select "Delete" from the context menu
    Then the design is removed from the library
```

#### US-SS6: Organize with Folders
```gherkin
Feature: Organize Designs with Folders
  As a user
  I want to organize designs into folders
  So that I can group designs by app or project

  Scenario: Create folder
    Given I am on the library page
    When I tap the folder icon
    And I enter a folder name
    Then the folder appears in my library

  Scenario: Move design to folder
    Given I have designs and folders
    When I move a design into a folder
    Then the design appears inside that folder

  Scenario: Nested folders
    Given I have a folder
    When I create a sub-folder inside it
    Then I can navigate the folder hierarchy
```

### Multi-Screenshot Canvas (NEW)

#### US-SS7: Multi-Screenshot Mode
```gherkin
Feature: Multi-Screenshot Canvas
  As a user
  I want to compose up to 10 screenshots in a single long canvas
  So that I can export a complete App Store listing at once

  Scenario: Create multi-screenshot design
    Given I am creating a new design
    When I select "Multi-Screenshot" mode
    And I add screenshots (up to 10)
    Then each screenshot appears in its own section of the canvas

  Scenario: Export all screenshots
    Given I have a multi-screenshot design
    When I tap "Export All"
    Then 10 individual high-resolution images are exported
```

### Export

#### US-SS8: Export & Share
```gherkin
Feature: Export & Share Design
  As a user
  I want to export my design as a high-resolution PNG
  So that I can upload it to the App Store

  Scenario: Export single screenshot
    Given I have a completed design
    When I tap "Export"
    Then a high-resolution PNG is saved to the device

  Scenario: Share design
    Given I have exported a design
    When I tap "Share"
    Then the system share sheet opens with the exported image
```

---

## Acceptance Criteria

### Editor Canvas
- [x] User can select a target device type
- [x] Canvas renders at exact App Store dimensions
- [x] User can import screenshot images (file picker + drag & drop)
- [x] User can pan/position the screenshot within the canvas
- [x] Orientation toggle works (portrait ↔ landscape)

### Background Customization
- [x] User can set a solid background color
- [x] User can apply a linear gradient with multiple stops
- [x] User can enable a doodle icon pattern background
- [x] Doodle supports icon color, gradient, opacity, size, spacing, rotation

### Device Frames
- [x] User can select from available device frames
- [x] User can remove the device frame entirely
- [x] User can adjust frame rotation

### Overlays
- [x] User can add up to 10 text overlays
- [x] Text overlays support full styling (font, size, weight, color, rotation, scale, alignment, decoration, container background/border)
- [x] User can add up to 10 image overlays
- [x] Image overlays support drag, resize (corner handles), and rotation
- [x] User can delete selected overlays

### Grid & Alignment
- [x] User can show/hide grid overlay
- [x] Snap-to-grid works when dragging
- [x] Center lines show for quick centering
- [x] Grid settings persist across sessions

### Library & Folders
- [x] User can save designs with name and auto-thumbnail
- [x] User can open, duplicate, and delete saved designs
- [x] User can create, rename, and delete folders
- [x] User can move designs between folders
- [x] Grid and list view modes

### Multi-Screenshot Canvas (NEW)
- [x] User can create a canvas with multiple screenshot slots (max 10)
- [x] Each slot can have its own screenshot image
- [x] Shared background and text overlays span the full canvas
- [x] Export produces individual images per slot

### Export
- [x] Export as high-resolution PNG at exact App Store dimensions
- [x] Share via system share sheet
- [x] Multi-screenshot export produces up to 10 individual images

---

## Dependencies
- `device_frame` — Device bezel rendering
- `screenshot` — Widget-to-image capture
- `flutter_colorpicker` — Color selection
- `google_fonts` — Font selection
- `desktop_drop` — Desktop drag & drop
- `file_picker` — File selection
- `image` — Image processing
- `share_plus` — Sharing

---

## Responsive Layout

| Platform | Layout |
|----------|--------|
| **Desktop** (≥ 600px) | Editor canvas on left, control panel sidebar on right |
| **Mobile** (< 600px) | Full-screen canvas, controls in bottom sheets |

---

## Roadmap

### 1. Clone Design via Device Change
Duplicate a design and adapt it to a different device format (e.g., iPhone → iPad). The system scales and repositions overlays proportionally.
```gherkin
Scenario: Clone to iPad
  Given I have a saved iPhone design in my library
  When I open the context menu and select "Clone to Format"
  And I select "iPad Pro 13-inch" from the device picker
  Then a new design is created with the iPad dimensions
  And the original background, text, and overlays are preserved and scaled proportionally
```

### 2. Layer Management (Z-Index)
Control the stacking order of text and image overlays with "Bring Forward" / "Send Backward" controls.
```gherkin
Scenario: Bring text to front
  Given I have an image overlay that covers my text overlay
  When I select the text overlay and tap "Bring to Front"
  Then the text appears visually on top of the image overlay
```

### 3. Library Multi-Select & Batch Operations
Long-press to enter selection mode, then batch delete, move, or export multiple designs at once.
```gherkin
Scenario: Batch move to folder
  Given I am viewing the design library
  When I long-press a design to enter selection mode
  And I select three designs and tap "Move to Folder"
  Then all three designs are moved simultaneously
```

### 4. Custom Templates / Presets
Save the current canvas configuration (backgrounds, text styling, overlay positions) as a reusable template, stored in a "My Templates" library.

### 5. Drag-to-Reorder Canvas Slots
Enable drag-and-drop reordering of screenshot slots in the multi-screenshot editor to adjust the visual narrative flow.

### 6. 3D Device Transforms (Isometric Views)
Tilt and rotate device frames in 3D space using X/Y/Z rotation sliders to create trendy isometric presentations.

### 7. Global Undo/Redo History
A unified history stack that records snapshots of the design state, allowing undo/redo of any editor action with a toolbar button.

---

*See [Development Documentation](../dev/screenshot_studio.md) for implementation details and key files.*
