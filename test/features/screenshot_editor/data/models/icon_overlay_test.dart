// TECH_DEBT: Color.value deprecated in Flutter 3.27
// ignore_for_file: deprecated_member_use
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IconOverlay', () {
    IconOverlay buildFull() {
      return IconOverlay(
        id: 'icon-1',
        codePoint: 0xe87c,
        fontFamily: 'sficons',
        fontPackage: 'flutter_sficon',
        color: const Color(0xFFFF9900),
        fontWeight: 600,
        size: 64,
        position: const Offset(30, 40),
        rotation: 0.2,
        scale: 1.3,
        backgroundColor: const Color(0x80FFFFFF),
        borderRadius: 16.0,
        padding: 12.0,
        zIndex: 4,
        opacity: 0.8,
        shadowColor: const Color(0x80000000),
        shadowBlurRadius: 6.0,
        shadowOffset: const Offset(1, 2),
        behindFrame: true,
      );
    }

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = buildFull();
      final json = original.toJson();
      final restored = IconOverlay.fromJson(json);

      expect(restored.id, 'icon-1');
      expect(restored.codePoint, 0xe87c);
      expect(restored.fontFamily, 'sficons');
      expect(restored.fontPackage, 'flutter_sficon');
      expect(restored.color, const Color(0xFFFF9900));
      expect(restored.fontWeight, 600);
      expect(restored.size, 64);
      expect(restored.position, const Offset(30, 40));
      expect(restored.rotation, 0.2);
      expect(restored.scale, 1.3);
      expect(restored.backgroundColor, const Color(0x80FFFFFF));
      expect(restored.borderRadius, 16.0);
      expect(restored.padding, 12.0);
      expect(restored.zIndex, 4);
      expect(restored.opacity, 0.8);
      expect(restored.shadowColor, const Color(0x80000000));
      expect(restored.shadowBlurRadius, 6.0);
      expect(restored.shadowOffset, const Offset(1, 2));
      expect(restored.behindFrame, true);
    });

    test('fromJson with minimal data uses defaults', () {
      final restored = IconOverlay.fromJson({
        'id': 'min-1',
        'codePoint': 0xe87c,
      });
      expect(restored.fontFamily, 'MaterialSymbolsRounded');
      expect(restored.fontPackage, 'material_symbols_icons');
      expect(restored.color, Colors.white);
      expect(restored.fontWeight, 400);
      expect(restored.size, 120);
      expect(restored.rotation, 0.0);
      expect(restored.scale, 1.0);
      expect(restored.backgroundColor, isNull);
      expect(restored.borderRadius, 0.0);
      expect(restored.padding, 0.0);
      expect(restored.zIndex, 2);
      expect(restored.opacity, 1.0);
      expect(restored.shadowColor, isNull);
      expect(restored.shadowBlurRadius, 0.0);
      expect(restored.behindFrame, false);
    });

    test('isSFSymbol returns true for sficons family', () {
      final sfIcon = buildFull(); // fontFamily: 'sficons'
      expect(sfIcon.isSFSymbol, true);
    });

    test('isSFSymbol returns false for Material Symbols', () {
      final materialIcon = IconOverlay(
        id: 'mat-1',
        codePoint: 0xe87c,
        fontFamily: 'MaterialSymbolsRounded',
        position: Offset.zero,
      );
      expect(materialIcon.isSFSymbol, false);
    });

    test('copyWith clearBackground sets backgroundColor to null', () {
      final original = buildFull();
      expect(original.backgroundColor, isNotNull);
      final cleared = original.copyWith(clearBackground: true);
      expect(cleared.backgroundColor, isNull);
    });

    test('copyWith clearShadowColor sets shadowColor to null', () {
      final original = buildFull();
      expect(original.shadowColor, isNotNull);
      final cleared = original.copyWith(clearShadowColor: true);
      expect(cleared.shadowColor, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      final original = buildFull();
      final modified = original.copyWith(size: 96);
      expect(modified.size, 96);
      expect(modified.codePoint, original.codePoint);
      expect(modified.fontFamily, original.fontFamily);
    });
  });
}
