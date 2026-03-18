import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/noop_frame_painter.dart';
import 'package:flutter/material.dart';

const _assetBase = 'assets/iphone_17';

/// Build a screen path (rounded rect) for the screen area within the frame.
Path _buildScreenPath(Rect screenRect, double cornerRadius) {
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius)),
    );
}

// Frame size in pixels: 1350 x 2760
// Actual screen resolution: 1206 x 2622 pixels
const _frameSize = Size(1350, 2760);
const _screenRect = Rect.fromLTWH(72, 69, 1206, 2622);
const _cornerRadius = 90.0;
const _screenSize = Size(402, 874); // logical points

DeviceInfo _buildInfo({
  required String color,
  required String portraitAsset,
  required String landscapeAsset,
}) {
  return DeviceInfo(
    identifier: DeviceIdentifier(
      TargetPlatform.iOS,
      DeviceType.phone,
      'iphone-17-$color',
    ),
    name: 'iPhone 17 (${color[0].toUpperCase()}${color.substring(1)})',
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

final black = _buildInfo(
  color: 'black',
  portraitAsset: 'iphone_17_black_portrait.png',
  landscapeAsset: 'iphone_17_black_landscape.png',
);

final lavender = _buildInfo(
  color: 'lavender',
  portraitAsset: 'iphone_17_lavender_portrait.png',
  landscapeAsset: 'iphone_17_lavender_landscape.png',
);

final mistBlue = _buildInfo(
  color: 'mist-blue',
  portraitAsset: 'iphone_17_mist_blue_portrait.png',
  landscapeAsset: 'iphone_17_mist_blue_landscape.png',
);

final sage = _buildInfo(
  color: 'sage',
  portraitAsset: 'iphone_17_sage_portrait.png',
  landscapeAsset: 'iphone_17_sage_landscape.png',
);

final white = _buildInfo(
  color: 'white',
  portraitAsset: 'iphone_17_white_portrait.png',
  landscapeAsset: 'iphone_17_white_landscape.png',
);

/// Default info (black).
final info = black;

/// All color variants.
final allColors = [black, lavender, mistBlue, sage, white];
