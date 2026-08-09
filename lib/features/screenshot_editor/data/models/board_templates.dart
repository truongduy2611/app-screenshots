import 'package:flutter/material.dart';

import 'board_template.dart';
import 'mesh_gradient_settings.dart';
import 'screenshot_design.dart';

/// Built-in board layouts.
///
/// These exist separately from [ScreenshotPreset] because a preset only
/// describes background and text for one artboard. A board's frames are
/// free-floating, so these also carry the rotation and overlap that give a
/// board its look — and, for the panorama layouts, the zero zone spacing that
/// makes one continuous image span every exported screenshot.
class BoardTemplates {
  const BoardTemplates._();

  static const double _defaultGap = 120.0;

  /// Ordered for the picker: the safe, widely-useful layouts first, the bolder
  /// ones after, and the neutral reset last.
  static List<BoardTemplate> get all => [
    // Dark
    tiltedTrio,
    alternatingLean,
    cascade,
    spotlight,
    midnightNeon,
    deepOcean,
    // Light
    paperWhite,
    softMint,
    warmSunset,
    pastelDrift,
    // Panorama — zero spacing, one continuous image
    panoramaFlow,
    panoramaDawn,
    // Bold
    edgeBleed,
    heroOffset,
    // Neutral
    straightOn,
  ];

  static BoardTemplate? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---------------------------------------------------------------------------

  /// Every frame leaning the same way — the most common App Store look.
  static final tiltedTrio = BoardTemplate(
    id: 'tilted_trio',
    name: 'Tilted Trio',
    description: 'Uniform lean, roomy margins',
    thumbnailColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF1E1B4B),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -8, widthFactor: 0.74, centerY: 0.6),
    ],
  );

  /// Frames alternate lean, so the row reads with a rhythm.
  static final alternatingLean = BoardTemplate(
    id: 'alternating_lean',
    name: 'Alternating Lean',
    description: 'Frames tilt in opposite directions',
    thumbnailColors: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF083344),
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E7490), Color(0xFF083344)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -10, widthFactor: 0.72, centerY: 0.58),
      FramePlacement(rotation: 10, widthFactor: 0.72, centerY: 0.62),
    ],
  );

  /// Zero spacing, frames overhanging their zones so devices straddle the
  /// seams — one continuous scene sliced into screenshots.
  static final panoramaFlow = BoardTemplate(
    id: 'panorama_flow',
    name: 'Panorama Flow',
    description: 'No gaps — one image across every screenshot',
    thumbnailColors: const [Color(0xFFF97316), Color(0xFFDB2777)],
    zoneGap: 0,
    background: ScreenshotDesign(
      backgroundColor: const Color(0xFF450A0A),
      meshGradient: const MeshGradientSettings(
        points: [
          MeshPoint(position: Offset(0.1, 0.2), color: Color(0xFFF97316)),
          MeshPoint(position: Offset(0.9, 0.15), color: Color(0xFFDB2777)),
          MeshPoint(position: Offset(0.25, 0.85), color: Color(0xFF7C3AED)),
          MeshPoint(position: Offset(0.85, 0.9), color: Color(0xFFF59E0B)),
        ],
        blend: 3.2,
      ),
    ),
    framePattern: const [
      // centerX drifts past the zone edge so a frame breaks the seam.
      FramePlacement(rotation: -6, widthFactor: 0.78, centerX: 0.62, centerY: 0.6),
      FramePlacement(rotation: 4, widthFactor: 0.78, centerX: 0.38, centerY: 0.64),
    ],
  );

  /// One large hero frame per zone, upright and centred.
  static final spotlight = BoardTemplate(
    id: 'spotlight',
    name: 'Spotlight',
    description: 'Large upright frames, high contrast',
    thumbnailColors: const [Color(0xFF111827), Color(0xFF374151)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF0B0B0F),
      backgroundGradient: RadialGradient(
        center: Alignment.topCenter,
        radius: 1.1,
        colors: [Color(0xFF27272A), Color(0xFF09090B)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: 0, widthFactor: 0.82, centerY: 0.62),
    ],
  );

  /// Progressive tilt down the row, like a fanned deck.
  static final cascade = BoardTemplate(
    id: 'cascade',
    name: 'Cascade',
    description: 'Tilt and height step across the row',
    thumbnailColors: const [Color(0xFF10B981), Color(0xFF34D399)],
    zoneGap: 80,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF022C22),
      backgroundGradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF064E3B), Color(0xFF10B981)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -12, widthFactor: 0.70, centerY: 0.54),
      FramePlacement(rotation: -4, widthFactor: 0.74, centerY: 0.60),
      FramePlacement(rotation: 4, widthFactor: 0.74, centerY: 0.66),
      FramePlacement(rotation: 12, widthFactor: 0.70, centerY: 0.60),
    ],
  );

  /// Near-black with a vivid mesh. Strong alternating tilt for apps that want
  /// to look loud rather than considered.
  static final midnightNeon = BoardTemplate(
    id: 'midnight_neon',
    name: 'Midnight Neon',
    description: 'Vivid mesh on near-black, strong tilt',
    thumbnailColors: const [Color(0xFFD946EF), Color(0xFF22D3EE)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF09090B),
      meshGradient: MeshGradientSettings(
        points: [
          MeshPoint(position: Offset(0.05, 0.1), color: Color(0xFFD946EF)),
          MeshPoint(position: Offset(0.95, 0.2), color: Color(0xFF22D3EE)),
          MeshPoint(position: Offset(0.3, 0.95), color: Color(0xFF6366F1)),
          MeshPoint(position: Offset(0.8, 0.75), color: Color(0xFF09090B)),
        ],
        blend: 2.6,
        noiseIntensity: 0.05,
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -14, widthFactor: 0.70, centerY: 0.56),
      FramePlacement(rotation: 14, widthFactor: 0.70, centerY: 0.64),
    ],
  );

  /// Cool blue-green mesh with a gentle progressive tilt. Calmer than
  /// [midnightNeon] while still having depth.
  static final deepOcean = BoardTemplate(
    id: 'deep_ocean',
    name: 'Deep Ocean',
    description: 'Blue-green mesh, gentle progressive tilt',
    thumbnailColors: const [Color(0xFF0369A1), Color(0xFF14B8A6)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF042F2E),
      meshGradient: MeshGradientSettings(
        points: [
          MeshPoint(position: Offset(0.15, 0.15), color: Color(0xFF0369A1)),
          MeshPoint(position: Offset(0.9, 0.3), color: Color(0xFF14B8A6)),
          MeshPoint(position: Offset(0.2, 0.9), color: Color(0xFF042F2E)),
          MeshPoint(position: Offset(0.85, 0.85), color: Color(0xFF0E7490)),
        ],
        blend: 3.4,
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -6, widthFactor: 0.72, centerY: 0.58),
      FramePlacement(rotation: -2, widthFactor: 0.74, centerY: 0.61),
      FramePlacement(rotation: 6, widthFactor: 0.72, centerY: 0.58),
    ],
  );

  // ---------------------------------------------------------------------------
  // Light
  //
  // Every layout above is dark. A light background is the more common choice
  // for productivity, finance, and health listings, and it also lets a dark
  // device shell read as the subject rather than disappearing into the canvas.
  // ---------------------------------------------------------------------------

  /// Almost white, barely any tilt. For apps whose screenshots carry the
  /// message and want nothing competing with them.
  static final paperWhite = BoardTemplate(
    id: 'paper_white',
    name: 'Paper White',
    description: 'Near-white and minimal, large upright frames',
    thumbnailColors: const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFFF8FAFC),
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE7ECF2)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -2, widthFactor: 0.78, centerY: 0.62),
      FramePlacement(rotation: 2, widthFactor: 0.78, centerY: 0.62),
    ],
  );

  /// Soft mint, gentle alternating lean. Friendly without being loud.
  static final softMint = BoardTemplate(
    id: 'soft_mint',
    name: 'Soft Mint',
    description: 'Pale green, gentle alternating lean',
    thumbnailColors: const [Color(0xFFD1FAE5), Color(0xFF6EE7B7)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFFECFDF5),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFECFDF5), Color(0xFFA7F3D0)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -7, widthFactor: 0.72, centerY: 0.60),
      FramePlacement(rotation: 7, widthFactor: 0.72, centerY: 0.60),
    ],
  );

  /// Warm coral to amber. Reads as energetic on a light listing.
  static final warmSunset = BoardTemplate(
    id: 'warm_sunset',
    name: 'Warm Sunset',
    description: 'Coral to amber, uniform lean',
    thumbnailColors: const [Color(0xFFFDBA74), Color(0xFFFB7185)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFFFFF7ED),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFED7AA), Color(0xFFFDA4AF)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -9, widthFactor: 0.73, centerY: 0.60),
    ],
  );

  /// Light multi-colour mesh — the pastel look, without going flat.
  static final pastelDrift = BoardTemplate(
    id: 'pastel_drift',
    name: 'Pastel Drift',
    description: 'Soft multi-colour mesh, playful tilt',
    thumbnailColors: const [Color(0xFFC7D2FE), Color(0xFFFBCFE8)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFFF5F3FF),
      meshGradient: MeshGradientSettings(
        points: [
          MeshPoint(position: Offset(0.1, 0.15), color: Color(0xFFC7D2FE)),
          MeshPoint(position: Offset(0.9, 0.1), color: Color(0xFFFBCFE8)),
          MeshPoint(position: Offset(0.2, 0.9), color: Color(0xFFBAE6FD)),
          MeshPoint(position: Offset(0.85, 0.85), color: Color(0xFFFEF08A)),
        ],
        blend: 3.8,
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -11, widthFactor: 0.70, centerY: 0.57),
      FramePlacement(rotation: 5, widthFactor: 0.72, centerY: 0.63),
      FramePlacement(rotation: 11, widthFactor: 0.70, centerY: 0.57),
    ],
  );

  /// Light panorama: zero spacing, so the wash runs unbroken across every
  /// exported screenshot. The counterpart to [panoramaFlow].
  static final panoramaDawn = BoardTemplate(
    id: 'panorama_dawn',
    name: 'Panorama Dawn',
    description: 'No gaps, soft light wash across every screenshot',
    thumbnailColors: const [Color(0xFFFDE68A), Color(0xFFA5B4FC)],
    zoneGap: 0,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFFFFFBEB),
      meshGradient: MeshGradientSettings(
        points: [
          MeshPoint(position: Offset(0.05, 0.3), color: Color(0xFFFDE68A)),
          MeshPoint(position: Offset(0.45, 0.1), color: Color(0xFFFBCFE8)),
          MeshPoint(position: Offset(0.75, 0.6), color: Color(0xFFA5B4FC)),
          MeshPoint(position: Offset(0.98, 0.2), color: Color(0xFFBAE6FD)),
        ],
        blend: 4.0,
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -5, widthFactor: 0.76, centerX: 0.6, centerY: 0.62),
      FramePlacement(rotation: 5, widthFactor: 0.76, centerX: 0.4, centerY: 0.58),
    ],
  );

  // ---------------------------------------------------------------------------
  // Bold
  // ---------------------------------------------------------------------------

  /// Frames deliberately larger than their zone, so the device is cropped by
  /// the screenshot edge. Reads as confident and fills the frame — the usual
  /// choice when the UI itself is the selling point.
  static final edgeBleed = BoardTemplate(
    id: 'edge_bleed',
    name: 'Edge Bleed',
    description: 'Oversized frames cropped by the screenshot edge',
    thumbnailColors: const [Color(0xFF18181B), Color(0xFF3F3F46)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF18181B),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF27272A), Color(0xFF09090B)],
      ),
    ),
    framePattern: const [
      // centerY past the midpoint pushes the bottom of the device off the zone.
      FramePlacement(rotation: -5, widthFactor: 0.92, centerY: 0.78),
    ],
  );

  /// One large frame pushed off-centre, leaving a column of open background —
  /// room for a headline beside the device rather than above it.
  static final heroOffset = BoardTemplate(
    id: 'hero_offset',
    name: 'Hero Offset',
    description: 'Large frame pushed aside, space for a headline',
    thumbnailColors: const [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF172554),
      backgroundGradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: -7, widthFactor: 0.74, centerX: 0.62, centerY: 0.66),
      FramePlacement(rotation: 7, widthFactor: 0.74, centerX: 0.38, centerY: 0.66),
    ],
  );

  /// No rotation at all — the neutral reset.
  static final straightOn = BoardTemplate(
    id: 'straight_on',
    name: 'Straight On',
    description: 'No rotation, even placement',
    thumbnailColors: const [Color(0xFF64748B), Color(0xFFCBD5E1)],
    zoneGap: _defaultGap,
    background: const ScreenshotDesign(
      backgroundColor: Color(0xFF1E293B),
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF0F172A)],
      ),
    ),
    framePattern: const [
      FramePlacement(rotation: 0, widthFactor: 0.72, centerY: 0.6),
    ],
  );
}
