import 'package:flutter/foundation.dart';

/// Active snap guide line positions during a drag.
///
/// Published through a [ValueNotifier] (see `ScreenshotEditorCubit.snapLines`)
/// rather than the bloc state, so showing/hiding guides only repaints the thin
/// guide layer instead of rebuilding the whole canvas.
@immutable
class SnapLines {
  const SnapLines({this.x, this.y});

  /// Vertical guide line x-position, or null when not snapped horizontally.
  final double? x;

  /// Horizontal guide line y-position, or null when not snapped vertically.
  final double? y;

  bool get isEmpty => x == null && y == null;

  @override
  bool operator ==(Object other) =>
      other is SnapLines && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
