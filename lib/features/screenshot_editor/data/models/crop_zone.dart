import 'package:flutter/material.dart';

import '../../utils/screenshot_utils.dart';

/// A rectangular export region on a [BoardDesign].
///
/// A board is one large canvas; crop zones mark the sub-rectangles that become
/// individual exported screenshots. They are part of the design file, so a
/// project keeps its export framing between sessions, and they can be shown or
/// hidden in the editor without affecting the exported pixels.
///
/// ## Locked vs unlocked
///
/// By default a zone is [locked]: its [size] is exactly the target output size
/// for [displayType] + [orientation], so export is a pure crop with no
/// resampling — the sharpest and fastest path. Unlocking lets the zone be
/// resized freely; export then crops [rect] and scales it to [targetSize],
/// which resamples.
class CropZone {
  /// Stable identifier, also used as the translation slot key for any
  /// per-locale content scoped to this zone.
  final String id;

  /// Optional user-facing label. Falls back to "Screenshot N" in the UI.
  final String? name;

  /// Top-left corner in board coordinates.
  final Offset position;

  /// Size in board coordinates. Equals [targetSize] while [locked].
  final Size size;

  /// Target export format key (see [ScreenshotUtils.allDisplayTypes]).
  final String displayType;

  /// Orientation used to resolve [targetSize] from [displayType].
  final Orientation orientation;

  /// When true the zone is pinned to [targetSize] and cannot be resized.
  final bool locked;

  /// Whether this zone is produced by "export all" / upload flows.
  final bool included;

  const CropZone({
    required this.id,
    required this.position,
    required this.size,
    required this.displayType,
    this.name,
    this.orientation = Orientation.portrait,
    this.locked = true,
    this.included = true,
  });

  /// Creates a zone locked to the native size of [displayType].
  factory CropZone.locked({
    required String id,
    required Offset position,
    required String displayType,
    Orientation orientation = Orientation.portrait,
    String? name,
    bool included = true,
  }) {
    return CropZone(
      id: id,
      name: name,
      position: position,
      size: ScreenshotUtils.getDimensions(displayType, orientation),
      displayType: displayType,
      orientation: orientation,
      included: included,
    );
  }

  /// The pixel size of the exported image for this zone.
  Size get targetSize =>
      ScreenshotUtils.getDimensions(displayType, orientation);

  /// The zone's rectangle in board coordinates.
  Rect get rect => position & size;

  /// Whether the captured region can be copied out without resampling.
  bool get isPixelPerfect =>
      (size.width - targetSize.width).abs() < 0.5 &&
      (size.height - targetSize.height).abs() < 0.5;

  CropZone copyWith({
    String? id,
    String? name,
    Offset? position,
    Size? size,
    String? displayType,
    Orientation? orientation,
    bool? locked,
    bool? included,
    bool clearName = false,
  }) {
    final nextDisplayType = displayType ?? this.displayType;
    final nextOrientation = orientation ?? this.orientation;
    final nextLocked = locked ?? this.locked;

    // A locked zone always tracks its format's native size, so changing the
    // format (or re-locking) resizes it rather than leaving a stale rect.
    final Size nextSize;
    if (nextLocked) {
      nextSize = ScreenshotUtils.getDimensions(
        nextDisplayType,
        nextOrientation,
      );
    } else {
      nextSize = size ?? this.size;
    }

    return CropZone(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      position: position ?? this.position,
      size: nextSize,
      displayType: nextDisplayType,
      orientation: nextOrientation,
      locked: nextLocked,
      included: included ?? this.included,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (name != null) 'name': name,
    'x': position.dx,
    'y': position.dy,
    'width': size.width,
    'height': size.height,
    'displayType': displayType,
    'orientation': orientation.index,
    'locked': locked,
    'included': included,
  };

  factory CropZone.fromJson(Map<String, dynamic> json) {
    final displayType = json['displayType'] as String? ?? 'APP_IPHONE_69';
    final orientation = Orientation.values[json['orientation'] as int? ?? 0];
    final locked = json['locked'] as bool? ?? true;
    final fallback = ScreenshotUtils.getDimensions(displayType, orientation);

    return CropZone(
      id: json['id'] as String,
      name: json['name'] as String?,
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      // A locked zone is defined by its format, so resolve from the format
      // rather than the stored rect — that keeps files valid if a format's
      // official dimensions ever change.
      size: locked
          ? fallback
          : Size(
              (json['width'] as num?)?.toDouble() ?? fallback.width,
              (json['height'] as num?)?.toDouble() ?? fallback.height,
            ),
      displayType: displayType,
      orientation: orientation,
      locked: locked,
      included: json['included'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropZone &&
          other.id == id &&
          other.name == name &&
          other.position == position &&
          other.size == size &&
          other.displayType == displayType &&
          other.orientation == orientation &&
          other.locked == locked &&
          other.included == included;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    position,
    size,
    displayType,
    orientation,
    locked,
    included,
  );
}
