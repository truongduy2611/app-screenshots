import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/noop_frame_painter.dart';
import 'package:flutter/material.dart';

const _assetBase = 'assets/iphone_air';

Path _buildScreenPath(Rect screenRect, double cornerRadius) {
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius)),
    );
}

// Frame size: 1380 x 2880
const _frameSize = Size(1380, 2880);
const _screenRect = Rect.fromLTWH(60, 96, 1260, 2736);
const _cornerRadius = 92.0;
const _screenSize = Size(420, 912);

DeviceInfo _buildInfo({
  required String color,
  required String portraitAsset,
  required String landscapeAsset,
}) {
  return DeviceInfo(
    identifier: DeviceIdentifier(
      TargetPlatform.iOS,
      DeviceType.phone,
      'iphone-air-$color',
    ),
    name: 'iPhone Air (${color[0].toUpperCase()}${color.substring(1)})',
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

final spaceBlack = _buildInfo(
  color: 'space-black',
  portraitAsset: 'iphone_air_space_black_portrait.png',
  landscapeAsset: 'iphone_air_space_black_landscape.png',
);

final cloudWhite = _buildInfo(
  color: 'cloud-white',
  portraitAsset: 'iphone_air_cloud_white_portrait.png',
  landscapeAsset: 'iphone_air_cloud_white_landscape.png',
);

final lightGold = _buildInfo(
  color: 'light-gold',
  portraitAsset: 'iphone_air_light_gold_portrait.png',
  landscapeAsset: 'iphone_air_light_gold_landscape.png',
);

final skyBlue = _buildInfo(
  color: 'sky-blue',
  portraitAsset: 'iphone_air_sky_blue_portrait.png',
  landscapeAsset: 'iphone_air_sky_blue_landscape.png',
);

/// Default info (space black).
final info = spaceBlack;

/// All color variants.
final allColors = [spaceBlack, cloudWhite, lightGold, skyBlue];
