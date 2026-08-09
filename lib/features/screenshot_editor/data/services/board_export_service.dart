import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;

/// One exported image and the zone it came from.
class BoardExportImage {
  const BoardExportImage({
    required this.zone,
    required this.index,
    required this.bytes,
  });

  final CropZone zone;

  /// Position of the zone in the board's zone list — used for stable
  /// `screenshot_N.png` filenames and for ordering uploads.
  final int index;

  final Uint8List bytes;

  String get fileName => 'screenshot_${index + 1}.png';
}

/// Result of one board export pass.
class BoardExportResult {
  const BoardExportResult({
    required this.images,
    required this.captureScale,
  });

  final List<BoardExportImage> images;

  /// The scale the board was captured at. Below 1.0 the board exceeded the
  /// single-capture pixel budget and crops were upscaled to their target size,
  /// so the caller should warn the user.
  final double captureScale;

  bool get wasDownscaled => captureScale < 1.0;
}

/// Turns one board capture into the individual screenshots its crop zones
/// describe.
///
/// This is where board mode earns its performance: the multi-artboard editor
/// re-mounts and re-captures the editor canvas once per screenshot, waiting
/// several frames each time for fonts and image decodes to settle. A board is
/// captured **once**, then each zone is copied out of that image on the GPU.
/// Export cost stops scaling with the number of screenshots, and for a
/// locale export it drops from `locales × screenshots` captures to `locales`.
class BoardExportService {
  /// Largest board, in pixels, captured at full scale in a single pass.
  ///
  /// A capture is an RGBA readback, so 80 MP is roughly 320 MB in flight.
  /// Beyond this the board is captured at a reduced scale and crops are
  /// upscaled, which keeps very large boards exporting instead of failing.
  static const int maxSinglePassPixels = 80 * 1000 * 1000;

  /// Scale at which [boardSize] fits within [maxSinglePassPixels]. 1.0 when it
  /// already does.
  static double captureScaleFor(Size boardSize) {
    final pixels = boardSize.width * boardSize.height;
    if (pixels <= maxSinglePassPixels) return 1.0;
    return math.sqrt(maxSinglePassPixels / pixels);
  }

  /// Crops [boardImage] into one PNG per zone in [zones].
  ///
  /// [captureScale] is the scale [boardImage] was captured at; zone rects are
  /// in unscaled board coordinates and are converted internally.
  ///
  /// When [stripAlpha] is true the PNGs are re-encoded without an alpha
  /// channel — App Store Connect rejects screenshots that have one.
  static Future<BoardExportResult> cropZones({
    required ui.Image boardImage,
    required List<CropZone> zones,
    double captureScale = 1.0,
    bool stripAlpha = true,
  }) async {
    final images = <BoardExportImage>[];

    for (var i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final bytes = await _cropOne(
        boardImage: boardImage,
        zone: zone,
        captureScale: captureScale,
      );
      if (bytes == null) continue;

      images.add(
        BoardExportImage(
          zone: zone,
          index: i,
          bytes: stripAlpha ? await compute(_stripAlpha, bytes) : bytes,
        ),
      );
    }

    return BoardExportResult(images: images, captureScale: captureScale);
  }

  /// Copies one zone out of the board image at its target resolution.
  ///
  /// A locked zone's rect already matches its target size, so at capture scale
  /// 1.0 this is a straight blit — no resampling, so the exported pixels are
  /// identical to what was rendered. An unlocked zone (or a downscaled
  /// capture) is scaled to the target size here instead.
  static Future<Uint8List?> _cropOne({
    required ui.Image boardImage,
    required CropZone zone,
    required double captureScale,
  }) async {
    final target = zone.targetSize;
    final width = target.width.round();
    final height = target.height.round();
    if (width <= 0 || height <= 0) return null;

    // Zone rect in captured-image space, clamped to the image so a zone that
    // hangs off the board edge yields transparent padding instead of throwing.
    final src = Rect.fromLTWH(
      zone.position.dx * captureScale,
      zone.position.dy * captureScale,
      zone.size.width * captureScale,
      zone.size.height * captureScale,
    );
    final clamped = src.intersect(
      Rect.fromLTWH(
        0,
        0,
        boardImage.width.toDouble(),
        boardImage.height.toDouble(),
      ),
    );
    if (clamped.isEmpty) return null;

    // Preserve the offset when the zone is partly outside the board so the
    // visible part lands in the right place in the output.
    final dst = Rect.fromLTWH(
      (clamped.left - src.left) / src.width * width,
      (clamped.top - src.top) / src.height * height,
      clamped.width / src.width * width,
      clamped.height / src.height * height,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    canvas.drawImageRect(
      boardImage,
      clamped,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();

    try {
      final cropped = await picture.toImage(width, height);
      try {
        final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        cropped.dispose();
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to crop zone ${zone.id}',
        tag: 'BoardExport',
        error: e,
        stackTrace: st,
      );
      return null;
    } finally {
      picture.dispose();
    }
  }
}

/// Top-level for [compute] — drops the alpha channel from a PNG.
///
/// Mirrors the multi-screenshot editor's own post-processing: App Store
/// Connect rejects screenshots that carry an alpha channel.
Uint8List _stripAlpha(Uint8List bytes) {
  final image = img.decodePng(bytes);
  if (image == null) return bytes;
  return img.encodePng(image.convert(numChannels: 3));
}
