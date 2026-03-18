/// Provider-agnostic translation interface.
///
/// Each translation provider (Apple FM, OpenAI, Gemini, DeepL, Custom)
/// implements this interface.
abstract class TranslationProvider {
  /// Translate a map of (overlayId → sourceText) from [from] to [to].
  ///
  /// Returns a map of (overlayId → translatedText).
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  });

  /// Human-readable provider name for display in the UI.
  String get displayName;

  /// Whether this provider requires an API key to function.
  bool get requiresApiKey;
}
