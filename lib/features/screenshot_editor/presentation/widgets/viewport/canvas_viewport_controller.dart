import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A [TransformationController] with Figma-style navigation helpers layered
/// on top: fit-to-rect, zoom-to-point, and animated transitions between
/// them. Both the single editor canvas and the multi-screenshot canvas share
/// one instance of this controller type via [FigmaCanvasViewport], so they
/// get identical navigation behavior from one implementation.
class CanvasViewportController extends TransformationController {
  CanvasViewportController({
    required TickerProvider vsync,
    this.minScale = 0.05,
    this.maxScale = 4.0,
  }) : _animController = AnimationController(
         vsync: vsync,
         duration: const Duration(milliseconds: 250),
       ) {
    _animController.addListener(_onAnimTick);
  }

  final double minScale;
  final double maxScale;
  final AnimationController _animController;
  Animation<Matrix4>? _animation;

  /// The matrix the in-flight animation is heading toward, or null when
  /// idle. Rapid successive zoom calls (fast scroll-wheel detents, quick
  /// double-clicks on the zoom buttons) each land before the previous 120ms
  /// animation finishes; computing the next target from this instead of the
  /// transient mid-animation [value] makes them compound correctly instead
  /// of each one restarting from — and collapsing onto — a single step.
  Matrix4? _targetMatrix;

  /// Size of the viewport this controller is driving, in logical pixels.
  /// The [FigmaCanvasViewport] reports this on every layout.
  Size viewportSize = Size.zero;

  double get scale => value.getMaxScaleOnAxis();

  void _onAnimTick() {
    final anim = _animation;
    if (anim != null) {
      value = anim.value;
      if (_animController.isCompleted) _targetMatrix = null;
    }
  }

  void _animateTo(Matrix4 target, {Duration? duration}) {
    _animController.duration = duration ?? const Duration(milliseconds: 250);
    _animation = Matrix4Tween(begin: value, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _targetMatrix = target;
    _animController
      ..stop()
      ..reset()
      ..forward();
  }

  /// Cancels any in-flight animation and jumps straight to [target].
  void jumpTo(Matrix4 target) {
    _animController.stop();
    _targetMatrix = null;
    value = target;
  }

  /// Frames [worldRect] (padded by [padding] on each side) in the viewport,
  /// clamped to [minScale]/[maxScale]. No-ops if the viewport size hasn't
  /// been reported yet or the rect is empty.
  void zoomToRect(Rect worldRect, {double padding = 0, bool animate = true}) {
    if (viewportSize.isEmpty) return;
    final contentW = worldRect.width + padding * 2;
    final contentH = worldRect.height + padding * 2;
    if (contentW <= 0 || contentH <= 0) return;

    final scaleX = (viewportSize.width / contentW).clamp(minScale, maxScale);
    final scaleY = (viewportSize.height / contentH).clamp(minScale, maxScale);
    final fitScale = math.min(scaleX, scaleY);

    final cx = worldRect.left + worldRect.width / 2;
    final cy = worldRect.top + worldRect.height / 2;
    final tx = viewportSize.width / 2 - cx * fitScale;
    final ty = viewportSize.height / 2 - cy * fitScale;

    final target = Matrix4.diagonal3Values(fitScale, fitScale, 1)
      ..setTranslationRaw(tx, ty, 0);
    animate ? _animateTo(target) : jumpTo(target);
  }

  /// The scale successive animated zoom calls should compound from: the
  /// in-flight animation's target if one exists, otherwise the live value.
  /// Using this (rather than the live mid-animation value) for both
  /// [setScale] and [zoomBy] keeps a burst of rapid calls — fast scroll-wheel
  /// detents, quick zoom-button clicks — landing on the intended cumulative
  /// result instead of each one restarting from wherever the animation
  /// happened to be and collapsing onto just the last step.
  double get _referenceScale =>
      (_targetMatrix ?? value).getMaxScaleOnAxis();

  /// Sets the absolute [target] scale, keeping [viewportFocal] (defaults to
  /// viewport center) fixed on screen.
  void setScale(double target, {Offset? viewportFocal, bool animate = true}) {
    _zoomToScale(
      target.clamp(minScale, maxScale),
      viewportFocal: viewportFocal,
      animate: animate,
    );
  }

  /// Multiplies the current scale by [factor] around [viewportFocal]
  /// (defaults to viewport center), clamped to [minScale]/[maxScale].
  void zoomBy(double factor, {Offset? viewportFocal, bool animate = false}) {
    final referenceScale = animate ? _referenceScale : scale;
    if (referenceScale <= 0) return;
    _zoomToScale(
      (referenceScale * factor).clamp(minScale, maxScale),
      viewportFocal: viewportFocal,
      animate: animate,
    );
  }

  void _zoomToScale(
    double targetScale, {
    Offset? viewportFocal,
    required bool animate,
  }) {
    final focal =
        viewportFocal ??
        Offset(viewportSize.width / 2, viewportSize.height / 2);
    final current = animate ? (_targetMatrix ?? value) : value;
    final currentScale = current.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final appliedFactor = targetScale / currentScale;

    final result = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(appliedFactor, appliedFactor, appliedFactor, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1)
      ..multiply(current);

    animate
        ? _animateTo(result, duration: const Duration(milliseconds: 120))
        : jumpTo(result);
  }

  /// Translates the view by [delta] (in viewport pixels), cancelling any
  /// in-flight animation. Used for direct-manipulation panning (trackpad,
  /// background drag, space-drag) where the transform must track the
  /// pointer 1:1 with no easing.
  void panBy(Offset delta) {
    _animController.stop();
    _targetMatrix = null;
    value = (Matrix4.identity()
      ..translateByDouble(delta.dx, delta.dy, 0, 1)
      ..multiply(value));
  }

  @override
  void dispose() {
    _animController.removeListener(_onAnimTick);
    _animController.dispose();
    super.dispose();
  }
}
