// TECH_DEBT: Color.value deprecated in Flutter 3.27
// ignore_for_file: deprecated_member_use
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextOverlay', () {
    TextOverlay buildOverlay({
      TextStyle? style,
      String? googleFont,
      double? rotation,
      TextAlign? textAlign,
      TextDecoration? decoration,
      TextDecorationStyle? decorationStyle,
      Color? decorationColor,
      Color? backgroundColor,
      Color? borderColor,
      double? borderWidth,
      double? borderRadius,
      double? scale,
      double? width,
      int? zIndex,
      bool? behindFrame,
    }) {
      return TextOverlay(
        id: 'test-1',
        text: 'Hello',
        style: style ??
            const TextStyle(
              fontSize: 24,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
        position: const Offset(100, 200),
        googleFont: googleFont ?? 'Roboto',
        rotation: rotation ?? 0.5,
        textAlign: textAlign ?? TextAlign.left,
        decoration: decoration ?? TextDecoration.underline,
        decorationStyle: decorationStyle ?? TextDecorationStyle.dashed,
        decorationColor: decorationColor ?? const Color(0xFFFF0000),
        backgroundColor: backgroundColor ?? const Color(0x80000000),
        borderColor: borderColor ?? const Color(0xFF00FF00),
        borderWidth: borderWidth ?? 2.0,
        borderRadius: borderRadius ?? 4.0,
        scale: scale ?? 1.5,
        width: width ?? 300.0,
        zIndex: zIndex ?? 5,
        behindFrame: behindFrame ?? true,
      );
    }

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = buildOverlay();
      final json = original.toJson();
      final restored = TextOverlay.fromJson(json);

      expect(restored.id, 'test-1');
      expect(restored.text, 'Hello');
      expect(restored.style.fontSize, 24);
      expect(restored.style.color, const Color(0xFFFFFFFF));
      expect(restored.style.fontWeight, FontWeight.w700);
      expect(restored.style.fontStyle, FontStyle.italic);
      expect(restored.position, const Offset(100, 200));
      expect(restored.googleFont, 'Roboto');
      expect(restored.rotation, 0.5);
      expect(restored.textAlign, TextAlign.left);
      expect(restored.decoration, TextDecoration.underline);
      expect(restored.decorationStyle, TextDecorationStyle.dashed);
      expect(restored.decorationColor, const Color(0xFFFF0000));
      expect(restored.backgroundColor, const Color(0x80000000));
      expect(restored.borderColor, const Color(0xFF00FF00));
      expect(restored.borderWidth, 2.0);
      expect(restored.borderRadius, 4.0);
      expect(restored.scale, 1.5);
      expect(restored.width, 300.0);
      expect(restored.zIndex, 5);
      expect(restored.behindFrame, true);
    });

    group('fontWeight parsing', () {
      for (final weight in FontWeight.values) {
        test('roundtrips FontWeight.w${weight.value}', () {
          final overlay = buildOverlay(
            style: TextStyle(fontSize: 16, fontWeight: weight),
          );
          final json = overlay.toJson();
          final restored = TextOverlay.fromJson(json);
          expect(restored.style.fontWeight, weight);
        });
      }

      test('null fontWeight remains null', () {
        final overlay = buildOverlay(
          style: const TextStyle(fontSize: 16),
        );
        final json = overlay.toJson();
        final restored = TextOverlay.fromJson(json);
        expect(restored.style.fontWeight, isNull);
      });

      test('unknown fontWeight value falls back to w400', () {
        final json = buildOverlay().toJson();
        // Inject a non-standard weight value
        (json['style'] as Map<String, dynamic>)['fontWeight'] = 999;
        final restored = TextOverlay.fromJson(json);
        expect(restored.style.fontWeight, FontWeight.w400);
      });
    });

    test('fromJson with minimal data uses defaults', () {
      final json = {
        'id': 'min-1',
        'text': 'Minimal',
        'style': {'fontSize': 16.0},
        'position': {'dx': 0.0, 'dy': 0.0},
      };
      final restored = TextOverlay.fromJson(json);
      expect(restored.rotation, 0.0);
      expect(restored.textAlign, TextAlign.center);
      expect(restored.decoration, TextDecoration.none);
      expect(restored.borderWidth, 0.0);
      expect(restored.borderRadius, 0.0);
      expect(restored.horizontalPadding, 8.0);
      expect(restored.verticalPadding, 8.0);
      expect(restored.scale, 1.0);
      expect(restored.width, isNull);
      expect(restored.zIndex, 1); // default for text is 1
      expect(restored.behindFrame, false);
    });

    group('_parseDecoration', () {
      test('underline', () {
        final json = buildOverlay(decoration: TextDecoration.underline).toJson();
        expect(TextOverlay.fromJson(json).decoration, TextDecoration.underline);
      });

      test('overline', () {
        final json = buildOverlay(decoration: TextDecoration.overline).toJson();
        expect(TextOverlay.fromJson(json).decoration, TextDecoration.overline);
      });

      test('lineThrough', () {
        final json =
            buildOverlay(decoration: TextDecoration.lineThrough).toJson();
        expect(
            TextOverlay.fromJson(json).decoration, TextDecoration.lineThrough);
      });

      test('none', () {
        final json = buildOverlay(decoration: TextDecoration.none).toJson();
        expect(TextOverlay.fromJson(json).decoration, TextDecoration.none);
      });

      test('unknown value defaults to none', () {
        final json = buildOverlay().toJson();
        json['decoration'] = 'SomeUnknownValue';
        expect(TextOverlay.fromJson(json).decoration, TextDecoration.none);
      });
    });

    test('copyWith preserves unmodified fields', () {
      final original = buildOverlay();
      final modified = original.copyWith(text: 'Changed');
      expect(modified.text, 'Changed');
      expect(modified.id, original.id);
      expect(modified.style, original.style);
      expect(modified.position, original.position);
    });

    test('copyWith clearWidth sets width to null', () {
      final original = buildOverlay(width: 300.0);
      final cleared = original.copyWith(clearWidth: true);
      expect(cleared.width, isNull);
    });

    test('textAlign roundtrips through index', () {
      for (final align in TextAlign.values) {
        final overlay = buildOverlay(textAlign: align);
        final json = overlay.toJson();
        final restored = TextOverlay.fromJson(json);
        expect(restored.textAlign, align);
      }
    });
  });
}
