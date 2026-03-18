# AI-Generated Templates — Developer Guide

## Architecture

```
┌──────────────────────┐     ┌───────────────────────┐
│  PresetPickerDialog  │     │   AiTemplateDialog     │
│  (_AiGenerateCard)   │────>│  (text input + chips)  │
└──────────────────────┘     └───────────┬─────────────┘
                                         │
                              ┌──────────▼──────────┐
                              │  AiTemplateService   │
                              │  generate(desc)      │
                              └──┬────────────────┬──┘
                                 │                │
                    ┌────────────▼───┐    ┌───────▼──────────┐
                    │   Apple FM     │    │   Gemini API     │
                    │ (MethodChannel)│    │  (HTTP + JSON)   │
                    └────────────────┘    └──────────────────┘
                                 │                │
                              ┌──▼────────────────▼──┐
                              │ JSON → ScreenshotPreset │
                              │ → applyPreset()         │
                              └─────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/.../data/services/ai_template_service.dart` | Core service — prompt, HTTP calls, JSON parsing |
| `lib/.../presentation/widgets/ai_template_dialog.dart` | Input dialog UI |
| `lib/.../presentation/widgets/preset_picker_dialog.dart` | `_AiGenerateCard` widget |
| `macos/Runner/AIChannel.swift` | Apple FM `generateTemplate` method |

## AiTemplateService

### Provider Selection Logic

```dart
Future<ScreenshotPreset> generate(String description) async {
  final config = await _providerRepo.getConfig();

  // 1. Try Apple FM if active and available
  if (config.activeProvider == AIProviderType.appleFM) {
    if (await AppleFMTranslationProvider.isAvailable()) {
      return _generateWithAppleFM(description);
    }
  }

  // 2. Fall back to Gemini (requires API key)
  return _generateWithGemini(description, config.apiKey!);
}
```

### Prompt Structure

The prompt instructs the AI to return a JSON object matching this schema:

```json
{
  "name": "Preset Name",
  "description": "Short description",
  "titleFont": "Google Font name",
  "thumbnailColors": ["#HEX1", "#HEX2"],
  "textAtBottom": false,
  "titleAlign": "left|center|right",
  "designs": [
    {
      "backgroundColor": "#HEX",
      "gradientColors": ["#HEX1", "#HEX2"],
      "gradientBegin": "topLeft",
      "gradientEnd": "bottomRight",
      "title": "Feature\\nHeadline",
      "subtitle": "Supporting text",
      "titleSize": 100,
      "titleWeight": 700,
      "titleFontStyle": "normal|italic",
      "titleColor": "#FFFFFF",
      "subtitleSize": 46,
      "subtitleColor": "#FFFFFFB3"
    }
  ]
}
```

### JSON Parsing

`_parsePreset()` converts the AI JSON into a `ScreenshotPreset` with:
- 5 `ScreenshotDesign` instances (cycles if AI returns fewer)
- `TextOverlay` objects for title and subtitle
- Gradient support via `LinearGradient` with configurable alignment
- Font weight mapping (100–900)
- Hex color parsing (6 or 8 digit)

## Swift Bridge (Apple FM)

The `AIChannel.swift` handles three methods:

| Method | Arguments | Returns |
|--------|-----------|---------|
| `isAvailable` | none | `Bool` |
| `translate` | `texts`, `from`, `to` | JSON string |
| `generateTemplate` | `description` | JSON string |

`generateTemplate` uses `LanguageModelSession` (same as `translate`) with a template-specific prompt. Requires `macOS 26+` and `FoundationModels` framework.

## Localization Keys

| Key | Value |
|-----|-------|
| `aiGenerate` | ✨ AI Generate |
| `aiGenerateSubtitle` | Describe your style and let AI create a template |
| `aiTemplatePromptHint` | e.g., Dark elegant style for a fitness app |
| `aiTemplateGenerating` | Generating… |
| `aiTemplateError` | Failed to generate template |
| `aiTemplateNoApiKey` | Set up a Gemini API key in Settings… |
| `generate` | Generate |

## Extending

### Adding new AI providers
1. Add the HTTP/channel call in `AiTemplateService`
2. Use the same prompt format — it's provider-agnostic
3. Parse the same JSON schema via `_parsePreset()`

### Adding new design properties
1. Extend the JSON schema in `_buildPrompt()`
2. Update `_parsePreset()` to read new fields
3. Map to existing `ScreenshotDesign` properties

### Persisting AI templates
Currently templates are generated and applied immediately. To add persistence:
1. Serialize the `ScreenshotPreset` to JSON via the existing `toJson()` methods
2. Store in `SharedPreferences` or a local database
3. Load in `PresetPickerDialog` alongside `ScreenshotPresets.all`
