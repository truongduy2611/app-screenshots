import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../utils/screenshot_utils.dart';
import 'crop_zone.dart';
import 'frame_element.dart';
import 'screenshot_design.dart';

/// A single large canvas holding many device frames, decorations, and the
/// export regions ([CropZone]) that slice it into individual screenshots.
///
/// ## Why the background is a [ScreenshotDesign]
///
/// A board's background layers (color, gradient, mesh, doodle, grid) and its
/// decorations (text / image / icon / magnifier overlays, positioned in canvas
/// coordinates) are exactly what [ScreenshotDesign] already models. Reusing it
/// verbatim means every existing control panel and overlay widget works on a
/// board unchanged — only the frame list and crop zones are new.
///
/// The frame-specific fields of that [ScreenshotDesign] (`deviceFrame`,
/// `imagePosition`, `padding`) are unused here: a board's frames live in
/// [frames] instead, so there can be more than one.
class BoardDesign {
  static const _uuid = Uuid();

  /// Gap between auto-laid-out crop zones, in board pixels.
  static const double defaultZoneGap = 120.0;

  /// Margin around the auto-laid-out zone strip, in board pixels.
  static const double defaultBoardMargin = 160.0;

  /// Most screenshots App Store Connect accepts per display type. Each crop
  /// zone exports one screenshot, so this caps the zone count.
  static const int maxZones = 10;

  /// Most screenshots Google Play accepts per type — lower than Apple's, so a
  /// board between the two limits still uploads to the App Store but has to be
  /// trimmed for Play. Surfaced as a warning rather than a hard cap, since a
  /// board is often iOS-only.
  static const int maxPlayZones = 8;

  /// Whether another crop zone can be added.
  bool get canAddZone => cropZones.length < maxZones;

  /// Whether the zone count exceeds what Google Play will accept.
  bool get exceedsPlayLimit => exportableZones.length > maxPlayZones;

  /// Board canvas size in pixels. Crop zone rects are in this coordinate space.
  final Size size;

  /// Background layers + decorations. See the class doc for why this is a
  /// [ScreenshotDesign].
  final ScreenshotDesign background;

  /// Device frames placed on the board.
  final List<FrameElement> frames;

  /// Export regions, in board coordinates.
  final List<CropZone> cropZones;

  /// Gap between zones when they are laid out, in board pixels.
  ///
  /// Zero butts the zones edge to edge, so a background, gradient, or image
  /// spanning the board continues unbroken from one exported screenshot into
  /// the next — the panorama layout App Store listings use.
  final double zoneGap;

  const BoardDesign({
    required this.size,
    this.background = const ScreenshotDesign(),
    this.frames = const [],
    this.cropZones = const [],
    this.zoneGap = defaultZoneGap,
  });

  /// Builds a starter board: [zoneCount] zones of [displayType] laid out in a
  /// row, each with a device frame centred inside it.
  factory BoardDesign.starter({
    required String displayType,
    int zoneCount = 3,
    Orientation orientation = Orientation.portrait,
    double gap = defaultZoneGap,
    double margin = defaultBoardMargin,
  }) {
    // A starter board can never open already over the store limit.
    zoneCount = zoneCount.clamp(1, maxZones);

    final zoneSize = ScreenshotUtils.getDimensions(displayType, orientation);
    final device = ScreenshotUtils.getDefaultDeviceFrame(displayType);

    final boardWidth =
        margin * 2 + zoneSize.width * zoneCount + gap * (zoneCount - 1);
    final boardHeight = margin * 2 + zoneSize.height;

    final zones = <CropZone>[];
    final frames = <FrameElement>[];

    for (var i = 0; i < zoneCount; i++) {
      final left = margin + i * (zoneSize.width + gap);
      zones.add(
        CropZone.locked(
          id: _uuid.v4(),
          position: Offset(left, margin),
          displayType: displayType,
          orientation: orientation,
        ),
      );

      // Frame inset inside its zone, matching the single-canvas default of a
      // comfortable margin around the device.
      final frameWidth = zoneSize.width * 0.7;
      final frameHeight = zoneSize.height * 0.7;
      frames.add(
        FrameElement(
          id: _uuid.v4(),
          device: device,
          orientation: orientation,
          position: Offset(
            left + (zoneSize.width - frameWidth) / 2,
            margin + zoneSize.height - frameHeight,
          ),
          size: Size(frameWidth, frameHeight),
          zIndex: i,
        ),
      );
    }

    return BoardDesign(
      size: Size(boardWidth, boardHeight),
      background: ScreenshotDesign(displayType: displayType),
      frames: frames,
      cropZones: zones,
      zoneGap: gap,
    );
  }

  /// The zones that "export all" and upload flows produce images for.
  List<CropZone> get exportableZones =>
      cropZones.where((z) => z.included).toList();

  /// Total pixels the board occupies when captured at 1:1.
  double get pixelCount => size.width * size.height;

  FrameElement? frameById(String id) {
    for (final frame in frames) {
      if (frame.id == id) return frame;
    }
    return null;
  }

  CropZone? zoneById(String id) {
    for (final zone in cropZones) {
      if (zone.id == id) return zone;
    }
    return null;
  }

  /// The topmost frame whose rect contains [point], or `null`.
  FrameElement? frameAt(Offset point) {
    FrameElement? hit;
    for (final frame in frames) {
      if (frame.rect.contains(point)) {
        if (hit == null || frame.zIndex >= hit.zIndex) hit = frame;
      }
    }
    return hit;
  }

  /// Bounding box of every frame and zone, useful for zoom-to-fit.
  Rect get contentBounds {
    Rect? bounds;
    for (final frame in frames) {
      bounds = bounds == null ? frame.rect : bounds.expandToInclude(frame.rect);
    }
    for (final zone in cropZones) {
      bounds = bounds == null ? zone.rect : bounds.expandToInclude(zone.rect);
    }
    return bounds ?? (Offset.zero & size);
  }

  BoardDesign copyWith({
    Size? size,
    ScreenshotDesign? background,
    List<FrameElement>? frames,
    List<CropZone>? cropZones,
    double? zoneGap,
  }) {
    return BoardDesign(
      size: size ?? this.size,
      background: background ?? this.background,
      frames: frames ?? this.frames,
      cropZones: cropZones ?? this.cropZones,
      zoneGap: zoneGap ?? this.zoneGap,
    );
  }

  Map<String, dynamic> toJson() => {
    'width': size.width,
    'height': size.height,
    'background': background.toJson(),
    'frames': frames.map((f) => f.toJson()).toList(),
    'cropZones': cropZones.map((z) => z.toJson()).toList(),
    'zoneGap': zoneGap,
  };

  factory BoardDesign.fromJson(Map<String, dynamic> json) {
    return BoardDesign(
      size: Size(
        (json['width'] as num?)?.toDouble() ?? 4000,
        (json['height'] as num?)?.toDouble() ?? 3000,
      ),
      background: json['background'] != null
          ? ScreenshotDesign.fromJson(
              Map<String, dynamic>.from(json['background'] as Map),
            )
          : const ScreenshotDesign(),
      frames:
          (json['frames'] as List?)
              ?.map(
                (f) => FrameElement.fromJson(Map<String, dynamic>.from(f as Map)),
              )
              .toList() ??
          const [],
      cropZones:
          (json['cropZones'] as List?)
              ?.map(
                (z) => CropZone.fromJson(Map<String, dynamic>.from(z as Map)),
              )
              .toList() ??
          const [],
      // Files written before spacing was adjustable keep the layout they were
      // authored with.
      zoneGap: (json['zoneGap'] as num?)?.toDouble() ?? defaultZoneGap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardDesign &&
          other.size == size &&
          other.background == background &&
          listEquals(other.frames, frames) &&
          listEquals(other.cropZones, cropZones) &&
          other.zoneGap == zoneGap;

  @override
  int get hashCode => Object.hash(
    size,
    background,
    Object.hashAll(frames),
    Object.hashAll(cropZones),
    zoneGap,
  );
}
