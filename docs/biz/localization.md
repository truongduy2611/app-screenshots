# 🌍 Localization

## Overview

App Screenshots supports **18 languages** using Flutter's built-in `intl` / `flutter_localizations` system with ARB files. All user-facing strings are localized, including Settings labels and editor controls.

---

## Supported Languages

| Code | Language |
|---|---|
| `en` | English (primary) |
| `ar` | Arabic |
| `de` | German |
| `es` | Spanish |
| `fr` | French |
| `it` | Italian |
| `ja` | Japanese |
| `ko` | Korean |
| `nl` | Dutch |
| `pt` | Portuguese |
| `ru` | Russian |
| `th` | Thai |
| `tr` | Turkish |
| `vi` | Vietnamese |
| `zh` | Chinese (Simplified) |
| `zh_Hant` | Chinese (Traditional) |

---

## Architecture

| Component | Path |
|---|---|
| **ARB files** | `lib/l10n/app_<locale>.arb` |
| **Config** | `l10n.yaml` |
| **Access** | `context.l10n.<key>` via context extensions |

All strings are accessed through generated localization classes — no hard-coded strings in the UI.

---

## User Stories

### US-L10N1: Auto-detect Language
```gherkin
Feature: Automatic Localization
  As a user
  I want the app to display in my device's language
  So that I can use the app comfortably

  Scenario: Device set to Japanese
    Given my device language is Japanese
    When I launch App Screenshots
    Then all UI strings appear in Japanese
```

---

## Acceptance Criteria

- [x] App loads the correct locale based on device settings
- [x] All user-facing strings use `context.l10n` — no hard-coded English
- [x] RTL layout works correctly for Arabic
- [x] Fallback to English for unsupported locales
- [x] App Store metadata is localized for key markets
