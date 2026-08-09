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

  static List<BoardTemplate> get all => [
    tiltedTrio,
    alternatingLean,
    panoramaFlow,
    spotlight,
    cascade,
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
