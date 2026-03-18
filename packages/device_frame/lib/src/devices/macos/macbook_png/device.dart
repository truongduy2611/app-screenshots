
import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/noop_frame_painter.dart';
import 'package:flutter/material.dart';

Path _buildScreenPath(Rect screenRect, double cornerRadius) {
  return Path()
    ..addRRect(
        RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius)),);
}

// MacBook Air 13" M4 - 3220 x 2100 px
// Screen: 2560 x 1664 logical @ 2x
const _airFrameSize = Size(3220, 2100);
const _airScreenRect = Rect.fromLTWH(330, 96, 2560, 1664);
const _airCornerRadius = 20.0;
const _airScreenSize = Size(1280, 832);

final macBookAir13 = DeviceInfo(
  identifier: const DeviceIdentifier(
    TargetPlatform.macOS,
    DeviceType.laptop,
    'macbook-air-13-m4',
  ),
  name: 'MacBook Air 13" M4',
  pixelRatio: 2,
  frameSize: _airFrameSize,
  screenSize: _airScreenSize,
  safeAreas: EdgeInsets.zero,
  framePainter: const NoopFramePainter(),
  screenPath: _buildScreenPath(_airScreenRect, _airCornerRadius),
  frameAssetPath: 'assets/macbook_air/macbook_air_13_4th_gen_midnight.png',
);

// MacBook Pro 14" M4 - 3944 x 2564 px
// Screen: 3024 x 1964 logical @ 2x
const _pro14FrameSize = Size(3944, 2564);
const _pro14ScreenRect = Rect.fromLTWH(460, 120, 3024, 1964);
const _pro14CornerRadius = 24.0;
const _pro14ScreenSize = Size(1512, 982);

final macBookPro14 = DeviceInfo(
  identifier: const DeviceIdentifier(
    TargetPlatform.macOS,
    DeviceType.laptop,
    'macbook-pro-14-m4',
  ),
  name: 'MacBook Pro 14" M4',
  pixelRatio: 2,
  frameSize: _pro14FrameSize,
  screenSize: _pro14ScreenSize,
  safeAreas: EdgeInsets.zero,
  framePainter: const NoopFramePainter(),
  screenPath: _buildScreenPath(_pro14ScreenRect, _pro14CornerRadius),
  frameAssetPath: 'assets/macbook_pro/macbook_pro_m4_14_inch_silver.png',
);

// MacBook Pro 16" M4 - 4340 x 2860 px
// Screen: 3456 x 2234 logical @ 2x
const _pro16FrameSize = Size(4340, 2860);
const _pro16ScreenRect = Rect.fromLTWH(442, 130, 3456, 2234);
const _pro16CornerRadius = 26.0;
const _pro16ScreenSize = Size(1728, 1117);

final macBookPro16 = DeviceInfo(
  identifier: const DeviceIdentifier(
    TargetPlatform.macOS,
    DeviceType.laptop,
    'macbook-pro-16-m4',
  ),
  name: 'MacBook Pro 16" M4',
  pixelRatio: 2,
  frameSize: _pro16FrameSize,
  screenSize: _pro16ScreenSize,
  safeAreas: EdgeInsets.zero,
  framePainter: const NoopFramePainter(),
  screenPath: _buildScreenPath(_pro16ScreenRect, _pro16CornerRadius),
  frameAssetPath: 'assets/macbook_pro/macbook_pro_m4_16_inch_silver.png',
);
