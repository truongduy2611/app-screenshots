// TECH_DEBT: Color.value deprecated in Flutter 3.27
// ignore_for_file: deprecated_member_use
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageOverlay', () {
    ImageOverlay buildFull() {
      return ImageOverlay(
        id: 'img-1',
        assetPath: 'assets/star.png',
        filePath: '/tmp/user_image.png',
        position: const Offset(50, 60),
        scale: 2.0,
        rotation: 0.3,
        width: 250,
        height: 180,
        zIndex: 3,
        opacity: 0.9,
        cornerRadius: 12.0,
        flipHorizontal: true,
        flipVertical: true,
        shadowColor: const Color(0x80000000),
        shadowBlurRadius: 10.0,
        shadowOffset: const Offset(2, 4),
        behindFrame: true,
      );
    }

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = buildFull();
      final json = original.toJson();
      final restored = ImageOverlay.fromJson(json);

      expect(restored.id, 'img-1');
      expect(restored.assetPath, 'assets/star.png');
      expect(restored.filePath, '/tmp/user_image.png');
      expect(restored.position, const Offset(50, 60));
      expect(restored.scale, 2.0);
      expect(restored.rotation, 0.3);
      expect(restored.width, 250);
      expect(restored.height, 180);
      expect(restored.zIndex, 3);
      expect(restored.opacity, 0.9);
      expect(restored.cornerRadius, 12.0);
      expect(restored.flipHorizontal, true);
      expect(restored.flipVertical, true);
      expect(restored.shadowColor, const Color(0x80000000));
      expect(restored.shadowBlurRadius, 10.0);
      expect(restored.shadowOffset, const Offset(2, 4));
      expect(restored.behindFrame, true);
    });

    test('fromJson with minimal data uses defaults', () {
      final restored = ImageOverlay.fromJson({
        'id': 'min-1',
      });
      expect(restored.id, 'min-1');
      expect(restored.position, Offset.zero);
      expect(restored.scale, 1.0);
      expect(restored.rotation, 0.0);
      expect(restored.width, 100.0);
      expect(restored.height, 100.0);
      expect(restored.zIndex, 0);
      expect(restored.opacity, 1.0);
      expect(restored.cornerRadius, 0.0);
      expect(restored.flipHorizontal, false);
      expect(restored.flipVertical, false);
      expect(restored.shadowColor, isNull);
      expect(restored.shadowBlurRadius, 0.0);
      expect(restored.behindFrame, false);
    });

    test('copyWith preserves unmodified fields', () {
      final original = buildFull();
      final modified = original.copyWith(opacity: 0.5);
      expect(modified.opacity, 0.5);
      expect(modified.width, original.width);
      expect(modified.shadowColor, original.shadowColor);
    });

    test('copyWith clearShadowColor sets shadow to null', () {
      final original = buildFull();
      expect(original.shadowColor, isNotNull);
      final cleared = original.copyWith(clearShadowColor: true);
      expect(cleared.shadowColor, isNull);
    });

    test('null shadow color serializes and deserializes correctly', () {
      final overlay = ImageOverlay(
        id: 'no-shadow',
        position: Offset.zero,
      );
      final json = overlay.toJson();
      final restored = ImageOverlay.fromJson(json);
      expect(restored.shadowColor, isNull);
    });
  });
}
