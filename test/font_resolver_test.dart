import 'package:app_screenshots/features/screenshot_editor/utils/font_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FontResolver Google Sans & Native iOS Fonts Tests', () {
    const baseStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    test('resolves Google Sans & Native iOS font family aliases', () {
      expect(FontResolver.resolveFamilyName('Google Sans Rounded'), equals('Google Sans'));
      expect(FontResolver.resolveFamilyName('GoogleSansRounded'), equals('Google Sans'));
      expect(FontResolver.resolveFamilyName('Google Sans Text'), equals('Google Sans'));
      expect(FontResolver.resolveFamilyName('Google Sans'), equals('Google Sans'));

      // Native iOS font aliases
      expect(FontResolver.resolveFamilyName('SF'), equals('SF Pro'));
      expect(FontResolver.resolveFamilyName('San Francisco'), equals('SF Pro'));
      expect(FontResolver.resolveFamilyName('SF Round'), equals('SF Pro Rounded'));
      expect(FontResolver.resolveFamilyName('SF Rounded'), equals('SF Pro Rounded'));
      expect(FontResolver.resolveFamilyName('SFRounded'), equals('SF Pro Rounded'));
      expect(FontResolver.resolveFamilyName('sf_rounded'), equals('SF Pro Rounded'));
      expect(FontResolver.resolveFamilyName('SF Compact Round'), equals('SF Compact Rounded'));
      expect(FontResolver.resolveFamilyName('SF Mono'), equals('SF Mono'));
      expect(FontResolver.resolveFamilyName('New York'), equals('New York'));
    });

    testWidgets('resolves native iOS fonts with proper system font fallbacks', (tester) async {
      final sfProStyle = FontResolver.apply('SF Pro', baseStyle);
      expect(sfProStyle.fontFamily, equals('SF Pro'));
      expect(sfProStyle.fontFamilyFallback, contains('.AppleSystemUIFont'));

      final sfRoundStyle = FontResolver.apply('SF Round', baseStyle);
      expect(sfRoundStyle.fontFamily, equals('SF Pro Rounded'));
      expect(sfRoundStyle.fontFamilyFallback, contains('.SF Rounded'));
      expect(sfRoundStyle.fontFeatures, isNotNull);
      expect(sfRoundStyle.fontFeatures!.any((f) => f.feature == 'ss01' || f.feature == 'rndd'), isTrue);

      final sfMonoStyle = FontResolver.apply('SF Mono', baseStyle);
      expect(sfMonoStyle.fontFamily, equals('SF Mono'));
      expect(sfMonoStyle.fontFamilyFallback, contains('.AppleSystemUIFontMonospaced'));

      final nyStyle = FontResolver.apply('New York', baseStyle);
      expect(nyStyle.fontFamily, equals('New York'));
      expect(nyStyle.fontFamilyFallback, contains('.SF Serif'));
    });

    testWidgets('applies rounded font features and font variations when requested', (tester) async {
      final style = FontResolver.apply(
        'Google Sans Rounded',
        baseStyle,
      );

      expect(style.fontFeatures, isNotNull);
      expect(style.fontFeatures!.any((f) => f.feature == 'ss01' || f.feature == 'rndd'), isTrue);
      expect(style.fontVariations, isNotNull);
      expect(style.fontVariations!.any((v) => v.axis == 'RNDD'), isTrue);
    });

    testWidgets('supports custom isRounded, fontFeatures, and fontVariations settings', (tester) async {
      final style = FontResolver.apply(
        'Google Sans',
        baseStyle,
        isRounded: true,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: const [FontVariation('wght', 700)],
      );

      expect(style.fontFeatures, isNotNull);
      expect(style.fontFeatures!.any((f) => f.feature == 'tnum'), isTrue);
      expect(style.fontFeatures!.any((f) => f.feature == 'ss01' || f.feature == 'rndd'), isTrue);
      expect(style.fontVariations, isNotNull);
      expect(style.fontVariations!.any((v) => v.axis == 'wght' && v.value == 700), isTrue);
    });
  });
}
