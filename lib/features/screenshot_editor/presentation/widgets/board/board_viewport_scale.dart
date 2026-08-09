import 'package:flutter/material.dart';

import '../viewport/canvas_viewport_controller.dart';

/// Publishes the canvas viewport's zoom to the selection chrome drawn inside
/// the board.
///
/// Board coordinates are screenshot-resolution — a three-zone iPhone board is
/// over 4,500px wide — so the canvas sits at a very low zoom by default. A
/// handle sized in board pixels therefore shrinks with the zoom: 44 board px
/// is 11 screen px on a fitted desktop window and under 4 on a phone, well
/// below a usable touch target.
///
/// Chrome divides its sizes by [BoardViewportScale.of] so it keeps a constant
/// on-screen size at any zoom, the way every canvas editor handles it. Only
/// chrome does this; anything that lands in an exported image stays in board
/// coordinates.
class BoardViewportScale extends InheritedNotifier<CanvasViewportController> {
  const BoardViewportScale({
    super.key,
    required CanvasViewportController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Smallest zoom the divisor honours. Below this the reciprocal explodes and
  /// chrome would swamp the canvas.
  static const double minScale = 0.02;
  static const double maxScale = 4.0;

  /// Current viewport zoom, or 1.0 when there is no viewport above — during a
  /// capture, and in widget tests that mount a frame on its own.
  static double of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<BoardViewportScale>();
    final scale = widget?.notifier?.scale ?? 1.0;
    if (scale.isNaN || scale <= 0) return 1.0;
    return scale.clamp(minScale, maxScale);
  }

  /// [base] board pixels adjusted so the result covers a constant number of
  /// screen pixels at [scale].
  ///
  /// Pulled out as a plain function so the relationship is testable without a
  /// viewport: at scale 1 it is the identity, and below that it grows.
  static double size(double base, double scale) {
    final s = (scale.isNaN || scale <= 0) ? 1.0 : scale.clamp(minScale, maxScale);
    return base / s;
  }
}
