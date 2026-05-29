import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Shared interaction wrapper for canvas overlays (image, icon, text).
///
/// The overlay's gesture layer is sized to the full transformed
/// (scale + rotation) axis-aligned bounding box (AABB) of [content], so drag
/// gestures are detected everywhere the overlay is visible — even when the
/// overlay is scaled up. The [scale]/[rotation]/[flipX]/[flipY] transforms are
/// applied as paint-only inner layers.
///
/// Flutter's `RenderBox.hitTest` gates on `size.contains(position)` using the
/// *unscaled* layout box, and `RenderTransform` does not override `hitTest`.
/// Nesting a `GestureDetector` inside a `Transform.scale` therefore clips its
/// hittable region to the unscaled size — touches on the enlarged area fall
/// through. Sizing the gesture layer to the AABB instead fixes that.
///
/// The AABB box is centered on the overlay's visual center, which sits at
/// `position + contentSize / 2` (center-aligned scaling does not move the
/// center). Because the AABB differs from [contentSize], the caller must wrap
/// the whole overlay subtree (this widget plus any MouseRegion / Opacity /
/// selection border) in `Transform.translate(offset: aabbOffset(...))` so the
/// box stays centered on that point. See [aabbOffset].
class OverlayInteractionBox extends StatelessWidget {
  const OverlayInteractionBox({
    super.key,
    required this.contentSize,
    required this.scale,
    required this.rotation,
    required this.content,
    required this.gestureChild,
    this.flipX = false,
    this.flipY = false,
    this.contentInteractive = false,
    this.overlayChildren = const [],
  });

  /// Untransformed content size (w × h).
  final Size contentSize;
  final double scale;

  /// Rotation in radians.
  final double rotation;
  final bool flipX;
  final bool flipY;

  /// The painted overlay content, at its untransformed size.
  final Widget content;

  /// The gesture layer — typically a `GestureDetector` with
  /// `HitTestBehavior.opaque`. Stretched to fill the AABB.
  final Widget gestureChild;

  /// When true, [content] receives pointer events (e.g. an editable
  /// `TextField`) and is not wrapped in [IgnorePointer].
  final bool contentInteractive;

  /// Extra widgets painted above the gesture + content layers, e.g. resize
  /// handles. Each should position itself within the AABB Stack.
  final List<Widget> overlayChildren;

  /// AABB of [contentSize] after applying [scale] and [rotation].
  static Size aabbSize(Size contentSize, double scale, double rotation) {
    final cos = math.cos(rotation).abs();
    final sin = math.sin(rotation).abs();
    final w = contentSize.width * scale;
    final h = contentSize.height * scale;
    return Size(w * cos + h * sin, w * sin + h * cos);
  }

  /// Offset that re-centers the AABB box on the overlay's visual center.
  /// Apply via a `Transform.translate` wrapping the whole overlay subtree.
  static Offset aabbOffset(Size contentSize, double scale, double rotation) {
    final aabb = aabbSize(contentSize, scale, rotation);
    return Offset(
      (contentSize.width - aabb.width) / 2,
      (contentSize.height - aabb.height) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final aabb = aabbSize(contentSize, scale, rotation);

    // OverflowBox hands [content] unbounded constraints so it always lays out
    // at its natural size — the AABB box may be a rough estimate (e.g. for an
    // icon glyph), and constraining the content to it would clip the overflow.
    final contentLayer = OverflowBox(
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Transform.flip(
            flipX: flipX,
            flipY: flipY,
            child: content,
          ),
        ),
      ),
    );

    return SizedBox(
      width: aabb.width,
      height: aabb.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: gestureChild),
          Positioned.fill(
            child: contentInteractive
                ? contentLayer
                : IgnorePointer(child: contentLayer),
          ),
          ...overlayChildren,
        ],
      ),
    );
  }
}
