/// In-memory translation cache to avoid redundant API calls.
///
/// Keyed by a hash of (sourceText + sourceLocale + targetLocale).
/// The cache lives for the duration of the app session.
class TranslationMemoryService {
  final Map<String, String> _cache = {};

  String _key(String text, String from, String to) =>
      '${text.hashCode}_${from}_$to';

  /// Lookup a previously translated text.
  String? lookup(String text, String from, String to) =>
      _cache[_key(text, from, to)];

  /// Store a translation result.
  void store(String text, String from, String to, String translated) {
    _cache[_key(text, from, to)] = translated;
  }

  /// Batch lookup — returns a map of overlayId → translated text
  /// for any texts that are already cached.
  Map<String, String> lookupBatch(
    Map<String, String> texts,
    String from,
    String to,
  ) {
    final results = <String, String>{};
    for (final entry in texts.entries) {
      final cached = lookup(entry.value, from, to);
      if (cached != null) {
        results[entry.key] = cached;
      }
    }
    return results;
  }

  /// Batch store — caches all translations.
  void storeBatch(
    Map<String, String> sourceTexts,
    Map<String, String> translatedTexts,
    String from,
    String to,
  ) {
    for (final entry in translatedTexts.entries) {
      final sourceText = sourceTexts[entry.key];
      if (sourceText != null) {
        store(sourceText, from, to, entry.value);
      }
    }
  }

  /// Number of cached entries.
  int get length => _cache.length;

  /// Clear the cache.
  void clear() => _cache.clear();
}
