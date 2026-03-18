import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'translation_state.dart';

/// Manages translation state for the screenshot editor.
///
/// Handles translating text overlays to multiple locales, previewing
/// translated text in the editor, and manual edits to translations.
class TranslationCubit extends Cubit<TranslationState> {
  final TranslationService _translationService;

  TranslationCubit(this._translationService) : super(const TranslationState());

  /// Load an existing bundle (e.g. from a saved design).
  void loadBundle(TranslationBundle? bundle) {
    if (bundle == null) {
      emit(state.copyWith(clearBundle: true));
      return;
    }

    // Restore locale statuses: mark each target locale that has
    // non-empty translations as "done" so checkmarks appear.
    final restoredStatuses = <String, TranslationStatus>{};
    for (final locale in bundle.targetLocales) {
      final hasTranslations = bundle.translations[locale]?.isNotEmpty == true;
      if (hasTranslations) {
        restoredStatuses[locale] = TranslationStatus.done;
      }
    }

    emit(state.copyWith(bundle: bundle, localeStatuses: restoredStatuses));
  }

  /// Translate all overlays for all target locales.
  ///
  /// [sourceTexts] maps overlay IDs to their current text.
  Future<void> translateAll({
    required Map<String, String> sourceTexts,
    required String sourceLocale,
    required List<String> targetLocales,
  }) async {
    if (sourceTexts.isEmpty || targetLocales.isEmpty) return;

    final provider = await _translationService.getActiveProvider();

    var bundle = state.bundle ?? const TranslationBundle();
    bundle = bundle.copyWith(sourceLocale: sourceLocale);

    // Clear any previous error
    emit(state.copyWith(bundle: bundle, clearError: true));

    AppLogger.d(
      'translateAll: source=$sourceLocale, targets=$targetLocales, '
      'overlays=${sourceTexts.length}, prompt=${bundle.customPrompt}',
      tag: 'Translation',
    );
    AppLogger.d('translateAll sourceTexts: $sourceTexts', tag: 'Translation');

    for (final locale in targetLocales) {
      _emitLocaleStatus(locale, TranslationStatus.translating);

      try {
        final rawResult = await provider.translate(
          texts: sourceTexts,
          from: sourceLocale,
          to: locale,
          context: bundle.customPrompt,
        );

        AppLogger.d(
          'translateAll raw result [$locale]: $rawResult',
          tag: 'Translation',
        );

        // Providers may return {sourceText: translatedText} instead of
        // {overlayId: translatedText}. Detect this by checking whether
        // the returned keys match overlay IDs. If not, re-map using a
        // reverse lookup (sourceText → list of overlayIds).
        Map<String, String> translated;
        final resultKeysMatchIds = rawResult.keys.any(
          (k) => sourceTexts.containsKey(k),
        );

        if (resultKeysMatchIds) {
          // Provider returned overlay-ID-keyed results — use as-is.
          translated = rawResult;
        } else {
          // Provider returned source-text-keyed results — re-map.
          // Build reverse lookup: sourceText → [overlayId, ...]
          final textToIds = <String, List<String>>{};
          for (final entry in sourceTexts.entries) {
            textToIds.putIfAbsent(entry.value, () => []).add(entry.key);
          }

          translated = {};
          for (final entry in rawResult.entries) {
            final ids = textToIds[entry.key];
            if (ids != null) {
              for (final id in ids) {
                translated[id] = entry.value;
              }
            }
          }

          AppLogger.d(
            'translateAll remapped [$locale]: $translated',
            tag: 'Translation',
          );
        }

        bundle = bundle.setLocaleTranslations(locale, translated);
        emit(state.copyWith(bundle: bundle));
        _emitLocaleStatus(locale, TranslationStatus.done);
      } catch (e, st) {
        AppLogger.error(
          'Translation failed for locale $locale',
          tag: 'Translation',
          error: e,
          stackTrace: st,
        );
        _emitLocaleStatus(locale, TranslationStatus.error);
        emit(state.copyWith(errorMessage: e.toString()));
      }
    }
  }

  /// Retry translation for a single locale.
  Future<void> retryLocale(
    String locale,
    Map<String, String> sourceTexts,
  ) async {
    if (state.bundle == null) return;
    AppLogger.d(
      'retryLocale: locale=$locale, sourceTexts=$sourceTexts',
      tag: 'Translation',
    );
    await translateAll(
      sourceTexts: sourceTexts,
      sourceLocale: state.bundle!.sourceLocale,
      targetLocales: [locale],
    );
  }

  /// Manually edit a single overlay translation for a locale.
  void updateTranslation(String locale, String overlayId, String text) {
    if (state.bundle == null) return;
    emit(
      state.copyWith(
        bundle: state.bundle!.setTranslation(locale, overlayId, text),
      ),
    );
  }

  /// Remove a locale's translations, overrides, and status entirely.
  void removeLocale(String locale) {
    if (state.bundle == null) return;
    final updated = state.bundle!.removeLocale(locale);
    final statuses = Map<String, TranslationStatus>.from(state.localeStatuses)
      ..remove(locale);
    emit(
      state.copyWith(
        bundle: updated,
        localeStatuses: statuses,
        // Clear preview if this locale was being previewed.
        clearPreviewLocale: state.previewLocale == locale,
      ),
    );
  }

  /// Set the preview locale displayed in the editor canvas.
  ///
  /// Pass `null` to show the original source text.
  void setPreviewLocale(String? locale) {
    emit(
      state.copyWith(previewLocale: locale, clearPreviewLocale: locale == null),
    );
  }

  /// Update a per-locale layout override (position, width, scale, fontSize)
  /// for a specific overlay. Creates the bundle if none exists.
  void updateOverlayOverride(
    String locale,
    String overlayId,
    OverlayOverride override,
  ) {
    var bundle = state.bundle ?? const TranslationBundle();
    bundle = bundle.setOverride(locale, overlayId, override);
    emit(state.copyWith(bundle: bundle));
  }

  /// Update the custom prompt (app context) stored in the bundle.
  void setCustomPrompt(String? prompt) {
    var bundle = state.bundle ?? const TranslationBundle();
    bundle = bundle.copyWith(
      customPrompt: prompt?.isEmpty == true ? null : prompt,
    );
    emit(state.copyWith(bundle: bundle));
  }

  /// Set the screenshot image path for a locale.
  void setLocaleImage(String locale, String filePath) {
    var bundle = state.bundle ?? const TranslationBundle();
    bundle = bundle.setLocaleImage(locale, filePath);
    emit(state.copyWith(bundle: bundle));
  }

  /// Remove the screenshot image for a locale.
  void removeLocaleImage(String locale) {
    if (state.bundle == null) return;
    emit(state.copyWith(bundle: state.bundle!.removeLocaleImage(locale)));
  }

  /// Get the locale-specific screenshot image path for the current
  /// preview locale, or `null` if none is set.
  String? get currentLocaleImagePath {
    final locale = state.previewLocale;
    if (locale == null || state.bundle == null) return null;
    return state.bundle!.getLocaleImage(locale);
  }

  /// Apply translations from the manual copy-paste flow.
  void applyManualTranslation(String locale, Map<String, String> texts) {
    AppLogger.d('applyManualTranslation [$locale]: $texts', tag: 'Translation');
    var bundle = state.bundle ?? const TranslationBundle();
    bundle = bundle.setLocaleTranslations(locale, texts);
    emit(state.copyWith(bundle: bundle));
    _emitLocaleStatus(locale, TranslationStatus.done);
  }

  void _emitLocaleStatus(String locale, TranslationStatus status) {
    final updated = Map<String, TranslationStatus>.from(state.localeStatuses);
    updated[locale] = status;
    emit(state.copyWith(localeStatuses: updated));
  }
}
