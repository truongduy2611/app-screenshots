import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslationBundle', () {
    test('default construction has expected values', () {
      const bundle = TranslationBundle();
      expect(bundle.sourceLocale, 'en');
      expect(bundle.targetLocales, isEmpty);
      expect(bundle.translations, isEmpty);
    });

    test('toJson and fromJson round-trip', () {
      final bundle = TranslationBundle(
        sourceLocale: 'en',
        targetLocales: ['ja', 'de'],
        translations: {
          'ja': {'overlay_1': 'テスト', 'overlay_2': 'サンプル'},
          'de': {'overlay_1': 'Test', 'overlay_2': 'Probe'},
        },
      );

      final json = bundle.toJson();
      final restored = TranslationBundle.fromJson(json);

      expect(restored.sourceLocale, 'en');
      expect(restored.targetLocales, ['ja', 'de']);
      expect(restored.translations['ja']!['overlay_1'], 'テスト');
      expect(restored.translations['de']!['overlay_2'], 'Probe');
    });

    test('fromJson handles missing fields gracefully', () {
      final bundle = TranslationBundle.fromJson({});
      expect(bundle.sourceLocale, 'en');
      expect(bundle.targetLocales, isEmpty);
      expect(bundle.translations, isEmpty);
    });

    test('getTranslation returns correct text', () {
      final bundle = TranslationBundle(
        translations: {
          'ja': {'overlay_1': '翻訳されたテキスト'},
        },
      );

      expect(bundle.getTranslation('ja', 'overlay_1'), '翻訳されたテキスト');
    });

    test('getTranslation returns null for missing locale', () {
      const bundle = TranslationBundle();
      expect(bundle.getTranslation('ja', 'overlay_1'), isNull);
    });

    test('getTranslation returns null for missing overlay', () {
      final bundle = TranslationBundle(
        translations: {
          'ja': {'overlay_1': '何か'},
        },
      );
      expect(bundle.getTranslation('ja', 'overlay_999'), isNull);
    });

    test('setTranslation adds a new translation', () {
      const bundle = TranslationBundle();
      final updated = bundle.setTranslation('ja', 'overlay_1', '新しい');

      expect(updated.getTranslation('ja', 'overlay_1'), '新しい');
      // Original is unchanged
      expect(bundle.getTranslation('ja', 'overlay_1'), isNull);
    });

    test('setTranslation updates an existing translation', () {
      final bundle = TranslationBundle(
        translations: {
          'ja': {'overlay_1': '古い'},
        },
      );
      final updated = bundle.setTranslation('ja', 'overlay_1', '新しい');

      expect(updated.getTranslation('ja', 'overlay_1'), '新しい');
    });

    test('setTranslation preserves other overlays in same locale', () {
      final bundle = TranslationBundle(
        translations: {
          'ja': {'overlay_1': 'A', 'overlay_2': 'B'},
        },
      );
      final updated = bundle.setTranslation('ja', 'overlay_1', 'C');

      expect(updated.getTranslation('ja', 'overlay_1'), 'C');
      expect(updated.getTranslation('ja', 'overlay_2'), 'B');
    });

    test('setLocaleTranslations replaces all translations for a locale', () {
      final bundle = TranslationBundle(
        translations: {
          'ja': {'overlay_1': 'A', 'overlay_2': 'B'},
        },
      );

      final updated = bundle.setLocaleTranslations('ja', {
        'overlay_1': 'X',
        'overlay_3': 'Y',
      });

      expect(updated.getTranslation('ja', 'overlay_1'), 'X');
      expect(updated.getTranslation('ja', 'overlay_2'), isNull);
      expect(updated.getTranslation('ja', 'overlay_3'), 'Y');
    });

    test('copyWith preserves unchanged fields', () {
      final bundle = TranslationBundle(
        sourceLocale: 'en',
        targetLocales: ['ja'],
        translations: {
          'ja': {'o1': 'test'},
        },
      );

      final updated = bundle.copyWith(sourceLocale: 'fr');

      expect(updated.sourceLocale, 'fr');
      expect(updated.targetLocales, ['ja']);
      expect(updated.getTranslation('ja', 'o1'), 'test');
    });

    test('equatable compares by value', () {
      final a = TranslationBundle(
        sourceLocale: 'en',
        targetLocales: ['ja'],
        translations: {
          'ja': {'o1': 'x'},
        },
      );
      final b = TranslationBundle(
        sourceLocale: 'en',
        targetLocales: ['ja'],
        translations: {
          'ja': {'o1': 'x'},
        },
      );

      expect(a, equals(b));
    });
  });
}
