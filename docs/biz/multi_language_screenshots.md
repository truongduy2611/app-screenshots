# 🌐 Multi-Language Screenshot Localization

## Overview

Multi-Language Screenshots lets users **translate all text overlays** in a design into multiple languages and **export one set of screenshots per locale** — eliminating the need to manually duplicate and re-edit designs for each App Store language. Translation is powered by **Apple's on-device Foundation Model** (zero cost, no keys needed) for Mac users, plus **BYOK cloud providers** (OpenAI, Google Gemini, DeepL) and a **manual copy-paste flow** for users who want alternatives. No server-side infrastructure, no proxy, no cost to us.

---

## Problem

App Store Connect supports **40+ locales**. Indie developers who design beautiful multi-screenshot layouts today must:

1. Duplicate the entire design set for each language.
2. Manually replace every text overlay with translated text.
3. Re-export all screenshots per locale.

This is slow, error-prone, and a major barrier to international reach.

---

## Solution

A translation layer inside the existing multi-screenshot editor that:

1. **Stores per-locale translations** alongside each text overlay.
2. **Translates all texts** in one tap via user-configured AI providers — or lets users copy/paste via the manual flow.
3. **Caches translations** in an in-memory translation memory to avoid redundant API calls.
4. **Previews the design** in any locale before exporting, with per-locale layout overrides.
5. **Batch-exports** all locales in one operation (N locales × M screenshots).
6. *(Planned)* **Auto-uploads** to App Store Connect using the user's own ASC API key.

---

## Core Concepts

### Translation Bundle

Each `SavedDesign` gains an optional **translation bundle**: a map from locale code to a map from overlay ID to translated text.

```
translations: {
  "en": { "overlay_1": "Track Your Habits", "overlay_2": "Stay Consistent" },
  "ja": { "overlay_1": "習慣を追跡する", "overlay_2": "一貫性を保つ" },
  "de": { "overlay_1": "Gewohnheiten verfolgen", "overlay_2": "Bleib konsequent" },
  ...
}
```

- The **source locale** (default: `en`) is the original text the user typed in the editor.
- All styling (font, size, color, position, rotation, etc.) is **shared** — only the `text` string varies per locale.
- A **custom prompt** (app context) can be attached to the bundle to improve translation quality for domain-specific terminology.

### Per-Locale Layout Overrides

Each locale can also store **layout overrides** for individual overlays:

```
overrides: {
  "de": { "overlay_1": { "dx": 10, "dy": 20, "width": 300, "scale": 0.9 } },
  ...
}
```

Only changed properties are stored — the rest inherit from the base design.

### AI Translation Providers

| Provider | Key Required | Platform | Notes |
|---|---|---|---|
| **Apple Foundation Model** | ❌ None | macOS (Apple Intelligence) | On-device, zero cost, zero latency |
| **OpenAI** | User's API key | All | Chat Completions API (configurable model, default `gpt-4o-mini`) |
| **Google Gemini** | User's API key | All | Gemini API (configurable model, default `gemini-2.0-flash`) |
| **DeepL** | User's API key | All | DeepL Translate API |
| **Custom Endpoint** | User's endpoint URL + optional key | All | Any OpenAI-compatible API (Ollama, Together, etc.) |
| **Manual** | ❌ None | All | Copy prompt to external AI, paste response back |

**Apple Foundation Model (default on Mac)**:
- Uses the `FoundationModels` framework (Swift, bridged to Flutter via method channel).
- Runs entirely on-device — **no API key, no cost, no privacy risk**.
- Available on macOS 26+ with Apple Intelligence (M-series chips).
- Ideal first experience: users can translate immediately without any setup.

**BYOK Cloud Providers**:
- For users who want cloud-quality models or are on non-Mac platforms.
- API keys are stored **locally only** — system keychain (macOS/iOS) or encrypted SharedPreferences.
- The app never transmits keys to our servers.
- Users pay their own API costs directly to the provider.

**Manual (Copy-Paste) Flow**:
- For users who don't want to configure API keys but want full control.
- The app generates a structured prompt that the user copies to ChatGPT, Claude, or any AI.
- The user pastes the JSON response back into the app.
- Works on any platform, no API key needed.

### Translation Memory

An in-memory cache that stores previously translated strings keyed by content hash + source/target locale. When re-translating:
- Cached translations are returned instantly without an API call.
- Only new or changed texts hit the provider.
- Reduces cost and latency for incremental edits.

### Font Fallback

When rendering translated text in non-Latin scripts, the app automatically falls back to appropriate Noto Sans variants:

| Script | Fallback Font |
|---|---|
| **Latin** (en, fr, de, es, ...) | User's selected Google Font |
| **CJK** — Chinese | Noto Sans SC (Simplified) / Noto Sans TC (Traditional) |
| **CJK** — Japanese | Noto Sans JP |
| **Korean** | Noto Sans KR |
| **Arabic** (ar, fa, ur) | Noto Sans Arabic |
| **Thai** | Noto Sans Thai |
| **Devanagari** (hi, mr, ne) | Noto Sans Devanagari |

---

## Features

### F1: Translation Provider Setup

Configure one or more AI translation providers.

| Setting | Description |
|---|---|
| **Active Provider** | Which provider to use (Apple FM is default on Mac) |
| **API Key** | Per-provider key entry (not needed for Apple FM / Manual) |
| **Custom Endpoint** | URL for self-hosted / OpenAI-compatible APIs |
| **Custom Model Name** | Model identifier for custom/OpenAI/Gemini endpoints |
| **Custom Prompt** | App context to improve domain-specific translation quality |

Accessed via the **translation controls panel** in the editor sidebar.

### F2: Source Locale Selection

Set the source language for current design texts (defaults to `en`). The source locale text is always the text entered directly in the editor.

### F3: Target Locale Management

Select which locales to generate translations for. Quick presets:

| Preset | Languages |
|---|---|
| **Top 10 Markets** | en, zh, ja, ko, de, fr, es, pt, it, ru |
| **All Supported** | All 40+ App Store locales |
| **Custom** | User picks from a searchable locale list |

Users can also **remove** individual locales, which clears their translations, overrides, and status.

### F4: Translate All Overlays

One-tap translation of **every text overlay** across **all** selected target locales.

- Uses a cache-first strategy — previously translated texts are reused from translation memory.
- Sends only uncached texts to the provider in a single batch prompt per locale.
- Shows a progress indicator per locale (via status dot UI).
- Failure for one locale doesn't block others.
- Individual retries per locale on failure.

### F5: Per-Overlay Translation Editing

After auto-translation, users can **manually edit** any translated string per locale per overlay (corrections, brand-name overrides, etc.).

### F5.1: Manual Copy-Paste Translation

For users who prefer not to configure API keys:
- The app generates a structured translation prompt.
- User copies it to any external AI (ChatGPT, Claude, etc.).
- User pastes the JSON response back via a dialog.
- Translations are applied instantly.

### F6: Live Preview by Locale

A locale switcher in the editor toolbar lets the user **preview the design** with translated text applied — before exporting. The canvas re-renders with the selected locale's text and font fallback applied.

### F6.1: Per-Locale Layout Overrides

When previewing a locale, users can **drag, resize, and rescale** text overlays to fine-tune their position for that specific language — without affecting other locales or the source design.

| Override Property | Description |
|---|---|
| **Position** | Drag the overlay to a new position (per-locale) |
| **Width** | Resize the text container width |
| **Scale** | Adjust the visual scale of the text block |
| **Font Size** | Change the font size for that locale |

**Why it matters**: Translated text is often longer or shorter than the source. German text averages ~30% longer than English; Chinese text tends to be shorter. Per-locale layout overrides let users position each locale's text perfectly without maintaining separate design copies.

**How it works**:
- While previewing a locale, any drag or resize on a text overlay saves an **override** for that locale only.
- Overrides are stored in the `TranslationBundle` alongside translations.
- Switching back to the source locale shows the original layout.
- Only changed properties are stored — the rest inherit from the base design.

### F7: Multi-Locale Batch Export

Export all screenshots for **all selected locales** at once:

```
export/
  en/
    screenshot_1.png
    screenshot_2.png
    ...
  ja/
    screenshot_1.png
    screenshot_2.png
    ...
  de/
    ...
```

The folder structure mirrors what `asc screenshots upload` expects. Returns a `LocaleExportResult` per locale with the count and directory path.

### F8: Auto-Upload to App Store Connect *(Planned)*

After exporting localized screenshots, upload them **directly to App Store Connect** without leaving the app.

- User provides their own **ASC API key** (Issuer ID, Key ID, `.p8` private key).
- The app calls the App Store Connect API to:
  1. Look up the app and its current version.
  2. Match exported locale folders to ASC version localizations.
  3. Upload screenshots per locale per device display type.
- Supports selecting the **target app**, **version**, and **device type** (iPhone 6.7", iPad Pro, etc.).
- Shows progress per locale during upload.
- Handles errors gracefully (invalid key, version not found, screenshot size mismatch).

| Setting | Description |
|---|---|
| **Issuer ID** | From App Store Connect → Users and Access → Integrations → Keys |
| **Key ID** | The API key identifier |
| **Private Key (.p8)** | The downloaded `.p8` file (stored locally, never uploaded to our servers) |
| **Default App** | Optionally pre-select an app for faster uploads |

> [!NOTE]
> ASC API keys are stored locally in the system keychain. Users generate these keys in their own App Store Connect account under Users and Access → Integrations → App Store Connect API.

---

## Data Model

### `TextOverlay` (no changes)

The existing `TextOverlay.text` field remains the **source locale** text. Translations live outside the overlay to keep the model simple.

### `TranslationBundle`

```dart
class TranslationBundle extends Equatable {
  final String sourceLocale;                                    // e.g. "en"
  final List<String> targetLocales;                             // selected targets
  final Map<String, Map<String, String>> translations;          // locale → overlayId → text
  final Map<String, Map<String, OverlayOverride>> overrides;    // locale → overlayId → override
  final String? customPrompt;                                   // app context for prompts
}
```

### `OverlayOverride`

```dart
class OverlayOverride extends Equatable {
  final Offset? position;
  final double? width;
  final double? scale;
  final double? fontSize;
}
```

Only non-null fields are applied. Supports `merge()` to layer overrides.

### `SavedDesign` (extended)

```dart
class SavedDesign {
  // ... existing fields ...
  final TranslationBundle? translationBundle;
}
```

### Serialization

`TranslationBundle` serializes to/from JSON and is included in:
- Local persistence (SavedDesign JSON)
- `.appshots` export/import files
- iCloud backup payloads

---

## User Stories

### US-ML1: Configure Translation Provider
```gherkin
Feature: Configure Translation Provider
  As a user
  I want to choose my AI translation provider
  So that I can translate screenshot texts

  Scenario: Use Apple Foundation Model (default on Mac)
    Given I am on a Mac with Apple Intelligence
    When I open the translation panel
    Then Apple (On-Device) is pre-selected
    And no API key is required

  Scenario: Set OpenAI API key
    Given I am in the translation settings sheet
    When I select "OpenAI" and enter my API key
    Then the key is stored securely in the local keychain
    And "OpenAI" is shown as my active provider

  Scenario: Use manual copy-paste
    Given I don't want to configure API keys
    When I select "Manual" as my provider
    Then I can copy a translation prompt and paste responses
```

### US-ML2: Translate All Overlays
```gherkin
Feature: Translate All Overlays
  As a user
  I want to translate all text overlays to my selected locales
  So that I can create localized screenshots efficiently

  Scenario: Batch translate to 5 locales
    Given I have a design with 3 text overlays
    And I have selected ja, de, fr, ko, es as targets
    When I tap "Translate All"
    Then each locale is translated with a progress indicator
    And already-cached translations are reused instantly
    And I can preview each locale in the editor

  Scenario: Partial failure
    Given translation for "ja" fails due to API error
    When I see the error status for "ja"
    Then I can retry "ja" without re-translating others
```

### US-ML3: Preview Locale in Editor
```gherkin
Feature: Preview Translated Design
  As a user
  I want to preview my design in any translated locale
  So that I can verify the result before exporting

  Scenario: Switch locale preview
    Given I have translated to Japanese
    When I select "ja" from the locale switcher
    Then all text overlays show their Japanese translations
    And font fallback is applied for CJK characters
    And I can switch back to "en" to see the originals

  Scenario: Adjust layout for locale
    Given I am previewing the "de" locale
    When I drag a text overlay to adjust its position
    Then the new position is saved as a per-locale override
    And the source locale layout is unchanged
```

### US-ML4: Edit Individual Translation
```gherkin
Feature: Edit Translation
  As a user
  I want to correct a specific translation
  So that I can fix AI mistakes or override brand names

  Scenario: Edit one overlay's translation
    Given I am previewing the "ja" locale
    When I tap a text overlay and edit its translated text
    Then only that overlay's Japanese translation is updated
    And other locales remain unchanged
```

### US-ML5: Multi-Locale Batch Export
```gherkin
Feature: Multi-Locale Export
  As a user
  I want to export screenshots for all translated locales
  So that I can upload them to App Store Connect

  Scenario: Export all locales
    Given I have a multi-screenshot design translated to 5 locales
    When I tap "Export All Locales"
    Then screenshots are exported to locale-named folders
    And a completion summary shows the count per locale
```

### US-ML6: Auto-Upload to App Store Connect *(Planned)*
```gherkin
Feature: Auto-Upload to ASC
  As a user
  I want to upload exported screenshots directly to App Store Connect
  So that I don't have to manually upload per locale in the browser

  Scenario: Upload after export
    Given I have exported screenshots for 5 locales
    When I tap "Upload to App Store Connect"
    And I select the target app, version, and device type
    Then screenshots are uploaded per locale with a progress indicator
    And a summary shows success/failure per locale
```

---

## Acceptance Criteria

### Provider Setup
- [x] Apple FM is the default provider on supported Macs (no setup needed)
- [x] Apple FM is only shown on macOS devices with Apple Intelligence
- [x] User can select from BYOK providers (OpenAI, Gemini, DeepL, Custom)
- [x] Manual copy-paste flow available (no API key needed)
- [x] API keys are stored in the local keychain / encrypted storage
- [x] Keys are never sent to our servers

### Translation
- [x] All text overlays in a design can be translated with one tap
- [x] Supports batch translation across multiple locales in a single operation
- [x] Translation memory caches and reuses previously translated strings
- [x] Progress is shown per locale during translation
- [x] Individual locale retry on failure
- [x] Custom prompt (app context) improves domain-specific translation quality
- [x] Manual copy-paste flow supported for users without API keys

### Preview & Editing
- [x] Locale switcher in the editor toolbar allows previewing any translated locale
- [x] User can edit individual translated strings
- [x] Per-locale layout overrides (position, width, scale, font size)
- [x] Font fallback to Noto Sans variants for CJK, Arabic, Thai, Devanagari scripts

### Export
- [x] Multi-locale export produces locale-named folders with all screenshots
- [x] Folder structure is compatible with `asc screenshots upload`
- [x] Export returns per-locale result details (count, path)

### Persistence
- [x] Translation bundle persists with the saved design
- [x] Translation bundle is included in `.appshots` exports
- [x] Translation bundle is included in iCloud backups

### ASC Auto-Upload *(Planned)*
- [ ] User can configure ASC API credentials (Issuer ID, Key ID, .p8 file)
- [ ] Credentials are stored in the local keychain only
- [ ] App list is fetched from ASC API after auth
- [ ] User can select target app, version, and device display type
- [ ] Screenshots are uploaded per locale with progress indicator
- [ ] Upload maps locale folder names to ASC version localizations
- [ ] Clear error messages for auth failures, version mismatches, and size errors

---

## Translation Prompt Design

The app sends a **structured prompt** to the AI provider for consistent results:

```
You are a professional App Store copywriter. Translate the following
marketing texts from {sourceLocale} to {targetLocale}.
Return ONLY a JSON object mapping each key to its translation.
Keep translations concise — they will appear as headline text on
App Store screenshots. Preserve any emoji in the text.

{customPrompt (if set, e.g. "This is a fitness tracking app for runners")}

Input:
{
  "overlay_1": "Track Your Habits",
  "overlay_2": "Stay Consistent",
  "overlay_3": "Beautiful Insights"
}
```

This approach:
- Sends all overlays in one API call (cost-efficient).
- Returns structured JSON (easy to parse).
- Gives the model context that these are marketing headlines (improves quality).
- Custom prompt adds domain context for more accurate translations.

---

## Technical Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   Translation UI                         │
│  TranslationControls (sidebar panel)                     │
│  ├─ LocaleTranslationCard (per locale)                   │
│  ├─ TranslationLanguageChip (locale chips)               │
│  ├─ TranslationStatusDot (progress indicator)            │
│  ├─ ManualTranslationDialog (copy-paste flow)            │
│  └─ TranslationSettingsSheet (provider config)           │
│                                                          │
│  LocaleSwitcher (toolbar — locale preview picker)        │
└──────────────────┬───────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────┐
│              TranslationCubit                            │
│  - translateAll(sourceTexts, sourceLocale, targets)       │
│  - retryLocale(locale, sourceTexts)                      │
│  - updateTranslation(locale, overlayId, text)            │
│  - applyManualTranslation(locale, texts)                 │
│  - setPreviewLocale(locale)                              │
│  - updateOverlayOverride(locale, overlayId, override)    │
│  - setCustomPrompt(prompt)                               │
│  - removeLocale(locale)                                  │
└──────────────────┬───────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────┐
│         TranslationService                               │
│  - translate(texts, from, to, context) [cache-first]     │
│  - Resolves active provider from config                  │
│  - Delegates to TranslationMemoryService for caching     │
└──────────────────┬───────────────────────────────────────┘
                   │
    ┌──────────────┼──────────┬──────────┬──────────┐
    ▼              ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│Apple FM│ │ OpenAI │ │ Gemini │ │ DeepL  │ │ Custom │
│(native)│ │Provider│ │Provider│ │Provider│ │Endpoint│
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘
```

### Key Components

| Component | Responsibility |
|---|---|
| `TranslationBundle` | Data model for per-locale overlay texts, overrides, and custom prompt |
| `OverlayOverride` | Per-locale position/width/scale/fontSize adjustments |
| `TranslationCubit` | State management for translation workflow |
| `TranslationState` | Immutable state with bundle, preview locale, per-locale status |
| `TranslationService` | Provider-agnostic translation orchestrator with cache-first strategy |
| `TranslationMemoryService` | In-memory translation cache (hash-based lookup) |
| `TranslationProvider` | Abstract interface with `translate()`, `displayName`, `requiresApiKey` |
| `AppleFMTranslationProvider` | Bridges to Swift `FoundationModels` via MethodChannel |
| `OpenAITranslationProvider` | Calls OpenAI Chat Completions API |
| `GeminiTranslationProvider` | Calls Google Gemini API |
| `DeepLTranslationProvider` | Calls DeepL Translate API |
| `CustomTranslationProvider` | Calls any OpenAI-compatible endpoint |
| `AIProviderRepository` | Persists provider config + API keys (keychain) |
| `TranslationControls` | Sidebar panel with locale cards and translate button |
| `LocaleTranslationCard` | Per-locale translation status and actions |
| `TranslationLanguageChip` | Locale selection chips |
| `TranslationStatusDot` | Visual status indicator per locale |
| `ManualTranslationDialog` | Copy-paste translation flow |
| `TranslationSettingsSheet` | Provider setup UI |
| `LocaleSwitcher` | Toolbar widget for preview locale selection |
| `FontFallback` | Script detection + Noto Sans fallback resolution |
| `MultiLocaleExporter` | Iterates locales, renders, exports PNGs per locale folder |
| `LocaleExportResult` | Result object per locale (count, path) |

---

## Dependencies

| Dependency | Purpose |
|---|---|
| `http` (existing) | HTTP requests to BYOK cloud AI APIs |
| `flutter_secure_storage` | Secure API key storage (keychain / encrypted prefs) |
| **MethodChannel** (custom, macOS only) | Bridge to Swift `FoundationModels` framework |
| `google_fonts` (existing) | Font fallback for CJK/RTL scripts via Noto Sans |

---

## Implementation Status

### ✅ Implemented
- `TranslationBundle` model + persistence (with overrides and custom prompt)
- `TranslationProvider` interface + **Apple Foundation Model** (macOS, zero setup)
- Translate All action with per-locale progress
- Locale preview switcher
- Multi-locale export to folders
- OpenAI, Google Gemini, DeepL, Custom/OpenAI-compatible providers
- Manual copy-paste flow
- Provider settings UI (`TranslationSettingsSheet`)
- Translation Memory (in-memory cache with batch lookup/store)
- Font fallback (`FontFallback` utility with Noto Sans mapping)
- Per-locale layout overrides (`OverlayOverride`)
- Custom prompt support for domain-specific translations

### ⬜ Planned
- App Store Connect auto-upload (ASC API key setup, per-locale screenshot upload)

---

*See [Localization](localization.md) for UI string localization. See [Screenshot Studio](screenshot_studio.md) for the editor architecture.*
