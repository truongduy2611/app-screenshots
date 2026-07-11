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

  /// Returns [style] with the resolved [family] applied. Falls back to the
  /// raw family name if Google Fonts doesn't know it.
  static TextStyle apply(String family, TextStyle style) {
    final key = '$family|${style.fontWeight?.value}|${style.fontStyle?.index}';
    var resolved = _cache[key];
    if (resolved == null) {
      try {
        final gf = GoogleFonts.getFont(family, textStyle: style);
        resolved = (
          fontFamily: gf.fontFamily,
          fontFamilyFallback: gf.fontFamilyFallback,
        );
      } catch (_) {
        resolved = (fontFamily: family, fontFamilyFallback: null);
      }
      _cache[key] = resolved;
    }
    return style.copyWith(
      fontFamily: resolved.fontFamily,
      fontFamilyFallback: resolved.fontFamilyFallback,
    );
  }
}
