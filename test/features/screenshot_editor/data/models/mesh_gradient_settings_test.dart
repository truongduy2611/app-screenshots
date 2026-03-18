// TECH_DEBT: Color.value deprecated in Flutter 3.27
// ignore_for_file: deprecated_member_use
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshGradientSettings', () {
    MeshGradientSettings buildFull() {
      return const MeshGradientSettings(
        points: [
          MeshPoint(position: Offset(0.0, 0.0), color: Color(0xFFFF0000)),
          MeshPoint(position: Offset(1.0, 0.0), color: Color(0xFF00FF00)),
          MeshPoint(position: Offset(0.0, 1.0), color: Color(0xFF0000FF)),
          MeshPoint(position: Offset(1.0, 1.0), color: Color(0xFFFFFF00)),
        ],
        blend: 5.0,
        noiseIntensity: 0.3,
      );
    }

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = buildFull();
      final json = original.toJson();
      final restored = MeshGradientSettings.fromJson(json);

      expect(restored.points.length, 4);
      expect(restored.blend, 5.0);
      expect(restored.noiseIntensity, 0.3);

      // Check first point
      expect(restored.points[0].position, const Offset(0.0, 0.0));
      expect(restored.points[0].color, const Color(0xFFFF0000));

      // Check last point
      expect(restored.points[3].position, const Offset(1.0, 1.0));
      expect(restored.points[3].color, const Color(0xFFFFFF00));
    });

    test('fromJson with missing blend/noise uses defaults', () {
      final restored = MeshGradientSettings.fromJson({
        'points': [
          {'x': 0.5, 'y': 0.5, 'color': 0xFFFF0000},
        ],
      });
      expect(restored.blend, 3.0);
      expect(restored.noiseIntensity, 0.0);
    });

    test('copyWith updates specified fields', () {
      final original = buildFull();
      final modified = original.copyWith(blend: 8.0);
      expect(modified.blend, 8.0);
      expect(modified.noiseIntensity, original.noiseIntensity);
      expect(modified.points.length, original.points.length);
    });
  });

  group('MeshPoint', () {
    test('toJson → fromJson round-trip preserves fields', () {
      const original = MeshPoint(
        position: Offset(0.3, 0.7),
        color: Color(0xFFABCDEF),
      );
      final json = original.toJson();
      final restored = MeshPoint.fromJson(json);

      expect(restored.position.dx, closeTo(0.3, 0.001));
      expect(restored.position.dy, closeTo(0.7, 0.001));
      expect(restored.color, const Color(0xFFABCDEF));
    });

    test('copyWith updates specified fields', () {
      const original = MeshPoint(
        position: Offset(0.5, 0.5),
        color: Color(0xFFFF0000),
      );
      final modified = original.copyWith(color: const Color(0xFF00FF00));
      expect(modified.color, const Color(0xFF00FF00));
      expect(modified.position, original.position);
    });
  });
}
