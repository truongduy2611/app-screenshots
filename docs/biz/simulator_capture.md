# 📱 Simulator Screenshot Capture

## Overview

Simulator Screenshot Capture automates the process of capturing App Store screenshots directly from running iOS Simulators. Instead of manually taking screenshots and importing them, users can capture, navigate, and batch-capture screenshots from within the app — then feed them directly into the existing editor, framing, and upload pipeline.

> [!IMPORTANT]
> **Status: ⬜ Planned — Not Yet Implemented.** This feature is part of the roadmap but no code has been written. The document below describes the intended design.

---

## Features

### F1: Simulator Discovery
List all available iOS Simulators (booted and available), showing device name, OS version, UDID, and boot state.

### F2: Single Screenshot Capture
Capture a screenshot from a booted simulator with one click. The captured PNG is automatically imported into the current multi-screenshot design.

### F3: App Launcher
Launch an iOS app by bundle ID on a selected simulator before capturing, ensuring the correct app is in the foreground.

### F4: Automation Plan Runner
Define and execute a deterministic sequence of automation steps (launch, tap, type, wait, screenshot) to capture multiple screenshots unattended.

### F5: Multi-Device Batch Capture
Run the same automation plan across multiple simulator device types to produce screenshots for all required App Store display sizes in one pass.

### F6: Capture-to-Editor Integration
Captured screenshots are automatically imported into the multi-screenshot editor as new design entries, ready for framing, localization, and upload to App Store Connect.

---

## Automation Plan Actions

| Action | Description | Required Fields |
|---|---|---|
| `launch` | Launch app on simulator | *(uses plan's bundle_id)* |
| `tap` | Tap a UI element | `label`, `id`, or `x` + `y` |
| `type` | Type text | `text` |
| `key_sequence` | Send key codes | `keycodes[]` |
| `wait` | Static delay | `duration_ms` |
| `wait_for` | Poll until element appears | `label`/`id`/`contains`, `timeout_ms` |
| `screenshot` | Capture current screen | `name` |

---

## User Stories

### Simulator Discovery & Capture

#### US-SC1: Browse Available Simulators
```gherkin
Feature: Browse Available Simulators
  As a user
  I want to see all available iOS Simulators on my Mac
  So that I can select the right device for capturing screenshots

  Scenario: List booted simulators
    Given I open the Capture feature
    When the simulator list loads
    Then I see all booted simulators with device name, OS, and UDID

  Scenario: No booted simulators
    Given no simulators are booted
    When I open the Capture feature
    Then I see a message "No booted simulators found"
    And a button to open Simulator.app
```

#### US-SC2: Capture Single Screenshot
```gherkin
Feature: Capture Single Screenshot
  As a user
  I want to capture a screenshot from a running simulator
  So that I can use it in my App Store design

  Scenario: Capture from booted simulator
    Given I have a booted simulator selected
    When I tap "Capture"
    Then a screenshot PNG is captured
    And it is imported into the current design as a new entry

  Scenario: Capture with app launch
    Given I have entered a bundle ID
    When I tap "Launch & Capture"
    Then the app launches on the simulator
    And after a brief delay, a screenshot is captured
```

#### US-SC3: Capture Preview
```gherkin
Feature: Capture Preview
  As a user
  I want to see a live preview of captured screenshots
  So that I can verify the content before proceeding

  Scenario: Preview captured screenshot
    Given I have captured a screenshot
    When the capture completes
    Then I see a thumbnail preview of the captured image
    And I can choose to "Keep" or "Retake"
```

### Automation Plan

#### US-SC4: Create Automation Plan
```gherkin
Feature: Create Automation Plan
  As a user
  I want to define a sequence of automation steps
  So that I can capture multiple screenshots hands-free

  Scenario: Build a plan
    Given I am in the Plan Editor
    When I add steps: Launch → Wait(2s) → Screenshot("home") → Tap("Settings") → Screenshot("settings")
    Then my plan is saved as a JSON file

  Scenario: Load existing plan
    Given I have a previously saved plan
    When I open the Plan Editor
    Then I see all steps listed and editable
```

#### US-SC5: Run Automation Plan
```gherkin
Feature: Run Automation Plan
  As a user
  I want to execute my automation plan
  So that screenshots are captured automatically

  Scenario: Execute plan successfully
    Given I have a valid automation plan
    When I tap "Run Plan"
    Then each step executes sequentially with progress indicators
    And captured screenshots appear in the editor

  Scenario: Step failure
    Given a step fails (e.g., element not found)
    When the plan encounters an error
    Then execution stops with the error highlighted
    And previously captured screenshots are preserved
```

### Multi-Device Batch

#### US-SC6: Batch Capture Across Devices
```gherkin
Feature: Batch Capture Across Devices
  As a user
  I want to run my plan on multiple simulator devices
  So that I get screenshots for all required App Store sizes

  Scenario: Select multiple devices
    Given I have an automation plan
    When I select iPhone 16 Pro Max, iPhone 16 Pro, and iPhone SE
    And I tap "Run All"
    Then the plan executes on each device sequentially
    And captured screenshots are grouped by device type

  Scenario: Size validation
    Given batch capture has completed
    When I view captured screenshots
    Then each screenshot shows its matching ASC display type
    And invalid-size screenshots are flagged
```

---

## Acceptance Criteria

### Simulator Management
- [ ] User can see all booted iOS Simulators with device name, OS version, and UDID
- [ ] User can refresh the simulator list
- [ ] Empty state shown when no simulators are booted
- [ ] User can launch an app by bundle ID on a selected simulator

### Single Capture
- [ ] User can capture a screenshot from any booted simulator
- [ ] Captured PNG is saved to a configurable output directory
- [ ] Captured image is auto-imported into the current multi-screenshot design
- [ ] Capture dimensions match the simulator's screen size
- [ ] User sees a preview with keep/retake options

### Automation Plans
- [ ] User can create, edit, save, and load JSON plan files
- [ ] Plan supports all actions: launch, tap, type, key_sequence, wait, wait_for, screenshot
- [ ] Plan validates required fields before execution
- [ ] User sees real-time step progress during execution
- [ ] Errors stop execution and display the failure details
- [ ] Captured screenshots are named per the plan's `name` fields

### Multi-Device Batch
- [ ] User can select multiple simulator device types
- [ ] Plan runs sequentially on each selected device
- [ ] Screenshots are organized by device type
- [ ] Each screenshot's dimensions are validated against ASC display types

### Integration
- [ ] Captured screenshots integrate with existing framing pipeline
- [ ] Captured screenshots integrate with existing ASC upload pipeline
- [ ] Captured screenshots integrate with existing localization workflow

---

## Platform Requirements

> ⚠️ **macOS Only** — This feature requires `xcrun simctl` from Xcode Command Line Tools and is available only on macOS desktop.

| Requirement | Details |
|---|---|
| **Xcode CLI Tools** | `xcrun simctl` must be available in PATH |
| **Booted Simulator** | At least one iOS Simulator must be booted |
| **AXe CLI** | Optional, for UI accessibility-based tap/type automation |

*See [Development Documentation](../dev/simulator_capture.md) for implementation details and key files.*
