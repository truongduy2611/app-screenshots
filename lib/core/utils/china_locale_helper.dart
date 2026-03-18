/// Utility for detecting China mainland locale.
///
/// Used to restrict certain AI providers that are not permitted
/// to operate in China (e.g. OpenAI, Gemini).
class ChinaLocaleHelper {
  ChinaLocaleHelper._();

  /// Returns `true` when [locale] represents China mainland.
  ///
  /// Matches Simplified Chinese with country code CN or script Hans.
  static bool isChinaMainland(
    // Using dynamic to avoid importing dart:ui in a pure-dart helper.
    // Callers pass a Flutter `Locale`.
    dynamic locale,
  ) {
    if (locale == null) return false;
    final lang = locale.languageCode as String?;
    final country = locale.countryCode as String?;
    final script = locale.scriptCode as String?;

    if (lang != 'zh') return false;

    // zh_CN is explicitly China mainland.
    if (country == 'CN') return true;

    // zh_Hans without a specific country is treated as China mainland.
    if (script == 'Hans' && (country == null || country.isEmpty)) return true;

    return false;
  }
}
