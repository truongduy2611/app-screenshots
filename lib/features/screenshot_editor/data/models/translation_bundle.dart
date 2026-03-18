import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:equatable/equatable.dart';

/// Stores per-locale translations for text overlays in a design.
///
/// Each overlay is identified by its [id] and mapped to a translated string
/// per locale. The [sourceLocale] indicates the original language the user
/// typed in the editor.
class TranslationBundle extends Equatable {
  /// Source locale code (e.g. "en").
  final String sourceLocale;

  /// Target locales the user selected for translation.
  final List<String> targetLocales;

  /// locale → (overlayId → translatedText)
  final Map<String, Map<String, String>> translations;

  /// locale → (overlayId → OverlayOverride)
  /// Stores per-locale position/size/scale adjustments for text overlays.
  final Map<String, Map<String, OverlayOverride>> overrides;

  /// Optional user-provided app context (e.g. "This is a fitness tracking app
  /// for runners") that is injected into the translation prompt to improve
  /// domain-specific translation quality.
  final String? customPrompt;

  const TranslationBundle({
    this.sourceLocale = 'en',
    this.targetLocales = const [],
    this.translations = const {},
    this.overrides = const {},
    this.customPrompt,
  });

  TranslationBundle copyWith({
    String? sourceLocale,
    List<String>? targetLocales,
    Map<String, Map<String, String>>? translations,
    Map<String, Map<String, OverlayOverride>>? overrides,
    String? customPrompt,
  }) {
    return TranslationBundle(
      sourceLocale: sourceLocale ?? this.sourceLocale,
      targetLocales: targetLocales ?? this.targetLocales,
      translations: translations ?? this.translations,
      overrides: overrides ?? this.overrides,
      customPrompt: customPrompt ?? this.customPrompt,
    );
  }

  /// Get translated text for a specific overlay in a locale.
  /// Returns `null` if no translation exists.
  String? getTranslation(String locale, String overlayId) {
    return translations[locale]?[overlayId];
  }

  /// Returns a new bundle with a single overlay translation updated.
  TranslationBundle setTranslation(
    String locale,
    String overlayId,
    String text,
  ) {
    final updated = Map<String, Map<String, String>>.from(
      translations.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
    );
    updated.putIfAbsent(locale, () => {});
    updated[locale]![overlayId] = text;
    return copyWith(translations: updated);
  }

  /// Returns a new bundle with all translations for a locale replaced.
  TranslationBundle setLocaleTranslations(
    String locale,
    Map<String, String> localeTranslations,
  ) {
    final updated = Map<String, Map<String, String>>.from(
      translations.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
    );
    updated[locale] = localeTranslations;
    return copyWith(translations: updated);
  }

  // ── Overlay overrides ──

  /// Get a per-locale layout override for an overlay.
  OverlayOverride? getOverride(String locale, String overlayId) {
    return overrides[locale]?[overlayId];
  }

  /// Set (or replace) a per-locale layout override for an overlay.
  TranslationBundle setOverride(
    String locale,
    String overlayId,
    OverlayOverride override,
  ) {
    final updated = Map<String, Map<String, OverlayOverride>>.from(
      overrides.map(
        (k, v) => MapEntry(k, Map<String, OverlayOverride>.from(v)),
      ),
    );
    updated.putIfAbsent(locale, () => {});
    updated[locale]![overlayId] = override;
    return copyWith(overrides: updated);
  }

  /// Remove a locale entirely — drops it from targetLocales, translations,
  /// and overrides.
  TranslationBundle removeLocale(String locale) {
    final updatedTranslations = Map<String, Map<String, String>>.from(
      translations.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
    )..remove(locale);
    final updatedOverrides = Map<String, Map<String, OverlayOverride>>.from(
      overrides.map(
        (k, v) => MapEntry(k, Map<String, OverlayOverride>.from(v)),
      ),
    )..remove(locale);
    return copyWith(
      targetLocales: targetLocales.where((l) => l != locale).toList(),
      translations: updatedTranslations,
      overrides: updatedOverrides,
    );
  }

  Map<String, dynamic> toJson() => {
    'sourceLocale': sourceLocale,
    'targetLocales': targetLocales,
    'translations': translations,
    'overrides': overrides.map(
      (locale, overlayMap) =>
          MapEntry(locale, overlayMap.map((id, o) => MapEntry(id, o.toJson()))),
    ),
    if (customPrompt != null) 'customPrompt': customPrompt,
  };

  factory TranslationBundle.fromJson(Map<String, dynamic> json) {
    return TranslationBundle(
      sourceLocale: json['sourceLocale'] as String? ?? 'en',
      targetLocales: List<String>.from(json['targetLocales'] ?? []),
      translations:
          (json['translations'] as Map<String, dynamic>?)?.map(
            (locale, overlays) =>
                MapEntry(locale, Map<String, String>.from(overlays as Map)),
          ) ??
          {},
      overrides:
          (json['overrides'] as Map<String, dynamic>?)?.map(
            (locale, overlayMap) => MapEntry(
              locale,
              (overlayMap as Map<String, dynamic>).map(
                (id, o) => MapEntry(
                  id,
                  OverlayOverride.fromJson(Map<String, dynamic>.from(o as Map)),
                ),
              ),
            ),
          ) ??
          {},
      customPrompt: json['customPrompt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    sourceLocale,
    targetLocales,
    translations,
    overrides,
    customPrompt,
  ];
}
