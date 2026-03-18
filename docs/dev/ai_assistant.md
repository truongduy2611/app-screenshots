# AI Design Assistant — Developer Guide

## Architecture

```
┌──────────────────────────┐
│  AiAssistantControls     │  (Sidebar tab widget)
│  ├─ Message list         │
│  ├─ Suggestion chips     │
│  └─ Prompt input bar     │
└───────────┬──────────────┘
            │
┌───────────▼──────────────┐
│  AiAssistantCubit        │  (State management)
│  ├─ messages[]           │
│  ├─ isProcessing         │
│  └─ pendingDesign?       │
└───────────┬──────────────┘
            │
┌───────────▼──────────────┐
│  AiDesignService         │  (Prompt → design diff)
│  ├─ buildSystemPrompt()  │
│  ├─ Apple FM / Gemini    │
│  └─ parseDesignDiff()    │
└───────────┬──────────────┘
            │
┌───────────▼──────────────┐
│  ScreenshotEditorCubit   │  (Apply design changes)
│  └─ replaceDesign()      │
└──────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `data/services/ai_design_service.dart` | AI prompt → design diff → merged `ScreenshotDesign` |
| `presentation/cubit/ai_assistant_cubit.dart` | Message history, loading state, undo stack |
| `presentation/cubit/ai_assistant_state.dart` | Immutable state: messages, status, pending design |
| `presentation/widgets/controls/ai_assistant_controls.dart` | Sidebar tab UI |
| `controls/desktop_editor_controls.dart` | Add 6th tab entry |

## AiDesignService

### Prompt Strategy

The service sends:
1. **System prompt**: describes the `ScreenshotDesign` JSON schema and available properties
2. **Current design**: `ScreenshotDesign.toJson()` serialized as context
3. **User message**: the natural language request

The AI returns a **partial JSON** of only changed properties, which is merged into the current design.

### Provider Routing

Uses the same `AIProviderRepository` config as translation/template:
- **Apple FM**: `AIChannel.swift` via MethodChannel (`designAssist` method)
- **Gemini**: HTTP POST to `generativelanguage.googleapis.com`
- **OpenAI**: HTTP POST to `api.openai.com`

### JSON Diff Response Schema

```json
{
  "changes": {
    "backgroundColor": "#1A1A2E",
    "gradientColors": ["#16213E", "#0F3460"],
    "gradientBegin": "topLeft",
    "gradientEnd": "bottomRight"
  },
  "textChanges": [
    {
      "index": 0,
      "text": "Track Your Goals",
      "fontSize": 110,
      "fontWeight": 700,
      "color": "#FFFFFF"
    }
  ],
  "explanation": "Applied a deep navy gradient with white bold text"
}
```

### Design Merging

```dart
ScreenshotDesign applyDiff(ScreenshotDesign current, Map<String, dynamic> diff) {
  // 1. Parse background changes
  // 2. Parse text overlay changes (by index)
  // 3. Return current.copyWith(...)
}
```

## AiAssistantCubit

### State

```dart
class AiAssistantState {
  final List<AiMessage> messages;     // Chat history
  final AiAssistantStatus status;     // idle | processing | error
  final String? errorMessage;
  final ScreenshotDesign? designBeforeAi;  // For undo
}
```

### Message Model

```dart
class AiMessage {
  final String id;
  final AiMessageRole role;  // user | assistant
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? designDiff;  // The changes applied
}
```

### Flow

1. `sendMessage(prompt)` → set status=processing, save current design for undo
2. Call `AiDesignService.processRequest(currentDesign, prompt)`
3. Get back `AiDesignResponse` with diff + explanation
4. Apply diff to design via `ScreenshotEditorCubit`
5. Add assistant message with explanation
6. Set status=idle

### Undo

`designBeforeAi` stores the design snapshot before the last AI change. The user can tap "Undo" to revert.

## Sidebar Integration

### desktop_editor_controls.dart

Add a 6th entry:

```dart
const _tabContents = <Widget>[
  BackgroundControls(),
  FrameControls(),
  TextControls(),
  DoodleControls(),
  AiAssistantControls(),   // NEW
  TranslationControls(),
];

const _tabIcons = <IconData>[
  Symbols.format_paint_rounded,
  Symbols.phone_iphone_rounded,
  Symbols.text_fields_rounded,
  Symbols.gesture_rounded,        // Changed from auto_awesome
  Symbols.auto_awesome_rounded,   // AI tab gets this icon
  Symbols.translate_rounded,
];
```

## Swift Bridge Extension

Add a new method `designAssist` to `AIChannel.swift`:

```swift
case "designAssist":
  guard let args = call.arguments as? [String: Any],
    let currentDesignJson = args["currentDesign"] as? String,
    let userPrompt = args["prompt"] as? String
  else { ... }
  // Build prompt with design context + user request
  // Return JSON diff
```

## Localization Keys

| Key | Value |
|-----|-------|
| `aiAssistant` | AI Assistant |
| `aiAssistantHint` | Describe what you'd like to change... |
| `aiAssistantSuggestions` | Suggestions |
| `aiAssistantUndo` | Undo AI change |
| `aiAssistantError` | Couldn't apply that change |
