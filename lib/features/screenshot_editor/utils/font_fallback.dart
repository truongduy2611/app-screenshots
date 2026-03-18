import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Script categories for font fallback resolution.
enum Script { latin, cjk, arabic, thai, devanagari, korean, other }

/// Detects the dominant script for a locale and returns a font-safe TextStyle.
///
/// If the current font family doesn't support the target locale's script,
/// falls back to the appropriate Noto Sans variant.
class FontFallback {
  FontFallback._();

  /// Resolve a TextStyle with appropriate font fallback for the given locale.
  static TextStyle resolve(TextStyle style, String locale) {
    final script = scriptForLocale(locale);
    if (script == Script.latin) return style; // Most fonts support Latin

    final fallbackFamily = _fallbackMap[script];
    if (fallbackFamily != null) {
      return GoogleFonts.getFont(fallbackFamily).merge(style);
    }
    return style;
  }

  /// Detect the primary script for a locale code.
  static Script scriptForLocale(String locale) {
    final lang = locale.split('-').first.toLowerCase();
    return _localeScriptMap[lang] ?? Script.latin;
  }

  /// Noto Sans fallback families by script.
  static const _fallbackMap = <Script, String>{
    Script.cjk: 'Noto Sans SC',
    Script.korean: 'Noto Sans KR',
    Script.arabic: 'Noto Sans Arabic',
    Script.thai: 'Noto Sans Thai',
    Script.devanagari: 'Noto Sans Devanagari',
  };

  /// Mapping of language codes to scripts.
  static const _localeScriptMap = <String, Script>{
    // CJK
    'zh': Script.cjk,
    'ja': Script.cjk,
    // Korean
    'ko': Script.korean,
    // Arabic
    'ar': Script.arabic,
    'fa': Script.arabic,
    'ur': Script.arabic,
    // Thai
    'th': Script.thai,
    // Devanagari
    'hi': Script.devanagari,
    'mr': Script.devanagari,
    'ne': Script.devanagari,
    // Everything else defaults to Latin
  };

  /// Get the appropriate Noto Sans variant for a CJK locale.
  /// More specific than the generic CJK fallback.
  static String cjkFontForLocale(String locale) {
    final lang = locale.split('-').first.toLowerCase();
    return switch (lang) {
      'ja' => 'Noto Sans JP',
      'ko' => 'Noto Sans KR',
      'zh' =>
        locale.toLowerCase().contains('hant') ? 'Noto Sans TC' : 'Noto Sans SC',
      _ => 'Noto Sans SC',
    };
  }
}
