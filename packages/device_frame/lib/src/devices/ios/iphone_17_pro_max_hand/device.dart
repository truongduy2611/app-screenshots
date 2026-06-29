import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/noop_frame_painter.dart';
import 'package:flutter/material.dart';

const _assetBase = 'assets/iphone_17_pro_max_hand';

Path _buildScreenPath(Rect screenRect, double cornerRadius) {
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius)),
    );
}

// Frame size in pixels: 3749 x 2800
// Screen area: Rect.fromLTWH(1489, 72, 771, 1674)
const _frameSize = Size(3749, 2800);
const _screenRect = Rect.fromLTWH(1489, 72, 771, 1674);
const _cornerRadius = 67.0;
const _screenSize = Size(440, 956); // Logical points (iPhone 17 Pro Max size)

DeviceInfo _buildInfo() {
  return DeviceInfo(
    identifier: const DeviceIdentifier(
      TargetPlatform.iOS,
      DeviceType.phone,
      'iphone-17-pro-max-hand',
    ),
    name: 'iPhone 17 Pro Max (Hand)',
    pixelRatio: 3,
    frameSize: _frameSize,
    screenSize: _screenSize,
    safeAreas: const EdgeInsets.only(top: 62, bottom: 34),
    rotatedSafeAreas: const EdgeInsets.only(left: 62, right: 62, bottom: 21),
    framePainter: const NoopFramePainter(),
    screenPath: _buildScreenPath(_screenRect, _cornerRadius),
    frameAssetPath: '$_assetBase/iphone_17_pro_max_hand_portrait.png',
    landscapeFrameAssetPath: '$_assetBase/iphone_17_pro_max_hand_landscape.png',
  );
}

final info = _buildInfo();

final allColors = [info];
