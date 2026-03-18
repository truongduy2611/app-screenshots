// TECH_DEBT: Color.value deprecated in Flutter 3.27
// ignore_for_file: deprecated_member_use
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MagnifierOverlay', () {
    MagnifierOverlay buildFull() {
      return const MagnifierOverlay(
        id: 'mag-1',
        position: Offset(100, 150),
        width: 200,
        height: 180,
        zoomLevel: 3.0,
        sourceOffset: Offset(5, -10),
        borderWidth: 4.0,
        borderColor: Color(0xFF00FF00),
        opacity: 0.9,
        zIndex: 5,
        behindFrame: true,
        shadowColor: Color(0x80000000),
        shadowBlurRadius: 12.0,
        shape: MagnifierShape.roundedRectangle,
        cornerRadius: 16.0,
        starPoints: 6,
      );
    }

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = buildFull();
      final json = original.toJson();
      final restored = MagnifierOverlay.fromJson(json);

      expect(restored.id, 'mag-1');
      expect(restored.position, const Offset(100, 150));
      expect(restored.width, 200);
      expect(restored.height, 180);
      expect(restored.zoomLevel, 3.0);
      expect(restored.sourceOffset, const Offset(5, -10));
      expect(restored.borderWidth, 4.0);
      expect(restored.borderColor, const Color(0xFF00FF00));
      expect(restored.opacity, 0.9);
      expect(restored.zIndex, 5);
      expect(restored.behindFrame, true);
      expect(restored.shadowColor, const Color(0x80000000));
      expect(restored.shadowBlurRadius, 12.0);
      expect(restored.shape, MagnifierShape.roundedRectangle);
      expect(restored.cornerRadius, 16.0);
      expect(restored.starPoints, 6);
    });

    test('fromJson with minimal data uses defaults', () {
      final restored = MagnifierOverlay.fromJson({'id': 'min-1'});
      expect(restored.width, 150);
      expect(restored.height, 150);
      expect(restored.zoomLevel, 2.0);
      expect(restored.sourceOffset, Offset.zero);
      expect(restored.borderWidth, 3.0);
      expect(restored.opacity, 1.0);
      expect(restored.zIndex, 0);
      expect(restored.behindFrame, false);
      expect(restored.shadowColor, isNull);
      expect(restored.shadowBlurRadius, 8.0);
      expect(restored.shape, MagnifierShape.circle);
      expect(restored.cornerRadius, 20.0);
      expect(restored.starPoints, 5);
    });

    test('legacy size field migration', () {
      final restored = MagnifierOverlay.fromJson({
        'id': 'legacy-1',
        'size': 200.0,
        'aspectRatio': 1.0,
      });
      // width comes from 'size' when 'width' is absent
      expect(restored.width, 200.0);
      // height = size / aspectRatio
      expect(restored.height, 200.0);
    });

    test('legacy size with non-1 aspect ratio', () {
      final restored = MagnifierOverlay.fromJson({
        'id': 'legacy-2',
        'size': 200.0,
        'aspectRatio': 2.0,
      });
      expect(restored.width, 200.0);
      expect(restored.height, 100.0); // 200 / 2.0
    });

    test('width/height override legacy size', () {
      final restored = MagnifierOverlay.fromJson({
        'id': 'override-1',
        'size': 200.0,
        'width': 300.0,
        'height': 250.0,
      });
      expect(restored.width, 300.0);
      expect(restored.height, 250.0);
    });

    test('all MagnifierShape values round-trip correctly', () {
      for (final shape in MagnifierShape.values) {
        final overlay = MagnifierOverlay(
          id: 'shape-test',
          position: Offset.zero,
          shape: shape,
        );
        final json = overlay.toJson();
        final restored = MagnifierOverlay.fromJson(json);
        expect(restored.shape, shape);
      }
    });

    test('unknown shape name defaults to circle', () {
      final restored = MagnifierOverlay.fromJson({
        'id': 'unknown-shape',
        'shape': 'nonexistent_shape',
      });
      expect(restored.shape, MagnifierShape.circle);
    });

    test('copyWith preserves unmodified fields', () {
      final original = buildFull();
      final modified = original.copyWith(zoomLevel: 5.0);
      expect(modified.zoomLevel, 5.0);
      expect(modified.width, original.width);
      expect(modified.shape, original.shape);
    });

    test('copyWith clearShadowColor sets shadow to null', () {
      final original = buildFull();
      expect(original.shadowColor, isNotNull);
      final cleared = original.copyWith(clearShadowColor: true);
      expect(cleared.shadowColor, isNull);
    });
  });
}
