// ignore_for_file: non_constant_identifier_names

import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/noop_frame_painter.dart';
import 'package:flutter/material.dart';

Path _buildScreenPath(Rect screenRect, double cornerRadius) {
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius)),
    );
}

// ─── Apple Watch S11 42mm ───────────────────────────────────────
// PNG size: 520 x 800 @ 72 DPI (1x)
// Screen resolution: 374 x 446 @ 2x → 187 x 223 logical
// Centered: h=(520-374)/2=73, v=(800-446)/2=177
const _s11_42mmFrameSize = Size(520, 800);
const _s11_42mmScreenRect = Rect.fromLTWH(73, 177, 374, 446);
const _s11_42mmCornerRadius = 58.0;
const _s11_42mmScreenSize = Size(187, 223);

// ─── Apple Watch S11 46mm ───────────────────────────────────────
// PNG size: 560 x 880 @ 72 DPI (1x)
// Screen resolution: 416 x 496 @ 2x → 208 x 248 logical
// Centered: h=(560-416)/2=72, v=(880-496)/2=192
const _s11_46mmFrameSize = Size(560, 880);
const _s11_46mmScreenRect = Rect.fromLTWH(72, 192, 416, 496);
const _s11_46mmCornerRadius = 62.0;
const _s11_46mmScreenSize = Size(208, 248);

// ─── Apple Watch Ultra 3 ────────────────────────────────────────
// PNG size: 600 x 960 @ 72 DPI (1x)
// Screen resolution: 410 x 502 @ 2x → 205 x 251 logical
// Centered: h=(600-410)/2=95, v=(960-502)/2=229
// Expanded by ~10px each side so content bleeds past; PNG bezel clips edges.
const _ultra3FrameSize = Size(600, 960);
const _ultra3ScreenRect = Rect.fromLTWH(85, 219, 430, 522);
const _ultra3CornerRadius = 50.0;
const _ultra3ScreenSize = Size(205, 251);

/// Sport Band variants for Apple Watch S11 42mm
DeviceInfo _s11_42mm({
  required String id,
  required String name,
  required String asset,
}) {
  return DeviceInfo(
    identifier: DeviceIdentifier(TargetPlatform.iOS, DeviceType.watch, id),
    name: name,
    pixelRatio: 2,
    frameSize: _s11_42mmFrameSize,
    screenSize: _s11_42mmScreenSize,
    safeAreas: EdgeInsets.zero,
    framePainter: const NoopFramePainter(),
    screenPath: _buildScreenPath(_s11_42mmScreenRect, _s11_42mmCornerRadius),
    frameAssetPath: asset,
  );
}

DeviceInfo _s11_46mm({
  required String id,
  required String name,
  required String asset,
}) {
  return DeviceInfo(
    identifier: DeviceIdentifier(TargetPlatform.iOS, DeviceType.watch, id),
    name: name,
    pixelRatio: 2,
    frameSize: _s11_46mmFrameSize,
    screenSize: _s11_46mmScreenSize,
    safeAreas: EdgeInsets.zero,
    framePainter: const NoopFramePainter(),
    screenPath: _buildScreenPath(_s11_46mmScreenRect, _s11_46mmCornerRadius),
    frameAssetPath: asset,
  );
}

DeviceInfo _ultra3({
  required String id,
  required String name,
  required String asset,
}) {
  return DeviceInfo(
    identifier: DeviceIdentifier(TargetPlatform.iOS, DeviceType.watch, id),
    name: name,
    pixelRatio: 2,
    frameSize: _ultra3FrameSize,
    screenSize: _ultra3ScreenSize,
    safeAreas: EdgeInsets.zero,
    framePainter: const NoopFramePainter(),
    screenPath: _buildScreenPath(_ultra3ScreenRect, _ultra3CornerRadius),
    frameAssetPath: asset,
  );
}

// ─── Sport Band 42mm ────────────────────────────────────────────
final s11_42mm_jetBlack = _s11_42mm(
  id: 'aw-s11-42mm-jet-black-sport-band-black',
  name: 'Watch S11 42mm Jet Black',
  asset:
      'assets/watch/sport_band/apple_watch_s11_42mm_aluminum_jet_black_sport_band_black.png',
);

final s11_42mm_silver = _s11_42mm(
  id: 'aw-s11-42mm-silver-sport-band-purple-fog',
  name: 'Watch S11 42mm Silver',
  asset:
      'assets/watch/sport_band/apple_watch_s11_42mm_aluminum_silver_sport_band_purple_fog.png',
);

// ─── Sport Band 46mm ────────────────────────────────────────────
final s11_46mm_jetBlack = _s11_46mm(
  id: 'aw-s11-46mm-jet-black-sport-band-black',
  name: 'Watch S11 46mm Jet Black',
  asset:
      'assets/watch/sport_band/apple_watch_s11_46mm_aluminum_jet_black_sport_band_black.png',
);

final s11_46mm_silver = _s11_46mm(
  id: 'aw-s11-46mm-silver-sport-band-purple-fog',
  name: 'Watch S11 46mm Silver',
  asset:
      'assets/watch/sport_band/apple_watch_s11_46mm_aluminum_silver_sport_band_purple_fog.png',
);

// ─── Sport Loop 42mm & 46mm ─────────────────────────────────────
final s11_42mm_sportLoop = _s11_42mm(
  id: 'aw-s11-42mm-space-gray-sport-loop',
  name: 'Watch S11 42mm Sport Loop',
  asset:
      'assets/watch/sport_loop/apple_watch_s11_42mm_aluminum_space_gray_sport_loop_forest.png',
);

final s11_46mm_sportLoop = _s11_46mm(
  id: 'aw-s11-46mm-space-gray-sport-loop',
  name: 'Watch S11 46mm Sport Loop',
  asset:
      'assets/watch/sport_loop/apple_watch_s11_46mm_aluminum_space_gray_sport_loop_forest.png',
);

// ─── Magnetic Link 42mm & 46mm ──────────────────────────────────
final s11_42mm_magneticLink = _s11_42mm(
  id: 'aw-s11-42mm-titanium-natural-magnetic-link',
  name: 'Watch S11 42mm Magnetic Link',
  asset:
      'assets/watch/magnetic_link/apple_watch_s11_42mm_titanium_natural_magnetic_link_caramel.png',
);

final s11_46mm_magneticLink = _s11_46mm(
  id: 'aw-s11-46mm-titanium-natural-magnetic-link',
  name: 'Watch S11 46mm Magnetic Link',
  asset:
      'assets/watch/magnetic_link/apple_watch_s11_46mm_titanium_natural_magnetic_link_caramel.png',
);

// ─── Apple Watch Ultra 3 ────────────────────────────────────────
final ultra3_oceanBandBlack = _ultra3(
  id: 'aw-ultra-3-black-ocean-band',
  name: 'Watch Ultra 3 Ocean Band',
  asset: 'assets/watch/ocean_band/aw_ultra_3_black_ocean_band_black.png',
);

final ultra3_alpineLoopBlack = _ultra3(
  id: 'aw-ultra-3-black-alpine-loop',
  name: 'Watch Ultra 3 Alpine Loop',
  asset: 'assets/watch/alpine_loop/aw_ultra_3_black_alpine_loop_black.png',
);

final ultra3_trailLoop = _ultra3(
  id: 'aw-ultra-3-black-trail-loop',
  name: 'Watch Ultra 3 Trail Loop',
  asset:
      'assets/watch/trail_loop/aw_ultra_3_black_trail_loop_black_charcoal.png',
);

final ultra3_milanese = _ultra3(
  id: 'aw-ultra-3-natural-milanese',
  name: 'Watch Ultra 3 Milanese Loop',
  asset: 'assets/watch/milanese_loop/aw_ultra_3_natural_milanese_loop.png',
);

/// Default info (S11 46mm Jet Black).
final info = s11_46mm_jetBlack;

/// All Watch S11 42mm variants.
final all42mm = [
  s11_42mm_jetBlack,
  s11_42mm_silver,
  s11_42mm_sportLoop,
  s11_42mm_magneticLink,
];

/// All Watch S11 46mm variants.
final all46mm = [
  s11_46mm_jetBlack,
  s11_46mm_silver,
  s11_46mm_sportLoop,
  s11_46mm_magneticLink,
];

/// All Watch Ultra 3 variants.
final allUltra3 = [
  ultra3_oceanBandBlack,
  ultra3_alpineLoopBlack,
  ultra3_trailLoop,
  ultra3_milanese,
];

/// All Watch devices (default selection).
final allDevices = [
  s11_42mm_jetBlack,
  s11_46mm_jetBlack,
  ultra3_oceanBandBlack,
];
