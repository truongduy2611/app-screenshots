import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/noop_frame_painter.dart';
import 'package:flutter/material.dart';

const _assetBase = 'assets/iphone_17_pro';

Path _buildScreenPath(Rect screenRect, double cornerRadius) {
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius)),
    );
}

// Frame size: 1350 x 2760
// Actual screen resolution: 1206 x 2622 pixels
const _frameSize = Size(1350, 2760);
const _screenRect = Rect.fromLTWH(72, 69, 1206, 2622);
const _cornerRadius = 90.0;
const _screenSize = Size(402, 874);

DeviceInfo _buildInfo({
  required String color,
  required String portraitAsset,
  required String landscapeAsset,
}) {
  return DeviceInfo(
    identifier: DeviceIdentifier(
      TargetPlatform.iOS,
      DeviceType.phone,
      'iphone-17-pro-$color',
    ),
    name: 'iPhone 17 Pro (${color[0].toUpperCase()}${color.substring(1)})',
    pixelRatio: 3,
    frameSize: _frameSize,
    screenSize: _screenSize,
    safeAreas: const EdgeInsets.only(top: 62, bottom: 34),
    rotatedSafeAreas: const EdgeInsets.only(left: 62, right: 62, bottom: 21),
    framePainter: const NoopFramePainter(),
    screenPath: _buildScreenPath(_screenRect, _cornerRadius),
    frameAssetPath: '$_assetBase/$portraitAsset',
    landscapeFrameAssetPath: '$_assetBase/$landscapeAsset',
  );
}

final silver = _buildInfo(
  color: 'silver',
  portraitAsset: 'iphone_17_pro_silver_portrait.png',
  landscapeAsset: 'iphone_17_pro_silver_landscape.png',
);

final deepBlue = _buildInfo(
  color: 'deep-blue',
  portraitAsset: 'iphone_17_pro_deep_blue_portrait.png',
  landscapeAsset: 'iphone_17_pro_deep_blue_landscape.png',
);

final cosmicOrange = _buildInfo(
  color: 'cosmic-orange',
  portraitAsset: 'iphone_17_pro_cosmic_orange_portrait.png',
  landscapeAsset: 'iphone_17_pro_cosmic_orange_landscape.png',
);

/// Default info (silver).
final info = silver;

/// All color variants.
final allColors = [silver, deepBlue, cosmicOrange];
