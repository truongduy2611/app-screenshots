# 🌐 Multi-Language Screenshots — Developer Guide

> **Business doc:** [multi_language_screenshots.md](../biz/multi_language_screenshots.md)
> **Architecture ref:** [architecture.md](architecture.md)
> **Screenshot Studio ref:** [screenshot_studio.md](screenshot_studio.md)

---

## Overview

This feature adds a **translation layer** to the Screenshot Studio, enabling users to translate text overlays, preview localized designs, export per-locale screenshot sets, and (planned) auto-upload to App Store Connect.

**Status:** Core translation pipeline, BYOK cloud providers (OpenAI, Gemini, DeepL, Custom), manual flow, translation memory, font fallback, and per-locale layout overrides are all implemented. App Store Connect auto-upload is planned.

---

## Feature Location

```
lib/features/screenshot_editor/
├── data/
│   ├── models/
│   │   ├── overlay_override.dart           # Per-locale layout adjustments
│   │   ├── translation_bundle.dart         # Core translation data model
│   │   └── ai_provider_config.dart # Provider config + enum
│   ├── services/
│   │   ├── apple_fm_provider.dart          # Apple Foundation Model (MethodChannel bridge)
│   │   ├── openai_provider.dart            # OpenAI Chat Completions
│   │   ├── gemini_provider.dart            # Google Gemini API
│   │   ├── deepl_provider.dart             # DeepL Translate API
│   │   ├── custom_provider.dart            # OpenAI-compatible custom endpoint
│   │   ├── translation_provider.dart       # Abstract TranslationProvider interface
│   │   ├── translation_service.dart        # Provider orchestrator + cache integration
│   │   ├── translation_memory_service.dart # In-memory translation cache
│   │   └── multi_locale_exporter.dart      # Multi-locale PNG export
│   └── repositories/
│       └── ai_provider_repository_impl.dart  # Provider config persistence
├── domain/
│   └── repositories/
│       └── ai_provider_repository.dart       # Abstract repository
├── presentation/
│   ├── cubit/
│   │   ├── translation_cubit.dart          # Translation state management
│   │   └── translation_state.dart          # Immutable translation state
│   └── widgets/
│       ├── locale_switcher.dart            # Toolbar locale preview picker
│       ├── translation_settings_sheet.dart # Provider setup bottom sheet
│       ├── manual_translation_dialog.dart  # Copy-paste translation dialog
│       └── controls/
│           ├── translation_controls.dart      # Sidebar translation panel
│           ├── locale_translation_card.dart    # Per-locale status card
│           ├── translation_language_chip.dart  # Locale chip widget
│           └── translation_status_dot.dart     # Status indicator dot
├── utils/
│   └── font_fallback.dart                  # Script detection + Noto Sans fallback
```

> [!NOTE]
> All files live **inside the existing `screenshot_editor` feature**. No new top-level feature directory is needed.

---

## Data Models

### `TranslationBundle`

```dart
// lib/features/screenshot_editor/data/models/translation_bundle.dart

class TranslationBundle extends Equatable {
  final String sourceLocale;                                    // e.g. "en"
  final List<String> targetLocales;                             // selected targets
  final Map<String, Map<String, String>> translations;          // locale → overlayId → text
  final Map<String, Map<String, OverlayOverride>> overrides;    // locale → overlayId → override
  final String? customPrompt;                                   // app context for translation prompt

  // Key methods:
  String? getTranslation(String locale, String overlayId);
  TranslationBundle setTranslation(String locale, String overlayId, String text);
  TranslationBundle setLocaleTranslations(String locale, Map<String, String> texts);
  OverlayOverride? getOverride(String locale, String overlayId);
  TranslationBundle setOverride(String locale, String overlayId, OverlayOverride override);
  TranslationBundle removeLocale(String locale);

  Map<String, dynamic> toJson();
  factory TranslationBundle.fromJson(Map<String, dynamic> json);
}
```

### `OverlayOverride`

```dart
// lib/features/screenshot_editor/data/models/overlay_override.dart

class OverlayOverride extends Equatable {
  final Offset? position;   // override canvas position
  final double? width;       // override text container width
  final double? scale;       // override scale factor
  final double? fontSize;    // override font size

  // Only non-null fields are applied on top of the base TextOverlay.
  OverlayOverride copyWith({..., bool clearPosition, bool clearWidth, ...});
  OverlayOverride merge(OverlayOverride other); // Non-null values in [other] win.
  Map<String, dynamic> toJson();
  factory OverlayOverride.fromJson(Map<String, dynamic> json);
}
```

### `AIProviderConfig`

```dart
// lib/features/screenshot_editor/data/models/ai_provider_config.dart

enum AIProviderType { appleFM, openai, gemini, deepl, custom, manual }

class AIProviderConfig extends Equatable {
  final AIProviderType activeProvider;  // default: appleFM
  final String? apiKey;
  final String? customEndpoint;
  final String? customModel;                     // e.g. "gpt-4o-mini", "gemini-2.0-flash"

  Map<String, dynamic> toJson();
  factory AIProviderConfig.fromJson(Map<String, dynamic> json);
}
```

### `SavedDesign` (extended)

```dart
// In saved_design.dart — existing model extended with:
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

## Translation Provider Interface

```dart
// lib/features/screenshot_editor/data/services/translation_provider.dart

abstract class TranslationProvider {
  /// Translate (overlayId → sourceText) from [from] to [to].
  /// [context] is an optional app description for better translations.
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  });

  String get displayName;
  bool get requiresApiKey;
}
```

---

## Translation Service (Cache-First Strategy)

```dart
// lib/features/screenshot_editor/data/services/translation_service.dart

class TranslationService {
  final AIProviderRepository _providerRepo;
  final TranslationMemoryService _memory;

  TranslationService(this._providerRepo, this._memory);

  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    // 1. Check cache for already-translated texts
    final cached = _memory.lookupBatch(texts, from, to);
    final uncached = Map<String, String>.from(texts)
      ..removeWhere((key, _) => cached.containsKey(key));

    if (uncached.isEmpty) return cached;

    // 2. Translate only uncached texts via active provider
    final provider = await getActiveProvider();
    final fresh = await provider.translate(texts: uncached, from: from, to: to, context: context);

    // 3. Store fresh results in cache
    _memory.storeBatch(uncached, fresh, from, to);

    // 4. Merge and return
    return {...cached, ...fresh};
  }

  Future<TranslationProvider> getActiveProvider() async {
    final config = await _providerRepo.getConfig();
    return _createProvider(config);
  }

  TranslationProvider _createProvider(AIProviderConfig config) {
    switch (config.activeProvider) {
      case AIProviderType.appleFM:
        return AppleFMTranslationProvider();
      case AIProviderType.openai:
        return OpenAITranslationProvider(
          apiKey: config.apiKey!, model: config.customModel ?? 'gpt-4o-mini');
      case AIProviderType.gemini:
        return GeminiTranslationProvider(
          apiKey: config.apiKey!, model: config.customModel ?? 'gemini-2.0-flash');
      case AIProviderType.deepl:
        return DeepLTranslationProvider(apiKey: config.apiKey!);
      case AIProviderType.custom:
        return CustomTranslationProvider(
          endpoint: config.customEndpoint!, apiKey: config.apiKey, model: config.customModel);
      case AIProviderType.manual:
        throw UnsupportedError('Manual provider does not use the service pipeline.');
    }
  }
}
```

---

## Translation Memory

```dart
// lib/features/screenshot_editor/data/services/translation_memory_service.dart

class TranslationMemoryService {
  final Map<String, String> _cache = {};

  String _key(String text, String from, String to) => '${text.hashCode}_${from}_$to';

  String? lookup(String text, String from, String to);
  void store(String text, String from, String to, String translated);

  // Batch operations for efficient multi-overlay translation:
  Map<String, String> lookupBatch(Map<String, String> texts, String from, String to);
  void storeBatch(Map<String, String> sourceTexts, Map<String, String> translatedTexts, String from, String to);

  int get length;
  void clear();
}
```

The cache lives for the app session. It's keyed by `hash(text)_from_to` and integrated directly into `TranslationService.translate()`.

---

## Apple Foundation Model Provider

### Swift Side (macOS only)

```swift
// macos/Runner/AIChannel.swift

import Foundation
import FoundationModels  // macOS 26+

// MethodChannel: "com.appscreenshots/translation"
// Methods:
//   "isAvailable" → Bool (checks Apple Intelligence availability)
//   "translate" → String (JSON) (translates texts via on-device LLM)
```

### Dart Side

```dart
// lib/features/screenshot_editor/data/services/apple_fm_provider.dart

class AppleFMTranslationProvider implements TranslationProvider {
  static const _channel = MethodChannel('com.appscreenshots/translation');

  static Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) { return false; }
  }

  @override String get displayName => 'Apple (On-Device)';
  @override bool get requiresApiKey => false;

  @override
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    final textsJson = jsonEncode(texts);
    final resultJson = await _channel.invokeMethod<String>('translate', {
      'texts': textsJson, 'from': from, 'to': to,
    });
    // Handles markdown code fence stripping from model response
    // Returns parsed JSON map
  }
}
```

---

## Cloud Providers

### OpenAI

```dart
// lib/features/screenshot_editor/data/services/openai_provider.dart

class OpenAITranslationProvider implements TranslationProvider {
  final String apiKey;
  final String model;  // default: 'gpt-4o-mini'

  // POST https://api.openai.com/v1/chat/completions
  // response_format: { type: 'json_object' }
  // Structured system prompt for App Store copywriting
}
```

### Google Gemini

```dart
// lib/features/screenshot_editor/data/services/gemini_provider.dart

class GeminiTranslationProvider implements TranslationProvider {
  final String apiKey;
  final String model;  // default: 'gemini-2.0-flash'

  // POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
  // responseMimeType: 'application/json'
}
```

### DeepL

```dart
// lib/features/screenshot_editor/data/services/deepl_provider.dart

class DeepLTranslationProvider implements TranslationProvider {
  final String apiKey;

  // POST https://api-free.deepl.com/v2/translate
  // Per-text requests (DeepL API sends one at a time)
  // Maps App Store locale codes to DeepL target language codes
}
```

### Custom Endpoint

```dart
// lib/features/screenshot_editor/data/services/custom_provider.dart

class CustomTranslationProvider implements TranslationProvider {
  final String endpoint;
  final String? apiKey;
  final String? model;

  // POST {endpoint}/v1/chat/completions
  // OpenAI-compatible format (works with Ollama, Together, etc.)
}
```

---

## TranslationCubit

```dart
// lib/features/screenshot_editor/presentation/cubit/translation_cubit.dart

class TranslationCubit extends Cubit<TranslationState> {
  final TranslationService _translationService;

  // Core lifecycle:
  void loadBundle(TranslationBundle? bundle);

  // AI translation:
  Future<void> translateAll({
    required Map<String, String> sourceTexts,
    required String sourceLocale,
    required List<String> targetLocales,
  });
  Future<void> retryLocale(String locale, Map<String, String> sourceTexts);

  // Manual editing:
  void updateTranslation(String locale, String overlayId, String text);
  void applyManualTranslation(String locale, Map<String, String> texts);

  // Locale management:
  void removeLocale(String locale);  // drops translations, overrides, and status

  // Preview:
  void setPreviewLocale(String? locale);

  // Layout overrides:
  void updateOverlayOverride(String locale, String overlayId, OverlayOverride override);

  // Custom prompt:
  void setCustomPrompt(String? prompt);
}
```

### TranslationState

```dart
part of 'translation_cubit.dart';

enum TranslationStatus { idle, translating, done, error }

class TranslationState extends Equatable {
  final TranslationBundle? bundle;
  final String? previewLocale;
  final Map<String, TranslationStatus> localeStatuses;
  final String? errorMessage;

  // Computed:
  bool get isTranslating;
  int get completedCount;

  // copyWith with clearBundle, clearPreviewLocale, clearError flags
}
```

---

## Font Fallback

```dart
// lib/features/screenshot_editor/utils/font_fallback.dart

enum Script { latin, cjk, arabic, thai, devanagari, korean, other }

class FontFallback {
  /// Resolve a TextStyle with font fallback for the given locale.
  static TextStyle resolve(TextStyle style, String locale);

  /// Detect script from locale code.
  static Script scriptForLocale(String locale);

  /// Get locale-specific CJK font (JP/KR/SC/TC).
  static String cjkFontForLocale(String locale);
}
```

| Locale | Script | Fallback |
|---|---|---|
| `zh` | CJK | Noto Sans SC / TC |
| `ja` | CJK | Noto Sans JP |
| `ko` | Korean | Noto Sans KR |
| `ar`, `fa`, `ur` | Arabic | Noto Sans Arabic |
| `th` | Thai | Noto Sans Thai |
| `hi`, `mr`, `ne` | Devanagari | Noto Sans Devanagari |
| everything else | Latin | User's font (no fallback) |

---

## Multi-Locale Export

```dart
// lib/features/screenshot_editor/data/services/multi_locale_exporter.dart

class LocaleExportResult {
  final String locale;
  final int screenshotCount;
  final String directoryPath;
}

class MultiLocaleExporter {
  Future<List<LocaleExportResult>> exportAll({
    required List<SavedDesign> designs,
    required TranslationBundle bundle,
    required String exportBasePath,
    required Future<List<int>> Function(SavedDesign, String? locale) renderDesign,
  });
}
```

Output structure:
```
exportBasePath/
├── en/              ← source locale (rendered with null locale → original text)
│   ├── screenshot_1.png
│   └── screenshot_2.png
├── ja/              ← target locale (rendered with locale → translated text)
│   ├── screenshot_1.png
│   └── screenshot_2.png
└── de/
    ├── screenshot_1.png
    └── screenshot_2.png
```

---

## Canvas Integration

### Editor Canvas Refactored Structure

The editor canvas has been decomposed into focused widget files:

```
presentation/widgets/
├── editor_canvas.dart                    # Main canvas (build delegates to helpers)
└── canvas/
    ├── canvas_painters.dart              # CheckerboardPainter, SnapGuidePainter, OverlaySelectionBorder
    ├── grab_cursor_region.dart           # Grab/grabbing cursor widget
    ├── import_hint_placeholder.dart      # Import image placeholder
    ├── image_overlay_widget.dart         # Image overlay (drag/rotate/resize)
    ├── icon_overlay_widget.dart          # Icon overlay (drag/snap)
    └── text_overlay_widget.dart          # Text overlay (drag/snap/translation)
```

### Text Overlay Translation

`TextOverlayWidget` handles locale preview by:
1. Receiving `previewLocale` and `localeOverride` from the parent `EditorCanvas`.
2. Using translated text (from bundle) when a preview locale is active.
3. Applying `OverlayOverride` position/width/scale/fontSize over the base overlay.
4. Resolving font fallback via `FontFallback.resolve()`.
5. Saving drag deltas as locale-specific overrides via `TranslationCubit.updateOverlayOverride()`.

### Drag Interception

When `previewLocale != null`, text overlay drags call `translationCubit.updateOverlayOverride()` instead of `cubit.updateTextOverlay()`, storing the new position as a locale-specific override without modifying the base design.

---

## UI Widgets

| Widget | Location | Responsibility |
|---|---|---|
| `TranslationControls` | `controls/translation_controls.dart` | Sidebar panel: source/target locale selection, translate button, locale cards |
| `LocaleTranslationCard` | `controls/locale_translation_card.dart` | Per-locale card showing status, retry, remove actions |
| `TranslationLanguageChip` | `controls/translation_language_chip.dart` | Compact locale chip for selection UI |
| `TranslationStatusDot` | `controls/translation_status_dot.dart` | Color-coded status dot (idle, translating, done, error) |
| `TranslationSettingsSheet` | `translation_settings_sheet.dart` | Bottom sheet for provider config (type, API key, model, endpoint) |
| `ManualTranslationDialog` | `manual_translation_dialog.dart` | Dialog for copy-paste translation flow |
| `LocaleSwitcher` | `locale_switcher.dart` | Toolbar dropdown for switching preview locale |

---

## DI Registration

```dart
// In service_locator.dart

// Services
sl.registerLazySingleton<TranslationMemoryService>(() => TranslationMemoryService());
sl.registerLazySingleton<TranslationService>(() => TranslationService(sl(), sl()));

// Repositories
sl.registerLazySingleton<AIProviderRepository>(
  () => AIProviderRepositoryImpl(sl<FlutterSecureStorage>()),
);

// Cubits
sl.registerFactory(() => TranslationCubit(sl()));
```

---

## Persistence

`TranslationBundle` serializes to JSON and is stored:

1. **With the design** — In the `SavedDesign` JSON under `screenshot_designs/{id}/design.json`
2. **In `.appshots` exports** — Included when sharing designs
3. **In iCloud backups** — Travels with the existing design backup payload

---

## App Store Connect Auto-Upload *(Planned)*

### Planned Components

```
lib/features/screenshot_editor/
├── data/
│   ├── services/
│   │   └── asc_upload_service.dart          # [NEW] ASC upload orchestration
│   └── repositories/
│       └── asc_credential_repository_impl.dart  # [NEW] Keychain credential storage
├── domain/
│   └── repositories/
│       └── asc_credential_repository.dart   # [NEW] Abstract repository
├── presentation/
│   ├── cubit/
│   │   ├── asc_upload_cubit.dart            # [NEW] Upload state management
│   │   └── asc_upload_state.dart            # [NEW] Upload state
│   └── widgets/
│       └── asc_upload_sheet.dart            # [NEW] Upload UI
```

---

## Dependencies

```yaml
# pubspec.yaml

dependencies:
  flutter_secure_storage: ^9.0.0   # Secure key storage
```

---

## Testing Strategy

### Unit Tests

```
test/features/screenshot_editor/
├── data/
│   ├── models/
│   │   ├── translation_bundle_test.dart
│   │   └── overlay_override_test.dart
│   ├── services/
│   │   ├── translation_service_test.dart
│   │   ├── translation_memory_service_test.dart
│   │   ├── openai_provider_test.dart
│   │   ├── gemini_provider_test.dart
│   │   └── deepl_provider_test.dart
│   └── repositories/
│       └── ai_provider_repository_impl_test.dart
└── presentation/
    └── cubit/
        └── translation_cubit_test.dart
```

### Key Test Cases

| Component | Key Test Cases |
|---|---|
| `TranslationBundle` | JSON round-trip, `getTranslation`, `setTranslation`, `setLocaleTranslations`, `removeLocale`, overrides CRUD, `customPrompt` persistence |
| `OverlayOverride` | JSON round-trip, `merge`, `copyWith` with clear flags |
| `TranslationCubit` | `translateAll` emits correct status per locale, partial failure, retry, manual edit, `removeLocale`, `setCustomPrompt`, `applyManualTranslation` |
| `TranslationService` | Cache-first strategy (cached returns instantly, uncached hits provider), batch store after translation |
| `TranslationMemoryService` | `lookup`/`store`, `lookupBatch`/`storeBatch`, `clear` |
| `FontFallback` | `scriptForLocale` mapping, `resolve` returns Noto Sans for CJK/Arabic/Thai, `cjkFontForLocale` specificity |
| `MultiLocaleExporter` | Creates correct directory structure, exports source + target locales, passes correct locale to render callback |

### Mock Pattern

```dart
class MockTranslationService extends Mock implements TranslationService {}
class MockTranslationProvider extends Mock implements TranslationProvider {}
class MockAIProviderRepository extends Mock implements AIProviderRepository {}

blocTest<TranslationCubit, TranslationState>(
  'translateAll translates all target locales with progress',
  build: () {
    when(() => mockService.getActiveProvider())
        .thenAnswer((_) async => mockProvider);
    when(() => mockProvider.translate(
      texts: any(named: 'texts'), from: any(named: 'from'),
      to: any(named: 'to'), context: any(named: 'context'),
    )).thenAnswer((_) async => {'overlay_1': 'Translated'});
    return TranslationCubit(mockService);
  },
  act: (cubit) => cubit.translateAll(
    sourceTexts: {'overlay_1': 'Original'},
    sourceLocale: 'en',
    targetLocales: ['ja', 'de'],
  ),
  expect: () => [
    // ja translating → ja done, bundle updated
    // de translating → de done, bundle updated
  ],
);
```

---

## Summary Checklist

### ✅ Implemented
- [x] `TranslationBundle` model + JSON serialization (with overrides + customPrompt)
- [x] `OverlayOverride` model + JSON serialization
- [x] `SavedDesign` extended with `translationBundle` field
- [x] `TranslationProvider` interface (with `context` parameter)
- [x] `AppleFMTranslationProvider` (Swift bridge + Dart MethodChannel)
- [x] `TranslationCubit` with `translateAll`, `retryLocale`, `updateTranslation`, `setPreviewLocale`
- [x] `LocaleSwitcher` widget in editor toolbar
- [x] `MultiLocaleExporter` service with `LocaleExportResult`
- [x] DI registration
- [x] `AIProviderConfig` model (with `manual` type)
- [x] `AIProviderRepository` + implementation
- [x] `OpenAITranslationProvider` (configurable model)
- [x] `GeminiTranslationProvider` (configurable model)
- [x] `DeepLTranslationProvider`
- [x] `CustomTranslationProvider`
- [x] Manual copy-paste flow (`ManualTranslationDialog`)
- [x] Provider settings UI (`TranslationSettingsSheet`)
- [x] `TranslationMemoryService` (in-memory cache with batch ops)
- [x] Translation memory integrated into `TranslationService` (cache-first strategy)
- [x] `FontFallback` utility (script detection + Noto Sans mapping)
- [x] Per-locale layout overrides (`OverlayOverride` in `TranslationBundle`)
- [x] `TranslationCubit.updateOverlayOverride()` for locale-specific drag
- [x] `TranslationCubit.setCustomPrompt()` for app context
- [x] `TranslationCubit.removeLocale()` for locale cleanup
- [x] `TranslationCubit.applyManualTranslation()` for manual flow
- [x] UI widgets: `TranslationControls`, `LocaleTranslationCard`, `TranslationLanguageChip`, `TranslationStatusDot`
- [x] Canvas refactored: `TextOverlayWidget` handles locale preview + overrides + font fallback

### ⬜ Planned
- [ ] `ASCCredentialRepository` + implementation
- [ ] `ASCUploadService` (reuse `packages/appstore_connect`)
- [ ] `ASCUploadCubit`
- [ ] Upload UI (app/version/device picker + progress)
- [ ] Unit tests for upload cubit and service
