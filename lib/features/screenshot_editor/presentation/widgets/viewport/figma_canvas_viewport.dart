import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_viewport_controller.dart';

/// A pannable/zoomable canvas viewport with Figma-style navigation on
/// desktop: two-finger trackpad scroll pans, pinch / Cmd+scroll zooms to the
/// pointer, plain mouse-wheel scroll pans, and holding Space + dragging pans
/// regardless of what's under the pointer.
///
/// On touch platforms this falls back to a plain [InteractiveViewer] wired
/// to the same [controller] — touch gesture behavior is intentionally left
/// unchanged.
class FigmaCanvasViewport extends StatefulWidget {
  const FigmaCanvasViewport({
    super.key,
    required this.controller,
    required this.child,
    this.constrainedOnTouch = false,
  });

  final CanvasViewportController controller;
  final Widget child;

  /// Value passed as `InteractiveViewer.constrained` on touch platforms
  /// only. Desktop always lays out [child] unconstrained (native size),
  /// since desktop navigation is driven by explicit zoom/pan rather than a
  /// FittedBox-style auto-fit.
  final bool constrainedOnTouch;

  static bool get isDesktopPlatform =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  State<FigmaCanvasViewport> createState() => _FigmaCanvasViewportState();
}

class _FigmaCanvasViewportState extends State<FigmaCanvasViewport> {
  // Physical space-key state, purely to decide the resting cursor/overlay
  // visibility before a drag starts.
  bool _spaceHeld = false;
  // True for the lifetime of an in-progress space-drag gesture. Kept
  // separate from _spaceHeld so releasing Space mid-drag doesn't unmount the
  // overlay's GestureDetector (which would cancel the gesture).
  bool _spacePanActive = false;
  bool _backgroundPanning = false;

  double _panZoomStartScale = 1.0;

  @override
  void initState() {
    super.initState();
    if (FigmaCanvasViewport.isDesktopPlatform) {
      HardwareKeyboard.instance.addHandler(_handleSpaceKey);
    }
  }

  @override
  void dispose() {
    if (FigmaCanvasViewport.isDesktopPlatform) {
      HardwareKeyboard.instance.removeHandler(_handleSpaceKey);
    }
    super.dispose();
  }

  bool _handleSpaceKey(KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.space) return false;
    // Never hijack space while a text field has focus.
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return false;
    }
    if (event is KeyDownEvent) {
      if (!_spaceHeld && mounted) setState(() => _spaceHeld = true);
    } else if (event is KeyUpEvent) {
      if (_spaceHeld && mounted) setState(() => _spaceHeld = false);
    }
    // Never consume — other handlers (shortcuts, text fields) still see it.
    return false;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final isZoomModifier =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (isZoomModifier) {
      final factor = math.exp(-event.scrollDelta.dy * 0.002);
      widget.controller.zoomBy(
        factor,
        viewportFocal: event.localPosition,
        animate: true,
      );
    } else {
      widget.controller.panBy(-event.scrollDelta);
    }
  }

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _panZoomStartScale = 1.0;
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    // Cmd/Ctrl + trackpad scroll arrives on this same pan-zoom event stream
    // (trackpad gestures are classified by input device, not modifier keys),
    // so it must be handled here too, not just in _onPointerSignal. Matches
    // Figma: modifier held converts the scroll into a zoom and suppresses
    // the pan for that event.
    final isZoomModifier =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (isZoomModifier) {
      if (event.panDelta != Offset.zero) {
        final factor = math.exp(-event.panDelta.dy * 0.01);
        widget.controller.zoomBy(factor, viewportFocal: event.localPosition);
      }
      return;
    }
    if (event.panDelta != Offset.zero) {
      widget.controller.panBy(event.panDelta);
    }
    if (event.scale != _panZoomStartScale && _panZoomStartScale != 0) {
      final factor = event.scale / _panZoomStartScale;
      widget.controller.zoomBy(factor, viewportFocal: event.localPosition);
      _panZoomStartScale = event.scale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        widget.controller.viewportSize = constraints.biggest;
        return FigmaCanvasViewport.isDesktopPlatform
            ? _buildDesktop(context)
            : _buildTouch(context);
      },
    );
  }

  Widget _buildTouch(BuildContext context) {
    return InteractiveViewer(
      transformationController: widget.controller,
      constrained: widget.constrainedOnTouch,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: widget.controller.minScale,
      maxScale: widget.controller.maxScale,
      child: widget.child,
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final showSpaceLayer = _spaceHeld || _spacePanActive;
    final cursor = _backgroundPanning || _spacePanActive
        ? SystemMouseCursors.grabbing
        : _spaceHeld
        ? SystemMouseCursors.grab
        : SystemMouseCursors.basic;

    return MouseRegion(
      cursor: cursor,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        onPointerPanZoomStart: _onPointerPanZoomStart,
        onPointerPanZoomUpdate: _onPointerPanZoomUpdate,
        child: ClipRect(
          child: Stack(
            children: [
              // Empty-canvas background drag pans the viewport. Sits behind
              // the content so element gesture detectors (drag/resize
              // handles, slot taps) hit-test first and win when the pointer
              // is actually over them.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) =>
                      setState(() => _backgroundPanning = true),
                  onPanUpdate: (details) =>
                      widget.controller.panBy(details.delta),
                  onPanEnd: (_) =>
                      setState(() => _backgroundPanning = false),
                  onPanCancel: () =>
                      setState(() => _backgroundPanning = false),
                ),
              ),
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  // Mirrors InteractiveViewer's own constrained:false
                  // technique: OverflowBox gives the Transform's child
                  // unbounded layout so it sizes to its natural extent,
                  // while Transform paints it panned/scaled without
                  // affecting the layout pass.
                  return OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Transform(
                      transform: widget.controller.value,
                      alignment: Alignment.topLeft,
                      child: widget.child,
                    ),
                  );
                },
              ),
              // Space-drag pan layer: opaque and on top, so it captures the
              // pointer before any element gesture detector can, guaranteeing
              // space+drag always pans regardless of what's underneath.
              if (showSpaceLayer)
                Positioned.fill(
                  child: MouseRegion(
                    cursor: _spacePanActive
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) =>
                          setState(() => _spacePanActive = true),
                      onPanUpdate: (details) =>
                          widget.controller.panBy(details.delta),
                      onPanEnd: (_) =>
                          setState(() => _spacePanActive = false),
                      onPanCancel: () =>
                          setState(() => _spacePanActive = false),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
