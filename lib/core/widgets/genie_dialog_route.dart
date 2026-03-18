import 'dart:io';

import 'package:flutter/material.dart';

/// A custom [PopupRoute] that animates a dialog emerging from a source [Rect],
/// creating a "genie" effect where the dialog appears to grow out of the
/// source widget (e.g. a FAB button).
class GenieDialogRoute<T> extends PopupRoute<T> {
  GenieDialogRoute({
    required this.builder,
    required this.sourceRect,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = const Color(0x80000000),
  });

  final WidgetBuilder builder;
  final Rect sourceRect;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Color barrierColor;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _GenieTransition(
      animation: animation,
      sourceRect: sourceRect,
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }
}

class _GenieTransition extends StatelessWidget {
  const _GenieTransition({
    required this.animation,
    required this.sourceRect,
    required this.child,
    this.isPageRoute = false,
  });

  final Animation<double> animation;
  final Rect sourceRect;
  final Widget child;
  final bool isPageRoute;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Convert the source rect's centre into an Alignment (-1..1, -1..1)
    // so the scale transform originates from the FAB's position.
    final sourceAlignX = (sourceRect.center.dx / screenWidth) * 2.0 - 1.0;
    final sourceAlignY = (sourceRect.center.dy / screenHeight) * 2.0 - 1.0;
    final sourceAlignment = Alignment(sourceAlignX, sourceAlignY);

    // ── Curves ──
    // Main curve: smooth deceleration for the scale/position
    final curvedForward = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Fade in quickly at the start
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    // ── Scale ──
    // Start at a small non-zero scale so it feels like the FAB is expanding
    final scaleAnimation = Tween<double>(
      begin: 0.05,
      end: 1.0,
    ).animate(curvedForward);

    // ── Alignment ──
    // Animate the transform origin from the FAB's position to centre
    // so the dialog "slides" to centre as it expands.
    final alignAnimation = AlignmentTween(
      begin: sourceAlignment,
      end: Alignment.center,
    ).animate(curvedForward);

    // ── Border radius ──
    // Start with a pill-like radius (matching FAB) → 0 for pages, 28 for dialogs
    final radiusAnimation = Tween<double>(
      begin: 24.0,
      end: isPageRoute ? 0.0 : 28.0,
    ).animate(curvedForward);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = scaleAnimation.value;
        final align = alignAnimation.value;
        final opacity = fadeAnimation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Align(
            alignment: align,
            child: Transform.scale(
              scale: scale,
              alignment: align,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radiusAnimation.value),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows a dialog with a genie animation emerging from [sourceRect].
Future<T?> showGenieDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required Rect sourceRect,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = const Color(0x80000000),
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    GenieDialogRoute<T>(
      builder: builder,
      sourceRect: sourceRect,
      barrierDismissible: barrierDismissible,
      barrierLabel:
          barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
    ),
  );
}

/// Creates a genie-style page route from [sourceRect] for full-page routes
/// (mobile) with iOS-style swipe-to-dismiss gesture support.
///
/// The user can swipe down to interactively dismiss the page with a smooth
/// scale-down and translation effect, similar to iOS fullscreen photo viewer.
PageRoute<T> geniePageRoute<T>({
  required WidgetBuilder builder,
  required Rect sourceRect,
  bool enableSwipeToDismiss = true,
}) {
  return _GeniePageRoute<T>(
    builder: builder,
    sourceRect: sourceRect,
    enableSwipeToDismiss: enableSwipeToDismiss,
  );
}

/// A full-page route with genie transition + interactive swipe-to-dismiss.
class _GeniePageRoute<T> extends PageRoute<T> {
  _GeniePageRoute({
    required this.builder,
    required this.sourceRect,
    this.enableSwipeToDismiss = true,
  });

  final WidgetBuilder builder;
  final Rect sourceRect;
  final bool enableSwipeToDismiss;

  /// Set to true when the route is dismissed via swipe gesture.
  /// When true, the reverse transition continues the drag motion
  /// instead of using the genie animation (shrink-to-source).
  bool _dismissedBySwipe = false;

  /// Snapshot of the drag state at the moment of swipe dismiss.
  /// Used to create a seamless continuation of the drag motion.
  Offset _dismissDragOffset = Offset.zero;
  double _dismissScale = 1.0;
  double _dismissBorderRadius = 0.0;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // When dismissed by swipe, continue the drag motion naturally
    if (_dismissedBySwipe) {
      return _SwipeDismissTransition(
        animation: animation,
        startOffset: _dismissDragOffset,
        startScale: _dismissScale,
        startBorderRadius: _dismissBorderRadius,
        child: child,
      );
    }

    final genie = _GenieTransition(
      animation: animation,
      sourceRect: sourceRect,
      isPageRoute: true,
      child: child,
    );

    // Only wrap with swipe-to-dismiss when fully presented and enabled
    if (!enableSwipeToDismiss) return genie;

    return _SwipeToDismissWrapper(
      animation: animation,
      route: this,
      child: genie,
    );
  }
}

/// Wraps a child with an interactive vertical-swipe-to-dismiss gesture.
///
/// During the drag, the page scales down and translates vertically following the
/// finger, with the background fading through. On release, if the drag exceeds
/// 20% of the screen height (or a fast fling), the route pops; otherwise, the
/// page snaps back with a spring animation.
class _SwipeToDismissWrapper extends StatefulWidget {
  const _SwipeToDismissWrapper({
    required this.animation,
    required this.route,
    required this.child,
  });

  final Animation<double> animation;
  final PageRoute route;
  final Widget child;

  @override
  State<_SwipeToDismissWrapper> createState() => _SwipeToDismissWrapperState();
}

class _SwipeToDismissWrapperState extends State<_SwipeToDismissWrapper>
    with SingleTickerProviderStateMixin {
  /// Current 2D drag offset (tracks both horizontal and vertical movement).
  Offset _dragOffset = Offset.zero;

  /// Whether a dismiss drag is actively in progress.
  bool _isDragging = false;

  /// Controller used to animate the snap-back when the user releases
  /// without exceeding the dismiss threshold.
  late final AnimationController _snapBackController;

  /// The offset at the moment the user released (used for snap-back lerp).
  Offset _snapBackStartOffset = Offset.zero;

  /// Minimum scale when fully dragged to dismiss threshold.
  static const double _minScale = 0.85;

  /// Corner radius applied during the drag.
  static const double _dragCornerRadius = 80.0;

  /// Fraction of screen height needed to trigger dismiss.
  /// Desktop uses a higher threshold to avoid accidental mouse/trackpad dismissals.
  static final double _dismissThreshold =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux ? 0.35 : 0.20;

  /// Fling velocity magnitude (pixels/second) that triggers an immediate dismiss.
  static final double _flingVelocity =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux
      ? 1200.0
      : 700.0;

  @override
  void initState() {
    super.initState();
    _snapBackController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          setState(() {
            final t = Curves.easeOut.transform(_snapBackController.value);
            _dragOffset = _snapBackStartOffset * (1.0 - t);
          });
        });
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  bool get _isFullyPresented =>
      widget.animation.status == AnimationStatus.completed;

  void _onPanStart(DragStartDetails details) {
    if (!_isFullyPresented) return;
    _snapBackController.stop();
    // Signal the navigator that a user gesture is in progress.
    // This disables Hero animations, matching CupertinoPageRoute behavior.
    final navigator = Navigator.of(context);
    navigator.didStartUserGesture();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final navigator = Navigator.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dragFraction = (_dragOffset.distance / screenHeight).clamp(0.0, 1.0);
    final velocityMagnitude = details.velocity.pixelsPerSecond.distance;

    final shouldDismiss =
        dragFraction > _dismissThreshold || velocityMagnitude > _flingVelocity;

    if (shouldDismiss) {
      // Compute current visual state to snapshot (same formulas as build())
      final currentScale = 1.0 - (1.0 - _minScale) * dragFraction;
      final currentBorderRadius =
          _dragCornerRadius * (dragFraction * 3.0).clamp(0.0, 1.0);

      // Snapshot drag state so the reverse transition can continue the motion
      final route = widget.route;
      if (route is _GeniePageRoute) {
        route._dismissedBySwipe = true;
        route._dismissDragOffset = _dragOffset;
        route._dismissScale = currentScale;
        route._dismissBorderRadius = currentBorderRadius;
      }
      setState(() {
        _isDragging = false;
      });
      navigator.pop();
    } else {
      // Snap back
      _snapBackStartOffset = _dragOffset;
      _snapBackController.forward(from: 0.0);
      setState(() {
        _isDragging = false;
      });
    }
    // Signal that the user gesture has ended
    navigator.didStopUserGesture();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dragFraction = (_dragOffset.distance / screenHeight).clamp(0.0, 1.0);

    // Scale: 1.0 → _minScale as drag progresses
    final scale = 1.0 - (1.0 - _minScale) * dragFraction;

    // Corner radius: 0 → _dragCornerRadius as drag progresses
    final borderRadius =
        _dragCornerRadius * (dragFraction * 3.0).clamp(0.0, 1.0);

    // Background opacity: fade out behind the scaled-down page
    final backgroundOpacity = (1.0 - dragFraction * 1.5).clamp(0.0, 1.0);

    final isActive = _isDragging || _dragOffset.distance > 0.01;

    Widget content = widget.child;

    if (isActive) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          // Semi-transparent barrier that fades as the user drags
          ColoredBox(color: Colors.black.withValues(alpha: backgroundOpacity)),
          // Transformed page content
          Transform.translate(
            offset: _dragOffset,
            child: Transform.scale(
              scale: scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: widget.child,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: content,
    );
  }
}

/// A transition that continues the drag-dismiss motion naturally.
///
/// Instead of a jarring fade, this smoothly scales down further,
/// continues translating in the drag direction, and fades out the
/// background – creating a seamless continuation of the user's gesture.
class _SwipeDismissTransition extends StatelessWidget {
  const _SwipeDismissTransition({
    required this.animation,
    required this.startOffset,
    required this.startScale,
    required this.startBorderRadius,
    required this.child,
  });

  final Animation<double> animation;
  final Offset startOffset;
  final double startScale;
  final double startBorderRadius;
  final Widget child;

  /// The final scale at fully dismissed.
  static const double _endScale = 0.65;

  /// How far (in pixels) to continue the translate as the animation runs.
  static const double _extraTranslate = 120.0;

  /// Final corner radius for the fully-dismissed state.
  static const double _endBorderRadius = 32.0;

  @override
  Widget build(BuildContext context) {
    // animation.value goes from 1 → 0 during reverse.
    // progress goes from 0 → 1 as we move toward fully dismissed.
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final progress = 1.0 - curved.value;

    // Scale: from startScale → _endScale
    final scale = startScale - (startScale - _endScale) * progress;

    // Translate: continue in the drag direction
    final direction = startOffset.distance > 0.01
        ? startOffset / startOffset.distance
        : const Offset(0, 1);
    final offset = startOffset + direction * _extraTranslate * progress;

    // Border radius: from startBorderRadius → _endBorderRadius
    final borderRadius =
        startBorderRadius + (_endBorderRadius - startBorderRadius) * progress;

    // Opacity: fade out smoothly
    final opacity = (1.0 - progress * 1.2).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Extracts the on-screen [Rect] of the widget at [context].
///
/// Returns `null` if the render object is not available.
Rect? rectFromContext(BuildContext context) {
  final renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.hasSize) return null;
  final position = renderBox.localToGlobal(Offset.zero);
  return position & renderBox.size;
}
