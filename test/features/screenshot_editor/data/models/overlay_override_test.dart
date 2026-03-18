import 'dart:ui';

import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverlayOverride', () {
    OverlayOverride buildFull() {
      return const OverlayOverride(
        position: Offset(10, 20),
        width: 300,
        scale: 1.5,
        fontSize: 24,
        rotation: 0.5,
        fontWeightIndex: 6, // w700
        fontStyleIndex: 1, // italic
        textAlignIndex: 2, // right
        googleFont: 'Roboto',
        color: 0xFFFF0000,
        backgroundColor: 0x80000000,
        borderColor: 0xFF00FF00,
        decorationColor: 0xFF0000FF,
        borderWidth: 2.0,
        borderRadius: 8.0,
        horizontalPadding: 12.0,
        verticalPadding: 16.0,
        decoration: 'TextDecoration.underline',
        decorationStyleIndex: 1, // double
      );
    }

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = buildFull();
      final json = original.toJson();
      final restored = OverlayOverride.fromJson(json);

      expect(restored.position, const Offset(10, 20));
      expect(restored.width, 300);
      expect(restored.scale, 1.5);
      expect(restored.fontSize, 24);
      expect(restored.rotation, 0.5);
      expect(restored.fontWeightIndex, 6);
      expect(restored.fontStyleIndex, 1);
      expect(restored.textAlignIndex, 2);
      expect(restored.googleFont, 'Roboto');
      expect(restored.color, 0xFFFF0000);
      expect(restored.backgroundColor, 0x80000000);
      expect(restored.borderColor, 0xFF00FF00);
      expect(restored.decorationColor, 0xFF0000FF);
      expect(restored.borderWidth, 2.0);
      expect(restored.borderRadius, 8.0);
      expect(restored.horizontalPadding, 12.0);
      expect(restored.verticalPadding, 16.0);
      expect(restored.decoration, 'TextDecoration.underline');
      expect(restored.decorationStyleIndex, 1);
    });

    test('toJson only includes non-null fields (sparse serialization)', () {
      const override = OverlayOverride(fontSize: 18);
      final json = override.toJson();
      expect(json.keys, contains('fontSize'));
      expect(json.keys, isNot(contains('width')));
      expect(json.keys, isNot(contains('scale')));
      expect(json.keys, isNot(contains('googleFont')));
    });

    test('fromJson with empty map returns all-null override', () {
      final restored = OverlayOverride.fromJson({});
      expect(restored.isEmpty, true);
      expect(restored.position, isNull);
      expect(restored.width, isNull);
      expect(restored.fontSize, isNull);
      expect(restored.googleFont, isNull);
    });

    group('isEmpty', () {
      test('returns true for const default', () {
        expect(const OverlayOverride().isEmpty, true);
      });

      test('returns false when any field is set', () {
        expect(const OverlayOverride(fontSize: 18).isEmpty, false);
        expect(const OverlayOverride(scale: 1.0).isEmpty, false);
        expect(const OverlayOverride(position: Offset(0, 0)).isEmpty, false);
      });
    });

    group('merge', () {
      test('non-null values in other win', () {
        const base = OverlayOverride(fontSize: 18, scale: 1.0);
        const other = OverlayOverride(fontSize: 24, width: 200);
        final merged = base.merge(other);

        expect(merged.fontSize, 24); // overridden
        expect(merged.scale, 1.0); // kept from base
        expect(merged.width, 200); // added from other
      });

      test('merge with empty keeps all base values', () {
        final full = buildFull();
        const empty = OverlayOverride();
        final merged = full.merge(empty);

        expect(merged.fontSize, full.fontSize);
        expect(merged.scale, full.scale);
        expect(merged.position, full.position);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final full = buildFull();
        final updated = full.copyWith(fontSize: 32);
        expect(updated.fontSize, 32);
        expect(updated.scale, full.scale);
      });

      test('clear flags set fields to null', () {
        final full = buildFull();
        final cleared = full.copyWith(
          clearFontSize: true,
          clearPosition: true,
          clearGoogleFont: true,
        );
        expect(cleared.fontSize, isNull);
        expect(cleared.position, isNull);
        expect(cleared.googleFont, isNull);
        expect(cleared.scale, full.scale); // not cleared
      });
    });

    group('convenience getters', () {
      test('fontWeight resolves correctly', () {
        const o = OverlayOverride(fontWeightIndex: 6);
        expect(o.fontWeight, FontWeight.w700);
      });

      test('fontWeight returns null when not set', () {
        const o = OverlayOverride();
        expect(o.fontWeight, isNull);
      });

      test('fontWeight clamps out-of-range index', () {
        const o = OverlayOverride(fontWeightIndex: 99);
        expect(o.fontWeight, FontWeight.w900); // clamped to 8
      });

      test('fontStyle resolves correctly', () {
        const o = OverlayOverride(fontStyleIndex: 1);
        expect(o.fontStyle, FontStyle.italic);
      });

      test('fontStyle returns null when not set', () {
        const o = OverlayOverride();
        expect(o.fontStyle, isNull);
      });

      test('textAlign resolves correctly', () {
        const o = OverlayOverride(textAlignIndex: 1);
        expect(o.textAlign, TextAlign.right);
      });

      test('textDecoration resolves all variants', () {
        expect(
          const OverlayOverride(
            decoration: 'TextDecoration.underline',
          ).textDecoration,
          TextDecoration.underline,
        );
        expect(
          const OverlayOverride(
            decoration: 'TextDecoration.overline',
          ).textDecoration,
          TextDecoration.overline,
        );
        expect(
          const OverlayOverride(
            decoration: 'TextDecoration.lineThrough',
          ).textDecoration,
          TextDecoration.lineThrough,
        );
        expect(
          const OverlayOverride(
            decoration: 'TextDecoration.none',
          ).textDecoration,
          TextDecoration.none,
        );
        expect(
          const OverlayOverride(decoration: 'unknown').textDecoration,
          isNull,
        );
      });

      test('textDecorationStyle resolves correctly', () {
        const o = OverlayOverride(decorationStyleIndex: 1);
        expect(o.textDecorationStyle, TextDecorationStyle.double);
      });
    });

    test('Equatable comparison', () {
      const a = OverlayOverride(fontSize: 18, scale: 1.0);
      const b = OverlayOverride(fontSize: 18, scale: 1.0);
      const c = OverlayOverride(fontSize: 20, scale: 1.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
