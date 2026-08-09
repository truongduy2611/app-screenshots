import 'package:flutter/material.dart';

import 'screenshot_design.dart';

/// Where a device frame sits inside its crop zone, as fractions of the zone.
///
/// Fractions rather than pixels so one template works for every export format
/// — a 6.9" iPhone zone and a 13" iPad zone lay out identically.
@immutable
class FramePlacement {
  /// In-plane rotation, degrees. Positive leans clockwise.
  final double rotation;

  /// Frame width as a fraction of the zone width.
  final double widthFactor;

  /// Frame centre, as fractions of the zone. `(0.5, 0.5)` is the zone centre;
  /// values outside 0..1 deliberately let a frame overhang its zone, which is
  /// what makes a device straddle two screenshots.
  final double centerX;
  final double centerY;

  const FramePlacement({
    this.rotation = 0,
    this.widthFactor = 0.72,
    this.centerX = 0.5,
    this.centerY = 0.58,
  });

  /// Frame aspect ratio (h/w) used to derive height from [widthFactor].
  /// Matches a modern phone shell closely enough for a starting layout.
  static const double aspect = 2.0;
}

/// A board layout: background styling plus how the device frames are placed.
///
/// Distinct from [ScreenshotPreset], which is authored as one design per
/// artboard and describes background and text only. A board is a single canvas
/// whose frames are free-floating elements, so a board template also has to say
/// where those frames go and how they are rotated — the tilted, overlapping
/// arrangements that make a board worth using over separate artboards.
@immutable
class BoardTemplate {
  final String id;

  /// Untranslated display name. Board templates are layout presets rather than
  /// UI copy, so names stay in English like [ScreenshotPreset] names do.
  final String name;

  final String description;

  /// Colours for the picker thumbnail.
  final List<Color> thumbnailColors;

  /// Background styling for the whole board: colour, gradient, mesh, doodle.
  final ScreenshotDesign background;

  /// Frame placements, cycled across the zones. A three-entry pattern on a
  /// five-zone board repeats from the start at zone four.
  final List<FramePlacement> framePattern;

  /// Spacing between crop zones this layout is designed around. Zero produces
  /// a continuous panorama across the exported screenshots.
  final double zoneGap;

  const BoardTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailColors,
    required this.background,
    required this.framePattern,
    required this.zoneGap,
  });

  /// The placement for the zone at [index], cycling the pattern.
  FramePlacement placementFor(int index) =>
      framePattern[index % framePattern.length];
}
