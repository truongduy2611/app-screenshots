// TECH_DEBT: Color.value deprecated in Flutter 3.27 — used by device_frame package internals
// ignore_for_file: deprecated_member_use
import 'dart:math' as math;

import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenshotDesign', () {
    test('default constructor has expected field values', () {
      const design = ScreenshotDesign();
      expect(design.backgroundColor, const Color(0xDD000000));
      expect(design.backgroundGradient, isNull);
      expect(design.deviceFrame, isNull);
      expect(design.overlays, isEmpty);
      expect(design.imageOverlays, isEmpty);
      expect(design.iconOverlays, isEmpty);
      expect(design.magnifierOverlays, isEmpty);
      expect(design.padding, 32.0);
      expect(design.imagePosition, Offset.zero);
      expect(design.displayType, isNull);
      expect(design.orientation, Orientation.portrait);
      expect(design.frameRotationX, 0.0);
      expect(design.frameRotationY, 0.0);
      expect(design.frameRotation, 0.0);
      expect(design.cornerRadius, 0.0);
      expect(design.doodleSettings, isNull);
      expect(design.transparentBackground, false);
      expect(design.meshGradient, isNull);
    });

    test('toJson → fromJson round-trip preserves basic fields', () {
      const original = ScreenshotDesign(
        backgroundColor: Color(0xFF112233),
        padding: 16.0,
        imagePosition: Offset(10, 20),
        displayType: 'iphone_16_pro',
        orientation: Orientation.landscape,
        frameRotationX: 0.1,
        frameRotationY: 0.2,
        frameRotation: 0.3,
        cornerRadius: 12.0,
        transparentBackground: true,
      );

      final json = original.toJson();
      final restored = ScreenshotDesign.fromJson(json);

      expect(restored.backgroundColor, original.backgroundColor);
      expect(restored.padding, original.padding);
      expect(restored.imagePosition, original.imagePosition);
      expect(restored.displayType, original.displayType);
      expect(restored.orientation, original.orientation);
      expect(restored.frameRotationX, original.frameRotationX);
      expect(restored.frameRotationY, original.frameRotationY);
      expect(restored.frameRotation, original.frameRotation);
      expect(restored.cornerRadius, original.cornerRadius);
      expect(restored.transparentBackground, original.transparentBackground);
    });

    test('fromJson with missing fields uses defaults', () {
      final restored = ScreenshotDesign.fromJson({});
      expect(restored.padding, 32.0);
      expect(restored.imagePosition, Offset.zero);
      expect(restored.orientation, Orientation.portrait);
      expect(restored.frameRotationX, 0.0);
      expect(restored.overlays, isEmpty);
      expect(restored.imageOverlays, isEmpty);
      expect(restored.cornerRadius, 0.0);
      expect(restored.transparentBackground, false);
    });

    test('copyWith preserves unmodified fields and applies new values', () {
      const original = ScreenshotDesign(
        padding: 16.0,
        cornerRadius: 8.0,
      );

      final modified = original.copyWith(padding: 24.0);
      expect(modified.padding, 24.0);
      expect(modified.cornerRadius, 8.0); // unchanged
    });

    test('copyWith clearGradient sets gradient to null', () {
      final original = ScreenshotDesign(
        backgroundGradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
      );

      final cleared = original.copyWith(clearGradient: true);
      expect(cleared.backgroundGradient, isNull);
    });

    test('copyWith clearDeviceFrame sets deviceFrame to null', () {
      final original = ScreenshotDesign(
        deviceFrame: Devices.all.first,
      );

      final cleared = original.copyWith(clearDeviceFrame: true);
      expect(cleared.deviceFrame, isNull);
    });

    group('gradient JSON round-trip', () {
      test('LinearGradient', () {
        final original = ScreenshotDesign(
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFF0000FF)],
            stops: [0.0, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );

        final json = original.toJson();
        final restored = ScreenshotDesign.fromJson(json);

        expect(restored.backgroundGradient, isA<LinearGradient>());
        final gradient = restored.backgroundGradient as LinearGradient;
        expect(gradient.colors.length, 2);
        expect(gradient.stops, [0.0, 1.0]);
      });

      test('RadialGradient', () {
        final original = ScreenshotDesign(
          backgroundGradient: const RadialGradient(
            colors: [Color(0xFFFF0000), Color(0xFF00FF00)],
            stops: [0.0, 1.0],
            center: Alignment.center,
            radius: 0.8,
          ),
        );

        final json = original.toJson();
        final restored = ScreenshotDesign.fromJson(json);

        expect(restored.backgroundGradient, isA<RadialGradient>());
        final gradient = restored.backgroundGradient as RadialGradient;
        expect(gradient.radius, 0.8);
      });

      test('SweepGradient', () {
        final original = ScreenshotDesign(
          backgroundGradient: SweepGradient(
            colors: const [Color(0xFFFF0000), Color(0xFF00FF00)],
            startAngle: 0.0,
            endAngle: math.pi * 2,
          ),
        );

        final json = original.toJson();
        final restored = ScreenshotDesign.fromJson(json);

        expect(restored.backgroundGradient, isA<SweepGradient>());
      });
    });

    test('known device frame round-trips through name', () {
      final original = ScreenshotDesign(
        deviceFrame: Devices.all.first,
      );

      final json = original.toJson();
      final restored = ScreenshotDesign.fromJson(json);

      expect(restored.deviceFrame, isNotNull);
      expect(restored.deviceFrame!.name, Devices.all.first.name);
    });

    test('unknown device frame name returns null', () {
      final restored = ScreenshotDesign.fromJson({
        'deviceFrame': 'nonexistent_device_xyz',
      });
      expect(restored.deviceFrame, isNull);
    });

    test('toJson → fromJson round-trip with text overlays', () {
      final original = ScreenshotDesign(
        overlays: [
          TextOverlay(
            id: 'text-1',
            text: 'Hello World',
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
            ),
            position: const Offset(100, 200),
          ),
        ],
      );

      final json = original.toJson();
      final restored = ScreenshotDesign.fromJson(json);

      expect(restored.overlays.length, 1);
      expect(restored.overlays[0].text, 'Hello World');
      expect(restored.overlays[0].style.fontSize, 24);
    });

    test('toJson → fromJson round-trip with image overlays', () {
      final original = ScreenshotDesign(
        imageOverlays: [
          ImageOverlay(
            id: 'img-1',
            position: const Offset(50, 50),
            width: 200,
            height: 150,
            opacity: 0.8,
          ),
        ],
      );

      final json = original.toJson();
      final restored = ScreenshotDesign.fromJson(json);

      expect(restored.imageOverlays.length, 1);
      expect(restored.imageOverlays[0].width, 200);
      expect(restored.imageOverlays[0].opacity, 0.8);
    });

    test('toJson → fromJson round-trip with icon overlays', () {
      final original = ScreenshotDesign(
        iconOverlays: [
          IconOverlay(
            id: 'icon-1',
            codePoint: 0xe87c,
            position: const Offset(30, 40),
            size: 48,
          ),
        ],
      );

      final json = original.toJson();
      final restored = ScreenshotDesign.fromJson(json);

      expect(restored.iconOverlays.length, 1);
      expect(restored.iconOverlays[0].codePoint, 0xe87c);
      expect(restored.iconOverlays[0].size, 48);
    });

    test('toJson → fromJson round-trip with magnifier overlays', () {
      final original = ScreenshotDesign(
        magnifierOverlays: [
          MagnifierOverlay(
            id: 'mag-1',
            position: const Offset(60, 70),
            width: 200,
            height: 200,
            zoomLevel: 3.0,
          ),
        ],
      );

      final json = original.toJson();
      final restored = ScreenshotDesign.fromJson(json);

      expect(restored.magnifierOverlays.length, 1);
      expect(restored.magnifierOverlays[0].zoomLevel, 3.0);
    });
  });
}
