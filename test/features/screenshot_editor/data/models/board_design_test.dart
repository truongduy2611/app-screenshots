import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/frame_element.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CropZone', () {
    test('locked factory sizes the zone to its format', () {
      final zone = CropZone.locked(
        id: 'a',
        position: const Offset(100, 200),
        displayType: 'APP_IPHONE_69',
      );

      expect(zone.size, const Size(1320, 2868));
      expect(zone.locked, isTrue);
      expect(zone.included, isTrue);
      expect(zone.isPixelPerfect, isTrue);
      expect(zone.rect, const Rect.fromLTWH(100, 200, 1320, 2868));
    });

    test('changing the format of a locked zone resizes it', () {
      final zone = CropZone.locked(
        id: 'a',
        position: Offset.zero,
        displayType: 'APP_IPHONE_69',
      ).copyWith(displayType: 'APP_IPHONE_67');

      expect(zone.size, const Size(1290, 2796));
      expect(zone.isPixelPerfect, isTrue);
    });

    test('an unlocked zone keeps its own size and is not pixel-perfect', () {
      final zone = CropZone.locked(
        id: 'a',
        position: Offset.zero,
        displayType: 'APP_IPHONE_69',
      ).copyWith(locked: false).copyWith(size: const Size(900, 1800));

      expect(zone.size, const Size(900, 1800));
      expect(zone.targetSize, const Size(1320, 2868));
      expect(zone.isPixelPerfect, isFalse);
    });

    test('re-locking snaps back to the format size', () {
      final zone = CropZone(
        id: 'a',
        position: Offset.zero,
        size: const Size(900, 1800),
        displayType: 'APP_IPHONE_69',
        locked: false,
      ).copyWith(locked: true);

      expect(zone.size, const Size(1320, 2868));
    });

    test('landscape orientation swaps the target dimensions', () {
      final zone = CropZone.locked(
        id: 'a',
        position: Offset.zero,
        displayType: 'APP_IPHONE_69',
        orientation: Orientation.landscape,
      );

      expect(zone.size, const Size(2868, 1320));
    });

    test('toJson → fromJson round-trip', () {
      final original = CropZone(
        id: 'zone-1',
        name: 'Hero',
        position: const Offset(40, 60),
        size: const Size(800, 1600),
        displayType: 'APP_IPHONE_67',
        locked: false,
        included: false,
      );

      final restored = CropZone.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.name, 'Hero');
      expect(restored.size, const Size(800, 1600));
      expect(restored.included, isFalse);
    });

    test('a locked zone resolves its size from the format on load', () {
      final json = CropZone.locked(
        id: 'zone-1',
        position: Offset.zero,
        displayType: 'APP_IPHONE_69',
      ).toJson();
      // Simulate a stale rect written by an older build.
      json['width'] = 1;
      json['height'] = 1;

      final restored = CropZone.fromJson(json);
      expect(restored.size, const Size(1320, 2868));
    });
  });

  group('FrameElement', () {
    test('toJson → fromJson round-trip preserves device and transform', () {
      final original = FrameElement(
        id: 'frame-1',
        device: Devices.ios.iPhone16ProMax,
        imagePath: '/tmp/shot.png',
        position: const Offset(120, 240),
        size: const Size(600, 1200),
        rotation: 0.2,
        rotationX: 0.1,
        rotationY: -0.1,
        cornerRadius: 48,
        zIndex: 3,
        opacity: 0.9,
        shadowColor: const Color(0x66000000),
        shadowBlurRadius: 24,
        shadowOffset: const Offset(0, 8),
      );

      final restored = FrameElement.fromJson(original.toJson());

      expect(restored, original);
      // TECH_DEBT: DeviceInfo deprecated in device_frame — no replacement API.
      // ignore: deprecated_member_use
      expect(restored.device?.identifier, Devices.ios.iPhone16ProMax.identifier);
      expect(restored.rect, const Rect.fromLTWH(120, 240, 600, 1200));
    });

    test('an unknown device identifier degrades to no frame', () {
      final json = FrameElement(
        id: 'frame-1',
        position: Offset.zero,
        size: const Size(100, 100),
      ).toJson();
      json['device'] = 'not_a_real_device';

      expect(FrameElement.fromJson(json).device, isNull);
    });

    test('clearImage and clearDevice drop their fields', () {
      final frame = FrameElement(
        id: 'frame-1',
        device: Devices.ios.iPhone16,
        imagePath: '/tmp/a.png',
        position: Offset.zero,
        size: const Size(100, 100),
      );

      expect(frame.copyWith(clearImage: true).imagePath, isNull);
      expect(frame.copyWith(clearDevice: true).device, isNull);
    });
  });

  group('BoardDesign', () {
    test('starter lays zones out in a row with frames inside them', () {
      final board = BoardDesign.starter(
        displayType: 'APP_IPHONE_69',
        zoneCount: 3,
      );

      expect(board.cropZones, hasLength(3));
      expect(board.frames, hasLength(3));

      final zoneSize = ScreenshotUtils.getDimensions(
        'APP_IPHONE_69',
        Orientation.portrait,
      );
      // Zones are laid out left to right and never overlap.
      for (var i = 1; i < board.cropZones.length; i++) {
        final previous = board.cropZones[i - 1];
        final current = board.cropZones[i];
        expect(current.position.dx, greaterThan(previous.rect.right));
        expect(current.position.dy, previous.position.dy);
      }
      // The board is wide enough for every zone.
      expect(
        board.size.width,
        greaterThanOrEqualTo(board.cropZones.last.rect.right),
      );
      expect(board.size.height, greaterThanOrEqualTo(zoneSize.height));

      // Each frame sits inside its zone.
      for (var i = 0; i < board.frames.length; i++) {
        expect(board.cropZones[i].rect.overlaps(board.frames[i].rect), isTrue);
      }
    });

    test('exportableZones skips excluded zones', () {
      final board = BoardDesign.starter(
        displayType: 'APP_IPHONE_69',
        zoneCount: 3,
      );
      final updated = board.copyWith(
        cropZones: [
          board.cropZones[0],
          board.cropZones[1].copyWith(included: false),
          board.cropZones[2],
        ],
      );

      expect(updated.exportableZones, hasLength(2));
      expect(updated.exportableZones.map((z) => z.id), isNot(contains(
        board.cropZones[1].id,
      )));
    });

    test('frameAt returns the topmost frame under a point', () {
      final lower = FrameElement(
        id: 'lower',
        position: Offset.zero,
        size: const Size(200, 200),
        zIndex: 0,
      );
      final upper = FrameElement(
        id: 'upper',
        position: const Offset(50, 50),
        size: const Size(200, 200),
        zIndex: 5,
      );
      final board = BoardDesign(
        size: const Size(1000, 1000),
        frames: [lower, upper],
      );

      expect(board.frameAt(const Offset(10, 10))?.id, 'lower');
      expect(board.frameAt(const Offset(100, 100))?.id, 'upper');
      expect(board.frameAt(const Offset(900, 900)), isNull);
    });

    test('contentBounds covers every frame and zone', () {
      final board = BoardDesign(
        size: const Size(100, 100),
        frames: [
          FrameElement(
            id: 'f',
            position: const Offset(10, 10),
            size: const Size(50, 50),
          ),
        ],
        cropZones: [
          CropZone(
            id: 'z',
            position: const Offset(200, 300),
            size: const Size(100, 100),
            displayType: 'APP_IPHONE_69',
            locked: false,
          ),
        ],
      );

      expect(board.contentBounds, const Rect.fromLTRB(10, 10, 300, 400));
    });

    test('toJson → fromJson round-trip preserves the whole board', () {
      final original = BoardDesign(
        size: const Size(5000, 3200),
        background: const ScreenshotDesign(
          backgroundColor: Color(0xFF102030),
          displayType: 'APP_IPHONE_69',
        ),
        frames: [
          FrameElement(
            id: 'frame-1',
            device: Devices.ios.iPhone16,
            position: const Offset(10, 20),
            size: const Size(600, 1200),
          ),
        ],
        cropZones: [
          CropZone.locked(
            id: 'zone-1',
            position: const Offset(160, 160),
            displayType: 'APP_IPHONE_69',
          ),
        ],
      );

      final restored = BoardDesign.fromJson(original.toJson());

      expect(restored.size, original.size);
      expect(restored.frames, original.frames);
      expect(restored.cropZones, original.cropZones);
      expect(
        restored.background.backgroundColor,
        original.background.backgroundColor,
      );
    });
  });

  group('SavedDesign board envelope', () {
    test('isBoard is false for designs without a board', () {
      final design = SavedDesign(
        id: '1',
        name: 'plain',
        lastModified: DateTime(2026, 1, 1),
        thumbnailPath: 'thumb.png',
        design: const ScreenshotDesign(),
      );

      expect(design.isBoard, isFalse);
      expect(SavedDesign.fromJson(design.toJson()).board, isNull);
    });

    test('a board survives a JSON round-trip', () {
      final board = BoardDesign.starter(
        displayType: 'APP_IPHONE_69',
        zoneCount: 2,
      );
      final design = SavedDesign(
        id: '1',
        name: 'board',
        lastModified: DateTime(2026, 1, 1),
        thumbnailPath: 'thumb.png',
        design: board.background,
        board: board,
      );

      final restored = SavedDesign.fromJson(design.toJson());

      expect(restored.isBoard, isTrue);
      expect(restored.board!.cropZones, hasLength(2));
      expect(restored.board!.frames, hasLength(2));
      expect(restored.board!.size, board.size);
    });
  });
}
