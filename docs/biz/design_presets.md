# 🎨 Design Presets

## Overview

Design Presets are pre-built screenshot templates that give users a head start when creating multi-screenshot designs. Each preset provides 5 professionally styled `ScreenshotDesign` instances with coordinated backgrounds, fonts, and text overlays. Users can apply a preset and then customize it by editing text and importing their own screenshots.

---

## Preset Structure

Each `ScreenshotPreset` contains:

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Unique preset identifier |
| `name` | `String` | Display name (e.g. "Midnight Gradient") |
| `description` | `String` | Short description of the style |
| `thumbnailColors` | `List<Color>` | Colors for preview thumbnail |
| `titleFont` | `String` | Google Font name used for titles |
| `designs` | `List<ScreenshotDesign>` | 5 template designs |

---

## How Presets Work

1. **User opens the preset picker** from the multi-screenshot editor
2. **User selects a preset** — previewed with thumbnail colors and name
3. **Preset is applied** — the cubit applies the preset's styling to existing screenshots:
   - Designs are cycled **round-robin** so all current slots receive styling
   - **Existing screenshot images are preserved** — only styling changes
   - Device frame is auto-applied based on the user's chosen device type
4. **User customizes** — edits text overlays, imports screenshots, adjusts colors

---

## User Stories

### US-PRE1: Apply a Preset
```gherkin
Feature: Apply Design Preset
  As a user
  I want to apply a preset template to my multi-screenshot design
  So that I get a professional look without starting from scratch

  Scenario: Apply preset to existing screenshots
    Given I have 3 screenshots in the multi-screenshot editor
    When I open the preset picker and select "Midnight Gradient"
    Then all 3 screenshots receive the preset's styling
    And my imported screenshot images are preserved
    And the preset's text overlays are applied

  Scenario: Apply preset to empty canvas
    Given I have no screenshots yet
    When I apply a preset
    Then 5 new screenshots are created with the preset's styling
```

---

## Acceptance Criteria

- [x] Preset picker displays all available presets with thumbnail previews
- [x] Applying a preset preserves existing screenshot images
- [x] Designs cycle round-robin when there are more/fewer slots than preset templates
- [x] Device frame is auto-applied based on the user's chosen device
- [x] Text overlays from preset are editable after applying
- [x] User can switch presets without losing imported images
