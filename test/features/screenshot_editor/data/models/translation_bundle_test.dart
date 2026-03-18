import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslationBundle', () {
    test('default construction has expected values', () {
      const bundle = TranslationBundle();
      expect(bundle.sourceLocale, 'en');
      expect(bundle.targetLocales, isEmpty);
      expect(bundle.translations, isEmpty);
      expect(bundle.overrides, isEmpty);
      expect(bundle.localeImages, isEmpty);
      expect(bundle.customPrompt, isNull);
    });

    test('toJson and fromJson round-trip with all fields', () {
      final bundle = TranslationBundle(
        sourceLocale: 'en',
        targetLocales: ['ja', 'de'],
        translations: {
          'ja': {'overlay_1': 'テスト', 'overlay_2': 'サンプル'},
          'de': {'overlay_1': 'Test', 'overlay_2': 'Probe'},
        },
        overrides: {
          'ja': {
            'overlay_1': const OverlayOverride(
              position: Offset(1, 2),
              width: 100,
              scale: 1.5,
              fontSize: 24,
            ),
          },
        },
        localeImages: {'ja': '/path/to/ja.png'},
        customPrompt: 'Test context',
      );

      final json = bundle.toJson();
      final restored = TranslationBundle.fromJson(json);

      expect(restored.sourceLocale, 'en');
      expect(restored.targetLocales, ['ja', 'de']);
      expect(restored.translations['ja']!['overlay_1'], 'テスト');
      expect(restored.translations['de']!['overlay_2'], 'Probe');
      expect(restored.overrides['ja']!['overlay_1']!.position?.dx, 1);
      expect(restored.localeImages['ja'], '/path/to/ja.png');
      expect(restored.customPrompt, 'Test context');
      expect(restored, equals(bundle));
    });

    test('fromJson handles missing fields gracefully', () {
      final bundle = TranslationBundle.fromJson({});
      expect(bundle.sourceLocale, 'en');
      expect(bundle.targetLocales, isEmpty);
      expect(bundle.translations, isEmpty);
      expect(bundle.overrides, isEmpty);
      expect(bundle.localeImages, isEmpty);
      expect(bundle.customPrompt, isNull);
    });

    test('getTranslation returns correct text or null', () {
      final bundle = TranslationBundle(
        translations: {
          'ja': {'overlay_1': '翻訳されたテキスト'},
        },
      );
      expect(bundle.getTranslation('ja', 'overlay_1'), '翻訳されたテキスト');
      expect(bundle.getTranslation('en', 'overlay_1'), isNull);
      expect(bundle.getTranslation('ja', 'overlay_999'), isNull);
    });

    test(
      'setTranslation adds/updates translation and updates targetLocales',
      () {
        const bundle = TranslationBundle();
        final updated = bundle.setTranslation('ja', 'overlay_1', '新しい');

        expect(updated.getTranslation('ja', 'overlay_1'), '新しい');
        expect(updated.targetLocales, contains('ja'));

        // Original is unchanged
        expect(bundle.getTranslation('ja', 'overlay_1'), isNull);

        // Update existing
        final updated2 = updated.setTranslation('ja', 'overlay_1', '更新');
        expect(updated2.getTranslation('ja', 'overlay_1'), '更新');
      },
    );

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
      expect(updated.targetLocales, contains('ja'));
    });

    test('setOverride and getOverride work correctly', () {
      const bundle = TranslationBundle();
      const override = OverlayOverride(position: Offset(10, 20));
      final updated = bundle.setOverride('es', 'overlay_1', override);

      expect(updated.getOverride('es', 'overlay_1'), override);
      expect(updated.targetLocales, contains('es'));
    });

    test('setLocaleImage and getLocaleImage work correctly', () {
      const bundle = TranslationBundle();
      final updated = bundle.setLocaleImage('ko', '/path/to/image.png');

      expect(updated.getLocaleImage('ko'), '/path/to/image.png');
      expect(updated.targetLocales, contains('ko'));
    });

    test('removeLocaleImage removes only the image', () {
      final bundle = const TranslationBundle().setLocaleImage(
        'ja',
        '/path.png',
      );
      final updated = bundle.removeLocaleImage('ja');

      expect(updated.getLocaleImage('ja'), isNull);
      expect(updated.targetLocales, contains('ja')); // Target locale remains
    });

    test('removeLocale completely removes a locale from all maps', () {
      final bundle = const TranslationBundle()
          .setTranslation('de', 'overlay_1', 'Hallo')
          .setOverride(
            'de',
            'overlay_1',
            const OverlayOverride(position: Offset(0, 0)),
          )
          .setLocaleImage('de', '/path.png');

      expect(bundle.targetLocales, contains('de'));
      expect(bundle.translations, contains('de'));
      expect(bundle.overrides, contains('de'));
      expect(bundle.localeImages, contains('de'));

      final updated = bundle.removeLocale('de');

      expect(updated.targetLocales, isNot(contains('de')));
      expect(updated.translations, isNot(contains('de')));
      expect(updated.overrides, isNot(contains('de')));
      expect(updated.localeImages, isNot(contains('de')));
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
