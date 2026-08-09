import 'dart:ui' as ui;

import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/board_export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Paints a board-like image: [colors] laid out as equal-width vertical bands.
Future<ui.Image> paintBands(Size size, List<Color> colors) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);
  final bandWidth = size.width / colors.length;
  for (var i = 0; i < colors.length; i++) {
    canvas.drawRect(
      Rect.fromLTWH(i * bandWidth, 0, bandWidth, size.height),
      Paint()..color = colors[i],
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  picture.dispose();
  return image;
}

/// Reads one pixel from a decoded PNG as an ARGB-ish tuple.
({int r, int g, int b}) pixelAt(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return (r: pixel.r.toInt(), g: pixel.g.toInt(), b: pixel.b.toInt());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A board 3 zones wide, each zone 100×200, no gaps — so zone N is band N.
  const zoneSize = Size(100, 200);
  const boardSize = Size(300, 200);
  const bandColors = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
  ];

  List<CropZone> bandZones({bool includeMiddle = true}) => [
    CropZone(
      id: 'z0',
      position: Offset.zero,
      size: zoneSize,
      displayType: 'BAND',
      locked: false,
    ),
    CropZone(
      id: 'z1',
      position: const Offset(100, 0),
      size: zoneSize,
      displayType: 'BAND',
      locked: false,
      included: includeMiddle,
    ),
    CropZone(
      id: 'z2',
      position: const Offset(200, 0),
      size: zoneSize,
      displayType: 'BAND',
      locked: false,
    ),
  ];

  group('BoardExportService.captureScaleFor', () {
    test('a normal board captures at full scale', () {
      expect(BoardExportService.captureScaleFor(const Size(4000, 3000)), 1.0);
    });

    test('an oversized board is scaled down to fit the pixel budget', () {
      // 20000 × 8000 = 160 MP, twice the 80 MP budget.
      final scale = BoardExportService.captureScaleFor(const Size(20000, 8000));

      expect(scale, lessThan(1.0));
      final scaledPixels = 20000 * scale * 8000 * scale;
      expect(
        scaledPixels,
        lessThanOrEqualTo(BoardExportService.maxSinglePassPixels + 1),
      );
    });
  });

  group('BoardExportService.cropZones', () {
    test('produces one image per zone, in order', () async {
      final board = await paintBands(boardSize, bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: bandZones(),
        stripAlpha: false,
      );

      expect(result.images, hasLength(3));
      expect(result.images.map((i) => i.index), [0, 1, 2]);
      expect(result.images.map((i) => i.fileName), [
        'screenshot_1.png',
        'screenshot_2.png',
        'screenshot_3.png',
      ]);
      expect(result.wasDownscaled, isFalse);
    });

    test('each crop carries exactly its own region of the board', () async {
      final board = await paintBands(boardSize, bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: bandZones(),
        stripAlpha: false,
      );

      // Target size for the unknown display type falls back to the default,
      // so sample proportionally rather than at fixed coordinates.
      for (var i = 0; i < result.images.length; i++) {
        final decoded = img.decodePng(result.images[i].bytes)!;
        final centre = pixelAt(
          decoded,
          decoded.width ~/ 2,
          decoded.height ~/ 2,
        );
        final expected = bandColors[i];
        expect(
          centre,
          (
            r: (expected.r * 255).round(),
            g: (expected.g * 255).round(),
            b: (expected.b * 255).round(),
          ),
          reason: 'zone $i should contain only its own band',
        );
      }
    });

    test('a zone hanging off the board edge still exports', () async {
      final board = await paintBands(boardSize, bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: [
          CropZone(
            id: 'edge',
            // Half of this zone is past the right edge of the board.
            position: const Offset(250, 0),
            size: zoneSize,
            displayType: 'BAND',
            locked: false,
          ),
        ],
        stripAlpha: false,
      );

      expect(result.images, hasLength(1));
      final decoded = img.decodePng(result.images.first.bytes)!;
      // The in-bounds half carries the last band's colour.
      final inBounds = pixelAt(decoded, decoded.width ~/ 4, decoded.height ~/ 2);
      expect(inBounds, (r: 0, g: 0, b: 255));
    });

    test('a zone entirely outside the board is skipped', () async {
      final board = await paintBands(boardSize, bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: [
          CropZone(
            id: 'gone',
            position: const Offset(5000, 5000),
            size: zoneSize,
            displayType: 'BAND',
            locked: false,
          ),
        ],
        stripAlpha: false,
      );

      expect(result.images, isEmpty);
    });

    test('an empty zone list yields no images rather than failing', () async {
      final board = await paintBands(boardSize, bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: const [],
      );

      expect(result.images, isEmpty);
      expect(result.captureScale, 1.0);
    });

    test('stripAlpha drops the alpha channel', () async {
      final board = await paintBands(boardSize, bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: [bandZones().first],
      );

      final decoded = img.decodePng(result.images.first.bytes)!;
      expect(decoded.numChannels, 3);
    });

    test('a downscaled capture is reported so callers can warn', () async {
      final board = await paintBands(const Size(150, 100), bandColors);
      addTearDown(board.dispose);

      final result = await BoardExportService.cropZones(
        boardImage: board,
        zones: [bandZones().first],
        // The board was captured at half scale.
        captureScale: 0.5,
        stripAlpha: false,
      );

      expect(result.wasDownscaled, isTrue);
      expect(result.images, hasLength(1));
      // Still the first band's colour — the zone rect is in unscaled board
      // coordinates and converted internally.
      final decoded = img.decodePng(result.images.first.bytes)!;
      final centre = pixelAt(decoded, decoded.width ~/ 2, decoded.height ~/ 2);
      expect(centre, (r: 255, g: 0, b: 0));
    });
  });
}
