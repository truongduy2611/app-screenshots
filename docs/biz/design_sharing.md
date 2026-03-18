# 📤 Design Sharing & Import/Export

## Overview

App Screenshots supports sharing and importing complete design files using a custom `.appshots` file format. This allows users to share their designs with others, transfer designs between devices, or back up individual designs manually.

---

## `.appshots` File Format

A `.appshots` file is a self-contained archive of a `SavedDesign`, including all design properties, metadata, and referenced images. It is created by `DesignFileService`.

---

## Features

### F1: Share / Export Design
Export a saved design as a `.appshots` file:

| Platform | Behavior |
|---|---|
| **iOS / Android** | Opens the native share sheet with the file |
| **macOS / Desktop** | Opens a "Save As" file dialog |

### F2: Import Design
Import a `.appshots` file into the design library:
- Opens a file picker filtered to `.appshots` files
- Parses the file and adds the design to the library
- Returns the imported `SavedDesign` for immediate use

### F3: Save Back to File
When a design was opened directly from a `.appshots` file, users can save changes back to the original file path (overwrite).

---

## User Stories

### US-SHR1: Share a Design
```gherkin
Feature: Share Design
  As a user
  I want to share my design as a file
  So that others can import and use my template

  Scenario: Share on mobile
    Given I have a saved design
    When I tap "Share" from the design's context menu
    Then a .appshots file is created
    And the system share sheet opens with the file

  Scenario: Export on desktop
    Given I have a saved design
    When I tap "Export" from the context menu
    Then a file save dialog opens
    And I can save the .appshots file to any location
```

### US-SHR2: Import a Design
```gherkin
Feature: Import Design
  As a user
  I want to import a .appshots file
  So that I can use a design shared by someone else

  Scenario: Import from file picker
    Given I tap "Import" in the library
    When I select a valid .appshots file
    Then the design is added to my library
    And I can open and edit it immediately
```

---

## Acceptance Criteria

- [x] Share produces a valid `.appshots` file on all platforms
- [x] Import correctly parses `.appshots` files and adds to library
- [x] Mobile uses native share sheet; desktop uses file save dialog
- [x] Imported designs are fully editable
- [x] Save-to-file overwrites the original `.appshots` file when requested
