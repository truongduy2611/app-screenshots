import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';

/// Result of exporting screenshots for a single locale.
class LocaleExportResult {
  final String locale;
  final int screenshotCount;
  final String directoryPath;

  const LocaleExportResult({
    required this.locale,
    required this.screenshotCount,
    required this.directoryPath,
  });
}

/// Exports screenshot designs to locale-organized folders.
///
/// Output structure:
/// ```
/// exportDir/
/// ├── en/
/// │   ├── screenshot_1.png
/// │   └── screenshot_2.png
/// ├── ja/
/// │   ├── screenshot_1.png
/// │   └── screenshot_2.png
/// └── de/
///     ├── screenshot_1.png
///     └── screenshot_2.png
/// ```
class MultiLocaleExporter {
  /// Export screenshots for all locales in the bundle.
  ///
  /// [designs] are the saved designs to export.
  /// [bundle] contains translation data for each locale.
  /// [exportBasePath] is the root directory for the export.
  /// [renderDesign] is a callback that renders a design to PNG bytes,
  ///   applying the given locale's translations to text overlays.
  ///
  /// Returns a list of [LocaleExportResult] for each locale exported.
  Future<List<LocaleExportResult>> exportAll({
    required List<SavedDesign> designs,
    required TranslationBundle bundle,
    required String exportBasePath,
    required Future<List<int>> Function(SavedDesign design, String? locale)
    renderDesign,
  }) async {
    final results = <LocaleExportResult>[];

    // All locales: source + targets
    final allLocales = [bundle.sourceLocale, ...bundle.targetLocales];

    for (final locale in allLocales) {
      final localeDir = Directory('$exportBasePath/$locale');
      await localeDir.create(recursive: true);

      int count = 0;
      for (int i = 0; i < designs.length; i++) {
        // For source locale, pass null to use original text.
        // For target locales, pass the locale to apply translations.
        final localeForRender = locale == bundle.sourceLocale ? null : locale;

        final pngBytes = await renderDesign(designs[i], localeForRender);

        final file = File('${localeDir.path}/screenshot_${i + 1}.png');
        await file.writeAsBytes(pngBytes);
        count++;
      }

      results.add(
        LocaleExportResult(
          locale: locale,
          screenshotCount: count,
          directoryPath: localeDir.path,
        ),
      );
    }

    return results;
  }
}
