// TECH_DEBT: Color.value deprecated in Flutter 3.27 — kept for parity with the
// rest of the design models, which serialize colors the same way.
// ignore_for_file: deprecated_member_use
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';

import 'screenshot_design.dart';

/// One device frame (or bare screenshot) placed freely on a [BoardDesign].
///
/// The single-artboard editor models this as fields on [ScreenshotDesign]
/// (`deviceFrame`, `imagePosition`, `padding`, …) because there is exactly one
/// frame per canvas. A board has many, each with its own rectangle, so the
/// frame becomes a first-class positioned element. That is what lets a frame
/// straddle two crop zones.
class FrameElement {
  /// Stable identifier. Also the slot key for per-locale image overrides.
  final String id;

  /// The device shell to draw. `null` renders the image bare, rounded by
  /// [cornerRadius].
  final DeviceInfo? device;

  /// Path to the screenshot shown inside the frame.
  final String? imagePath;

  /// Top-left corner in board coordinates.
  final Offset position;

  /// Bounding-box size in board coordinates. The device shell is fitted
  /// inside this box.
  final Size size;

  /// In-plane rotation, radians.
  final double rotation;

  /// Perspective tilts, radians.
  final double rotationX;
  final double rotationY;

  /// Device orientation of the shell.
  final Orientation orientation;

  /// Corner radius used when [device] is `null`.
  final double cornerRadius;

  /// Paint order among frames and overlays.
  final int zIndex;

  final double opacity;

  final Color? shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  const FrameElement({
    required this.id,
    required this.position,
    required this.size,
    this.device,
    this.imagePath,
    this.rotation = 0.0,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.orientation = Orientation.portrait,
    this.cornerRadius = 0.0,
    this.zIndex = 0,
    this.opacity = 1.0,
    this.shadowColor,
    this.shadowBlurRadius = 0.0,
    this.shadowOffset = Offset.zero,
  });

  Rect get rect => position & size;

  Offset get center =>
      Offset(position.dx + size.width / 2, position.dy + size.height / 2);

  FrameElement copyWith({
    String? id,
    DeviceInfo? device,
    String? imagePath,
    Offset? position,
    Size? size,
    double? rotation,
    double? rotationX,
    double? rotationY,
    Orientation? orientation,
    double? cornerRadius,
    int? zIndex,
    double? opacity,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    bool clearDevice = false,
    bool clearImage = false,
    bool clearShadowColor = false,
  }) {
    return FrameElement(
      id: id ?? this.id,
      device: clearDevice ? null : (device ?? this.device),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      orientation: orientation ?? this.orientation,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      zIndex: zIndex ?? this.zIndex,
      opacity: opacity ?? this.opacity,
      shadowColor: clearShadowColor ? null : (shadowColor ?? this.shadowColor),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device': device?.identifier.toString(),
    'imagePath': imagePath,
    'x': position.dx,
    'y': position.dy,
    'width': size.width,
    'height': size.height,
    'rotation': rotation,
    'rotationX': rotationX,
    'rotationY': rotationY,
    'orientation': orientation.index,
    'cornerRadius': cornerRadius,
    'zIndex': zIndex,
    'opacity': opacity,
    if (shadowColor != null) 'shadowColor': shadowColor!.value,
    'shadowBlurRadius': shadowBlurRadius,
    'shadowOffsetX': shadowOffset.dx,
    'shadowOffsetY': shadowOffset.dy,
  };

  factory FrameElement.fromJson(Map<String, dynamic> json) {
    return FrameElement(
      id: json['id'] as String,
      device: ScreenshotDesign.findDevice(json['device'] as String?),
      imagePath: json['imagePath'] as String?,
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      size: Size(
        (json['width'] as num?)?.toDouble() ?? 600,
        (json['height'] as num?)?.toDouble() ?? 1200,
      ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      rotationX: (json['rotationX'] as num?)?.toDouble() ?? 0.0,
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0.0,
      orientation: Orientation.values[json['orientation'] as int? ?? 0],
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      zIndex: json['zIndex'] as int? ?? 0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      shadowColor: json['shadowColor'] != null
          ? Color(json['shadowColor'] as int)
          : null,
      shadowBlurRadius: (json['shadowBlurRadius'] as num?)?.toDouble() ?? 0.0,
      shadowOffset: Offset(
        (json['shadowOffsetX'] as num?)?.toDouble() ?? 0,
        (json['shadowOffsetY'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrameElement &&
          other.id == id &&
          other.device?.identifier == device?.identifier &&
          other.imagePath == imagePath &&
          other.position == position &&
          other.size == size &&
          other.rotation == rotation &&
          other.rotationX == rotationX &&
          other.rotationY == rotationY &&
          other.orientation == orientation &&
          other.cornerRadius == cornerRadius &&
          other.zIndex == zIndex &&
          other.opacity == opacity &&
          other.shadowColor == shadowColor &&
          other.shadowBlurRadius == shadowBlurRadius &&
          other.shadowOffset == shadowOffset;

  @override
  int get hashCode => Object.hash(
    id,
    device?.identifier,
    imagePath,
    position,
    size,
    rotation,
    rotationX,
    rotationY,
    orientation,
    cornerRadius,
    zIndex,
    Object.hash(opacity, shadowColor, shadowBlurRadius, shadowOffset),
  );
}
