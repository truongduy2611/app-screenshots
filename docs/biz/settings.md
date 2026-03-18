# ⚙️ Settings & Preferences

## Overview

Settings provides app-wide configuration including appearance, app icon customization, iCloud backup/restore, support links, and legal information. It renders as a dialog on desktop (≥ 600px) or a full-page route on mobile.

---

## Features

### F1: Theme / Appearance
Users can switch between three theme modes:

| Mode | Behavior |
|---|---|
| **System** | Follows the device's light/dark setting |
| **Light** | Always light mode |
| **Dark** | Always dark mode (app default) |

Persisted via `SharedPreferences`.

### F2: App Icon
Users can choose between two app icon variants:

| Icon | Name |
|---|---|
| **Default** | Main app icon (`main-icon.png`) |
| **Purple** | Alternative icon (`app-icon.png`) |

- On **iOS**: Uses `UIApplication.setAlternateIconName` — OS persists the choice.
- On **macOS**: Dock icon is reapplied on every launch (OS does not persist alternate icons).

### F3: iCloud Backup & Restore
Automatic and manual backup of all saved designs to iCloud.

| Capability | Description |
|---|---|
| **Auto-backup** | Toggleable; runs in background when enabled |
| **Manual backup** | One-tap "Back Up Now" |
| **Restore** | Pick from a list of available backups to restore |
| **Delete backup** | Remove individual backup snapshots |
| **Conflict handling** | Auto-merge on restore |

### F4: Support
| Action | Destination |
|---|---|
| Rate on App Store | Your App Store review URL |
| Send Feedback | Your feedback email |
| Redeem Code | `apps.apple.com/redeem` |
| GitHub | Open source repository link |

### F5: Legal
| Link | URL |
|---|---|
| Terms of Service | Your Terms of Service URL |
| Privacy Policy | Your Privacy Policy URL |

### F6: About
- Shows app name and version

### F7: Review Prompt
A subtle card at the bottom of Settings that triggers the native `InAppReview` prompt when tapped.

---

## User Stories

### US-SET1: Change Theme
```gherkin
Feature: Change Theme
  As a user
  I want to switch between light, dark, and system themes
  So that the app matches my visual preference

  Scenario: Switch to light mode
    Given I am in Settings
    When I select "Light" in the Appearance segment
    Then the entire app switches to light mode
    And the preference is remembered on next launch
```

### US-SET2: Change App Icon
```gherkin
Feature: Change App Icon
  As a user
  I want to choose an alternative app icon
  So that I can personalize the app on my home screen

  Scenario: Select alternative icon
    Given I am in Settings → App Icon
    When I tap the "Purple" icon card
    Then the app icon changes to the purple variant
```

### US-SET3: iCloud Backup
```gherkin
Feature: iCloud Backup
  As a user
  I want to back up my designs to iCloud
  So that I can restore them on another device or after reinstalling

  Scenario: Enable auto-backup
    Given I am in Settings → iCloud Backup
    When I toggle auto-backup on
    Then a backup runs in the background
    And future backups happen automatically

  Scenario: Manual backup
    Given auto-backup is off
    When I tap "Back Up Now"
    Then a backup is created immediately

  Scenario: Restore from backup
    Given I have one or more iCloud backups
    When I tap a backup to restore
    Then my designs are restored with auto-merge for conflicts
```

---

## Acceptance Criteria

- [ ] Theme segmented control with 3 modes persists across sessions
- [x] App icon picker shows 2 variants with selected state
- [x] iCloud backup toggle, manual backup, restore, and delete all work
- [x] Rate, Feedback, and Redeem links open correctly
- [x] Legal links open in external browser

- [x] Review prompt card triggers `InAppReview`

---

*See [Architecture](../dev/architecture.md) for implementation details on `ThemeCubit`, `AppIconCubit`, and `BackupCubit`.*
