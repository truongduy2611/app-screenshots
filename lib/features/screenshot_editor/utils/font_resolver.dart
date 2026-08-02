import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Resolves a Google Fonts family once per (family, weight, style) variant
/// and caches the resulting `fontFamily`/`fontFamilyFallback`.
///
/// `GoogleFonts.getFont` re-runs descriptor matching (and registers the
/// variant loader) on every call; canvas hot paths call it per text overlay
/// per build, which adds up across the multi-canvas previews. The first call
/// per variant still goes through `getFont` so the font file loads exactly
/// as before.
class FontResolver {
  FontResolver._();

  static final Map<
    String,
    ({String? fontFamily, List<String>? fontFamilyFallback})
  >
  _cache = {};

  /// Alias mapping for Google Sans, native iOS fonts (SF Pro, SF Rounded, etc.), and related variants.
  static const Map<String, String> _fontAliases = {
    // Google Sans variants
    'Google Sans Rounded': 'Google Sans',
    'GoogleSansRounded': 'Google Sans',
    'Google Sans Round': 'Google Sans',
    'google_sans_rounded': 'Google Sans',
    'googleSansRounded': 'Google Sans',
    'GoogleSans': 'Google Sans',
    'Google Sans Text': 'Google Sans',
    'GoogleSansText': 'Google Sans',

    // Native iOS / Apple fonts
    'SF': 'SF Pro',
    'SF Pro': 'SF Pro',
    'San Francisco': 'SF Pro',
    'SF Round': 'SF Pro Rounded',
    'SF Rounded': 'SF Pro Rounded',
    'SF Pro Rounded': 'SF Pro Rounded',
    'SFProRounded': 'SF Pro Rounded',
    'SFRounded': 'SF Pro Rounded',
    'sf_rounded': 'SF Pro Rounded',
    'sf_pro_rounded': 'SF Pro Rounded',
    'SF Compact': 'SF Compact',
    'SF Compact Rounded': 'SF Compact Rounded',
    'SFCompactRounded': 'SF Compact Rounded',
    'SF Compact Round': 'SF Compact Rounded',
    'SF Mono': 'SF Mono',
    'SFMono': 'SF Mono',
    'New York': 'New York',
    'NewYork': 'New York',
  };

  /// Native iOS / Apple font families that map directly to system fonts.
  static const Set<String> nativeAppleFonts = {
    'SF Pro',
    'SF Pro Rounded',
    'SF Compact',
    'SF Compact Rounded',
    'SF Mono',
    'New York',
  };

  /// Resolves the given [family] name, checking alias mappings first.
  static String resolveFamilyName(String family) {
    if (GoogleFonts.asMap().containsKey(family)) {
      return family;
    }
    return _fontAliases[family] ?? family;
  }

  /// Returns system fallback font families for native Apple / iOS fonts.
  static List<String>? nativeFontFallback(String family) {
    final resolved = resolveFamilyName(family);
    return switch (resolved) {
      'SF Pro Rounded' => const ['.SF Rounded', 'SF Pro Rounded', '.AppleSystemUIFont', 'sans-serif'],
      'SF Pro' => const ['.SF Pro Text', '.SF NS Text', 'SF Pro', '.AppleSystemUIFont', 'sans-serif'],
      'SF Compact Rounded' => const ['.SF Compact Rounded', '.SF Rounded', 'SF Compact Rounded', 'sans-serif'],
      'SF Compact' => const ['.SF Compact Text', 'SF Compact', 'sans-serif'],
      'SF Mono' => const ['.AppleSystemUIFontMonospaced', 'SF Mono', 'Menlo', 'Courier', 'monospace'],
      'New York' => const ['.SF Serif', 'New York', 'Georgia', 'serif'],
      _ => null,
    };
  }

  /// Returns [style] with the resolved [family] applied. Falls back to the
  /// raw family name if Google Fonts doesn't know it.
  /// Also configures OpenType font features and variable font variations
  /// for rounded fonts like 'Google Sans Rounded' or 'SF Pro Rounded'.
  static TextStyle apply(
    String family,
    TextStyle style, {
    bool? isRounded,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
  }) {
    final bool roundedRequested = isRounded ?? _isRoundedFamily(family);
    final targetFamily = resolveFamilyName(family);
    final isNativeApple = nativeAppleFonts.contains(targetFamily);
    final key =
        '$targetFamily|${style.fontWeight?.value}|${style.fontStyle?.index}';
    var resolved = _cache[key];
    if (resolved == null) {
      if (isNativeApple) {
        resolved = (
          fontFamily: targetFamily,
          fontFamilyFallback: nativeFontFallback(targetFamily),
        );
      } else {
        try {
          final gf = GoogleFonts.getFont(targetFamily, textStyle: style);
          resolved = (
            fontFamily: gf.fontFamily,
            fontFamilyFallback: gf.fontFamilyFallback,
          );
        } catch (_) {
          resolved = (
            fontFamily: targetFamily,
            fontFamilyFallback: nativeFontFallback(targetFamily),
          );
        }
      }
      _cache[key] = resolved;
    }

    final mergedFeatures = <FontFeature>[
      ...?style.fontFeatures,
      ...?fontFeatures,
      if (roundedRequested) ...const [
        FontFeature.enable('ss01'),
        FontFeature('rndd'),
      ],
    ];

    final mergedVariations = <FontVariation>[
      ...?style.fontVariations,
      ...?fontVariations,
      if (roundedRequested) ...const [
        FontVariation('RNDD', 1.0),
      ],
    ];

    return style.copyWith(
      fontFamily: resolved.fontFamily,
      fontFamilyFallback: resolved.fontFamilyFallback ?? style.fontFamilyFallback,
      fontFeatures: mergedFeatures.isNotEmpty ? mergedFeatures : style.fontFeatures,
      fontVariations: mergedVariations.isNotEmpty ? mergedVariations : style.fontVariations,
    );
  }

  static bool _isRoundedFamily(String family) {
    final lower = family.toLowerCase();
    return lower.contains('rounded') || lower.contains('round');
  }
}


