// TECH_DEBT: Color.value deprecated in Flutter 3.27 — used by device_frame package internals
// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';

import 'mesh_gradient_settings.dart';

part 'text_overlay.dart';
part 'image_overlay.dart';
part 'icon_overlay.dart';
part 'grid_settings.dart';
part 'doodle_settings.dart';
part 'magnifier_overlay.dart';

class ScreenshotDesign {
  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final DeviceInfo? deviceFrame;
  final List<TextOverlay> overlays;
  final double padding;
  final Offset imagePosition;
  final String? displayType;
  final Orientation orientation;
  final double frameRotationX;
  final double frameRotationY;
  final double frameRotation;
  final List<ImageOverlay> imageOverlays;
  final List<IconOverlay> iconOverlays;
  final List<MagnifierOverlay> magnifierOverlays;
  final GridSettings gridSettings;
  final DoodleSettings? doodleSettings;
  final bool transparentBackground;
  final MeshGradientSettings? meshGradient;

  final double cornerRadius;

  const ScreenshotDesign({
    this.backgroundColor = const Color(0xDD000000),
    this.backgroundGradient,
    this.deviceFrame,
    this.overlays = const [],
    this.imageOverlays = const [],
    this.iconOverlays = const [],
    this.magnifierOverlays = const [],
    this.padding = 32.0,
    this.imagePosition = Offset.zero,
    this.displayType,
    this.orientation = Orientation.portrait,
    this.frameRotationX = 0.0,
    this.frameRotationY = 0.0,
    this.frameRotation = 0.0,
    this.gridSettings = const GridSettings(),
    this.cornerRadius = 0.0,
    this.doodleSettings,
    this.transparentBackground = false,
    this.meshGradient,
  });

  ScreenshotDesign copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    DeviceInfo? deviceFrame,
    List<TextOverlay>? overlays,
    double? padding,
    Offset? imagePosition,
    String? displayType,
    Orientation? orientation,
    double? frameRotationX,
    double? frameRotationY,
    double? frameRotation,
    List<ImageOverlay>? imageOverlays,
    List<IconOverlay>? iconOverlays,
    List<MagnifierOverlay>? magnifierOverlays,
    GridSettings? gridSettings,
    double? cornerRadius,
    DoodleSettings? doodleSettings,
    bool? transparentBackground,
    MeshGradientSettings? meshGradient,
    bool clearGradient = false,
    bool clearDeviceFrame = false,
    bool clearDoodle = false,
    bool clearMeshGradient = false,
  }) {
    return ScreenshotDesign(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: clearGradient
          ? null
          : (backgroundGradient ?? this.backgroundGradient),
      deviceFrame: clearDeviceFrame ? null : (deviceFrame ?? this.deviceFrame),
      overlays: overlays ?? this.overlays,
      padding: padding ?? this.padding,
      imagePosition: imagePosition ?? this.imagePosition,
      displayType: displayType ?? this.displayType,
      orientation: orientation ?? this.orientation,
      frameRotationX: frameRotationX ?? this.frameRotationX,
      frameRotationY: frameRotationY ?? this.frameRotationY,
      frameRotation: frameRotation ?? this.frameRotation,
      imageOverlays: imageOverlays ?? this.imageOverlays,
      iconOverlays: iconOverlays ?? this.iconOverlays,
      magnifierOverlays: magnifierOverlays ?? this.magnifierOverlays,
      gridSettings: gridSettings ?? this.gridSettings,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      doodleSettings: clearDoodle
          ? null
          : (doodleSettings ?? this.doodleSettings),
      transparentBackground:
          transparentBackground ?? this.transparentBackground,
      meshGradient: clearMeshGradient
          ? null
          : (meshGradient ?? this.meshGradient),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor.value,
      'backgroundGradient': backgroundGradient != null
          ? _gradientToJson(backgroundGradient!)
          : null,
      'deviceFrame': deviceFrame?.identifier.toString(),
      'overlays': overlays.map((e) => e.toJson()).toList(),
      'padding': padding,
      'imagePosition': {'dx': imagePosition.dx, 'dy': imagePosition.dy},
      'displayType': displayType,
      'orientation': orientation.index,
      'frameRotationX': frameRotationX,
      'frameRotationY': frameRotationY,
      'frameRotation': frameRotation,
      'imageOverlays': imageOverlays.map((e) => e.toJson()).toList(),
      'iconOverlays': iconOverlays.map((e) => e.toJson()).toList(),
      'magnifierOverlays': magnifierOverlays.map((e) => e.toJson()).toList(),
      'gridSettings': gridSettings.toJson(),
      'cornerRadius': cornerRadius,
      'doodleSettings': doodleSettings?.toJson(),
      'transparentBackground': transparentBackground,
      'meshGradient': meshGradient?.toJson(),
    };
  }

  factory ScreenshotDesign.fromJson(Map<String, dynamic> json) {
    return ScreenshotDesign(
      backgroundColor: Color(json['backgroundColor'] ?? Colors.blue.value),
      backgroundGradient: json['backgroundGradient'] != null
          ? _gradientFromJson(json['backgroundGradient'])
          : null,
      deviceFrame: _findDeviceByName(json['deviceFrame']),
      overlays:
          (json['overlays'] as List?)
              ?.map((e) => TextOverlay.fromJson(e))
              .toList() ??
          [],
      padding: (json['padding'] as num?)?.toDouble() ?? 32.0,
      imagePosition: Offset(
        (json['imagePosition']?['dx'] as num?)?.toDouble() ?? 0,
        (json['imagePosition']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      displayType: json['displayType'],
      orientation: Orientation.values[json['orientation'] ?? 0],
      frameRotationX: (json['frameRotationX'] as num?)?.toDouble() ?? 0.0,
      frameRotationY: (json['frameRotationY'] as num?)?.toDouble() ?? 0.0,
      frameRotation: (json['frameRotation'] as num?)?.toDouble() ?? 0.0,
      imageOverlays:
          (json['imageOverlays'] as List?)
              ?.map((e) => ImageOverlay.fromJson(e))
              .toList() ??
          [],
      iconOverlays:
          (json['iconOverlays'] as List?)
              ?.map((e) => IconOverlay.fromJson(e))
              .toList() ??
          [],
      magnifierOverlays:
          (json['magnifierOverlays'] as List?)
              ?.map((e) => MagnifierOverlay.fromJson(e))
              .toList() ??
          [],
      gridSettings: json['gridSettings'] != null
          ? GridSettings.fromJson(json['gridSettings'])
          : const GridSettings(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      doodleSettings: json['doodleSettings'] != null
          ? DoodleSettings.fromJson(json['doodleSettings'])
          : null,
      transparentBackground: json['transparentBackground'] ?? false,
      meshGradient: json['meshGradient'] != null
          ? MeshGradientSettings.fromJson(json['meshGradient'])
          : null,
    );
  }

  static Map<String, dynamic> _gradientToJson(Gradient gradient) {
    if (gradient is LinearGradient) {
      final begin = gradient.begin is Alignment
          ? gradient.begin as Alignment
          : Alignment.topLeft;
      final end = gradient.end is Alignment
          ? gradient.end as Alignment
          : Alignment.bottomRight;
      return {
        'type': 'linear',
        'colors': gradient.colors.map((e) => e.value).toList(),
        'stops': gradient.stops,
        'begin': {'x': begin.x, 'y': begin.y},
        'end': {'x': end.x, 'y': end.y},
      };
    } else if (gradient is RadialGradient) {
      final center = gradient.center is Alignment
          ? gradient.center as Alignment
          : Alignment.center;
      final focal = gradient.focal is Alignment
          ? gradient.focal as Alignment?
          : null;
      return {
        'type': 'radial',
        'colors': gradient.colors.map((e) => e.value).toList(),
        'stops': gradient.stops,
        'center': {'x': center.x, 'y': center.y},
        'radius': gradient.radius,
        if (focal != null) 'focal': {'x': focal.x, 'y': focal.y},
        'focalRadius': gradient.focalRadius,
      };
    } else if (gradient is SweepGradient) {
      final center = gradient.center is Alignment
          ? gradient.center as Alignment
          : Alignment.center;
      return {
        'type': 'sweep',
        'colors': gradient.colors.map((e) => e.value).toList(),
        'stops': gradient.stops,
        'center': {'x': center.x, 'y': center.y},
        'startAngle': gradient.startAngle,
        'endAngle': gradient.endAngle,
      };
    }
    // Fallback: treat as linear
    return {'type': 'linear', 'colors': [], 'stops': null};
  }

  static Gradient _gradientFromJson(Map<String, dynamic> json) {
    final colors = (json['colors'] as List).map((e) => Color(e)).toList();
    final stops = (json['stops'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    final type = json['type'] ?? 'linear';

    switch (type) {
      case 'radial':
        return RadialGradient(
          colors: colors,
          stops: stops,
          center: Alignment(
            (json['center']?['x'] as num?)?.toDouble() ?? 0.0,
            (json['center']?['y'] as num?)?.toDouble() ?? 0.0,
          ),
          radius: (json['radius'] as num?)?.toDouble() ?? 0.5,
          focal: json['focal'] != null
              ? Alignment(
                  (json['focal']['x'] as num).toDouble(),
                  (json['focal']['y'] as num).toDouble(),
                )
              : null,
          focalRadius: (json['focalRadius'] as num?)?.toDouble() ?? 0.0,
        );
      case 'sweep':
        return SweepGradient(
          colors: colors,
          stops: stops,
          center: Alignment(
            (json['center']?['x'] as num?)?.toDouble() ?? 0.0,
            (json['center']?['y'] as num?)?.toDouble() ?? 0.0,
          ),
          startAngle: (json['startAngle'] as num?)?.toDouble() ?? 0.0,
          endAngle: (json['endAngle'] as num?)?.toDouble() ?? math.pi * 2,
        );
      default:
        return LinearGradient(
          colors: colors,
          stops: stops,
          begin: Alignment(
            (json['begin']?['x'] as num?)?.toDouble() ?? -1.0,
            (json['begin']?['y'] as num?)?.toDouble() ?? -1.0,
          ),
          end: Alignment(
            (json['end']?['x'] as num?)?.toDouble() ?? 1.0,
            (json['end']?['y'] as num?)?.toDouble() ?? 1.0,
          ),
        );
    }
  }

  /// Builds the full list of devices including all color variants.
  /// Cached as a static field to avoid rebuilding on every lookup.
  static List<DeviceInfo>? _allDevicesWithColors;
  static List<DeviceInfo> get _allDevices {
    return _allDevicesWithColors ??= [
      ...Devices.all,
      // iOS color variants not in Devices.all
      ...Devices.ios.iPhone17ProMaxColors,
      ...Devices.ios.iPhone17ProColors,
      ...Devices.ios.iPhone17Colors,
      ...Devices.ios.iPhoneAirColors,
      // Watch band/color variants not in Devices.all
      ...Devices.watch.all42mm,
      ...Devices.watch.all46mm,
      ...Devices.watch.allUltra3,
    ];
  }

  static DeviceInfo? _findDeviceByName(String? name) {
    if (name == null) return null;
    try {
      // Try identifier match first (new format: "ios_phone_iphone-17-pro-max-silver")
      final byIdentifier = _allDevices
          .where((d) => d.identifier.toString() == name)
          .firstOrNull;
      if (byIdentifier != null) return byIdentifier;

      // Fallback: legacy name-based match ("iPhone 17 Pro Max (Silver)")
      return _allDevices.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
  }
}
