import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/apple_fm_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/custom_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/deepl_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/gemini_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/openai_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_memory_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';

/// Orchestrates translation calls by resolving the active provider,
/// checking the translation memory cache, and delegating to the provider.
class TranslationService {
  final AIProviderRepository _providerRepo;
  final TranslationMemoryService _memory;

  TranslationService(this._providerRepo, this._memory);

  /// Translate texts with cache-first strategy.
  ///
  /// Returns full map of overlayId → translated text, mixing cached
  /// and freshly translated results.
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

    // 2. Translate only uncached texts
    final provider = await getActiveProvider();
    final fresh = await provider.translate(
      texts: uncached,
      from: from,
      to: to,
      context: context,
    );

    // 3. Store fresh results in cache
    _memory.storeBatch(uncached, fresh, from, to);

    // 4. Merge and return
    return {...cached, ...fresh};
  }

  /// Get the currently active provider instance.
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
          apiKey: config.apiKey!,
          model: config.customModel ?? 'gpt-4o-mini',
        );
      case AIProviderType.gemini:
        return GeminiTranslationProvider(
          apiKey: config.apiKey!,
          model: config.customModel ?? 'gemini-2.0-flash',
        );
      case AIProviderType.deepl:
        return DeepLTranslationProvider(apiKey: config.apiKey!);
      case AIProviderType.custom:
        return CustomTranslationProvider(
          endpoint: config.customEndpoint!,
          apiKey: config.apiKey,
          model: config.customModel,
        );
      case AIProviderType.manual:
        throw UnsupportedError(
          'Manual provider does not use the translation service pipeline.',
        );
    }
  }
}
