import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/crop_zone_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Crop zone outlines are rounded only on edges facing open canvas. At zero
/// spacing the zones form one continuous strip, and rounding the inner edges
/// would draw seams through the middle of an image meant to read as unbroken.
void main() {
  const r = Radius.circular(CropZoneLayer.cornerRadius);

  CropZone zoneAt(String id, double x, {double width = 100, double y = 0}) {
    return CropZone(
      id: id,
      position: Offset(x, y),
      size: Size(width, 200),
      displayType: 'APP_IPHONE_69',
      locked: false,
    );
  }

  group('CropZoneLayer.radiusFor', () {
    test('a lone zone is rounded on both sides', () {
      final zone = zoneAt('a', 0);
      expect(
        CropZoneLayer.radiusFor([zone], zone),
        const BorderRadius.horizontal(left: r, right: r),
      );
    });

    test('spaced zones stay rounded on both sides', () {
      final zones = [zoneAt('a', 0), zoneAt('b', 150)];
      for (final zone in zones) {
        expect(
          CropZoneLayer.radiusFor(zones, zone),
          const BorderRadius.horizontal(left: r, right: r),
          reason: '${zone.id} should be fully rounded when gaps exist',
        );
      }
    });

    test('a butted-together run rounds only its outer ends', () {
      // Three zones edge to edge: 0..100, 100..200, 200..300.
      final zones = [zoneAt('a', 0), zoneAt('b', 100), zoneAt('c', 200)];

      expect(
        CropZoneLayer.radiusFor(zones, zones[0]),
        const BorderRadius.horizontal(left: r, right: Radius.zero),
      );
      expect(
        CropZoneLayer.radiusFor(zones, zones[1]),
        BorderRadius.zero,
        reason: 'a zone with neighbours on both sides has no rounded corner',
      );
      expect(
        CropZoneLayer.radiusFor(zones, zones[2]),
        const BorderRadius.horizontal(left: Radius.zero, right: r),
      );
    });

    test('a zone on another row is not treated as a neighbour', () {
      // Touching horizontally, but stacked far below with no vertical overlap.
      final a = zoneAt('a', 0);
      final b = zoneAt('b', 100, y: 1000);

      expect(
        CropZoneLayer.radiusFor([a, b], a),
        const BorderRadius.horizontal(left: r, right: r),
      );
    });

    test('sub-pixel drift still counts as touching', () {
      // Arranging accumulates floating-point error, so an exact match cannot
      // be relied on for the seam test.
      final zones = [zoneAt('a', 0), zoneAt('b', 100.4)];

      expect(
        CropZoneLayer.radiusFor(zones, zones[0]).topRight,
        Radius.zero,
      );
    });
  });
}
