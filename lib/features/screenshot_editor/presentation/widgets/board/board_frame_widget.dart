import 'dart:io';
import 'dart:math' as math;

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/frame_element.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/image_picker_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_viewport_scale.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/import_hint_placeholder.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The rotation glyph shown when a frame corner is hovered.
///
/// Drawn rather than taken from the icon set because a single icon can only
/// point one way — reused at four corners, three of them read as pointing into
/// the frame or off into space. This sweeps an arc *around* the corner it
/// belongs to, so each corner gets a glyph that matches the motion it performs.
///
/// The painter fills the whole rotate pad and pivots on its centre, which is
/// the frame's corner, so the arc always lands in that corner's outer quadrant
/// — outside the border, clear of the artwork.
class _CornerRotateGlyphPainter extends CustomPainter {
  _CornerRotateGlyphPainter({
    required this.corner,
    required this.color,
    required this.haloColor,
  });

  /// Which corner this glyph sits on, as a ±1 alignment.
  final Alignment corner;
  final Color color;

  /// Drawn underneath as a wider stroke. The glyph floats over the board
  /// background, whose colour the user controls, so it carries its own
  /// contrast rather than assuming a dark canvas.
  final Color haloColor;

  /// Arc radius and stroke, as fractions of the pad.
  static const double _radiusFactor = 0.30;
  static const double _strokeFactor = 0.085;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * _radiusFactor;
    final stroke = size.shortestSide * _strokeFactor;

    // The quarter turn centred on this corner's outward diagonal: the arc
    // spans the 90° the corner itself occupies.
    final start = BoardFrameWidget.rotateGlyphStartAngle(corner);
    const sweep = BoardFrameWidget.rotateGlyphSweep;

    final arc = Path()
      ..addArc(Rect.fromCircle(center: pivot, radius: radius), start, sweep);

    // An arrowhead at each end: rotation runs both ways, and a single head
    // would imply the drag only turns one direction.
    final head = stroke * 1.9;

    Path arrowAt(double angle, double direction) {
      final radial = Offset(math.cos(angle), math.sin(angle));
      // Flip the tangent at the start end so each head points outward, away
      // from the arc, rather than both chasing the same way round.
      final tangent =
          Offset(-math.sin(angle), math.cos(angle)) * direction;
      final base = pivot + radial * radius;

      return Path()
        ..moveTo(base.dx + tangent.dx * head, base.dy + tangent.dy * head)
        ..lineTo(
          base.dx + radial.dx * head * 0.72,
          base.dy + radial.dy * head * 0.72,
        )
        ..lineTo(
          base.dx - radial.dx * head * 0.72,
          base.dy - radial.dy * head * 0.72,
        )
        ..close();
    }

    final arrow = Path()
      ..addPath(arrowAt(start + sweep, 1), Offset.zero)
      ..addPath(arrowAt(start, -1), Offset.zero);

    for (final pass in [true, false]) {
      final paint = Paint()
        ..color = pass ? haloColor.withValues(alpha: 0.85) : color
        ..strokeCap = StrokeCap.round;

      canvas
        ..drawPath(
          arc,
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = pass ? stroke * 2.4 : stroke,
        )
        ..drawPath(
          arrow,
          Paint()
            ..color = paint.color
            ..style = pass ? PaintingStyle.stroke : PaintingStyle.fill
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = stroke * 1.4,
        );
    }
  }

  @override
  bool shouldRepaint(_CornerRotateGlyphPainter old) =>
      old.corner != corner ||
      old.color != color ||
      old.haloColor != haloColor;
}

/// One [FrameElement] rendered on the board, draggable and resizable.
///
/// Drag/resize state is local for the duration of the gesture so the cubit is
/// touched once on release — one undo entry per gesture, and no board-wide
/// rebuild per pointer move. Mirrors how [DraggableFrameWidget] behaves in the
/// single-artboard editor.
class BoardFrameWidget extends StatefulWidget {
  const BoardFrameWidget({
    super.key,
    required this.frame,
    required this.isSelected,
    required this.showChrome,
  });

  final FrameElement frame;
  final bool isSelected;

  /// Whether selection borders and resize handles may be drawn. Turned off
  /// during capture so export pixels carry no editor chrome.
  final bool showChrome;

  /// Side length of a corner resize handle, in board pixels. Board coordinates
  /// are screenshot-resolution, so handles must be large to stay usable when
  /// the viewport is zoomed out.
  static const double handleSize = 44.0;

  /// Thickness of the rotate grab band running along each edge, in board
  /// pixels. Corners stay reserved for resize, so a band stops [handleSize]
  /// short of each end.
  static const double rotateBand = 40.0;

  /// Side length of the rotate pad straddling each corner, in board pixels.
  ///
  /// Bigger than [handleSize] and centred on the same point, so the corner
  /// reads as resize-in-the-middle, rotate-around-it — the split design tools
  /// use, with the resize handle winning the overlap.
  ///
  /// It must straddle the corner rather than sit wholly outside it: a
  /// `Positioned` child beyond its `Stack`'s bounds still paints under
  /// `Clip.none`, but `RenderBox.hitTest` rejects any position outside the
  /// parent, so a fully-outside pad would take no hover or drag at all.
  static const double rotateCornerSize = 128.0;

  /// How far the frame's interactive box extends past the frame on each side,
  /// in board pixels.
  ///
  /// Rotate affordances belong outside the border, and Flutter will not
  /// hit-test a child positioned beyond its parent's bounds — so the box has to
  /// reach out there for them to receive a pointer at all. Must be at least
  /// half [rotateCornerSize] so a corner pad is fully live.
  static const double chromeMargin = 96.0;

  /// Increment the rotation snaps to while Shift is held, in degrees.
  static const double snapDegrees = 15.0;

  /// Smallest side a frame can be dragged to, in board pixels. Below this the
  /// handles overlap and the frame can no longer be grabbed to resize back out.
  static const double minSide = handleSize * 2;

  /// Angular span of a corner's rotation glyph — the quarter turn that corner
  /// occupies.
  static const double rotateGlyphSweep = math.pi / 2;

  /// Start angle of the rotation glyph arc at [corner], in radians, measured
  /// from the frame's corner. Centring the sweep on the corner's outward
  /// diagonal is what keeps the glyph in that corner's outer quadrant.
  static double rotateGlyphStartAngle(Alignment corner) =>
      math.atan2(corner.y, corner.x) - rotateGlyphSweep / 2;

  /// Rotates [v] by [angle] radians.
  static Offset rotateVector(Offset v, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  /// The rect produced by dragging [corner] of a frame by [delta], holding the
  /// opposite corner fixed on screen. Returns `null` if the result would be
  /// smaller than [minSide].
  ///
  /// The resize handles live inside the chrome's rotation, so [delta] arrives
  /// in the frame's own axes — dragging the corner of a tilted frame grows it
  /// along the direction the pointer is actually moving.
  ///
  /// The model stores an axis-aligned rect that is rotated about its centre at
  /// paint time, so changing the size also moves the centre, which would swing
  /// the frame away under the cursor. The new origin is therefore derived from
  /// the opposite corner: that point is held fixed in board space and the rect
  /// rebuilt around it. At zero rotation this reduces to plain edge arithmetic.
  static (Offset, Size)? resizeFromCorner({
    required Offset position,
    required Size size,
    required double angle,
    required Alignment corner,
    required Offset delta,
  }) {
    // corner.x/y are -1 or 1: a -1 edge shrinks as the pointer moves positive.
    final width = size.width + corner.x * delta.dx;
    final height = size.height + corner.y * delta.dy;
    if (width < minSide || height < minSide) return null;

    final centre = position + Offset(size.width / 2, size.height / 2);

    // The opposite corner in local axes, before and after the resize.
    final oppositeBefore = Offset(
      -corner.x * size.width / 2,
      -corner.y * size.height / 2,
    );
    final oppositeAfter = Offset(-corner.x * width / 2, -corner.y * height / 2);

    final pinned = centre + rotateVector(oppositeBefore, angle);
    final nextCentre = pinned - rotateVector(oppositeAfter, angle);

    return (
      nextCentre - Offset(width / 2, height / 2),
      Size(width, height),
    );
  }

  @override
  State<BoardFrameWidget> createState() => _BoardFrameWidgetState();
}

class _BoardFrameWidgetState extends State<BoardFrameWidget> {
  Offset? _dragPosition;
  Size? _dragSize;

  /// Corner whose rotate pad the pointer is currently over, if any.
  Alignment? _hoveredRotateCorner;

  /// Live rotation while an edge is being dragged, plus the pointer angle and
  /// frame rotation the gesture started from.
  double? _dragRotation;
  double _rotateStartPointerAngle = 0;
  double _rotateStartRotation = 0;

  /// Identifies this frame's box so pointer positions can be converted into
  /// frame-local coordinates, which is what makes rotation correct at any
  /// viewport zoom or pan.
  final GlobalKey _boxKey = GlobalKey();

  BoardCubit get _cubit => context.read<BoardCubit>();

  Offset get _position => _dragPosition ?? widget.frame.position;
  Size get _size => _dragSize ?? widget.frame.size;
  double get _rotation => _dragRotation ?? widget.frame.rotation;

  void _startGesture() {
    _cubit.selectFrame(widget.frame.id);
    _cubit.beginBatchEdit();
    _dragPosition = widget.frame.position;
    _dragSize = widget.frame.size;
  }

  void _endGesture() {
    if (_dragPosition == null && _dragSize == null && _dragRotation == null) {
      return;
    }
    // A tap that registers as a zero-distance pan would otherwise commit an
    // identical frame and leave a do-nothing entry in the undo history.
    final moved = _position != widget.frame.position ||
        _size != widget.frame.size ||
        _rotation != widget.frame.rotation;
    if (moved) {
      _cubit.updateFrame(
        widget.frame.copyWith(
          position: _position,
          size: _size,
          rotation: _rotation,
        ),
      );
    }
    _cubit.endBatchEdit();
    setState(() {
      _dragPosition = null;
      _dragSize = null;
      _dragRotation = null;
    });
  }

  void _onMove(Offset delta) {
    setState(() => _dragPosition = _position + delta);
  }

  /// Resizes from a corner, keeping the opposite corner visually pinned.
  void _onResize(Alignment corner, Offset delta) {
    final next = BoardFrameWidget.resizeFromCorner(
      position: _position,
      size: _size,
      angle: _rotation,
      corner: corner,
      delta: delta,
    );
    if (next == null) return;

    setState(() {
      _dragPosition = next.$1;
      _dragSize = next.$2;
    });
  }

  // ---------------------------------------------------------------------------
  // Rotation
  // ---------------------------------------------------------------------------

  /// Angle of [globalPosition] measured from the frame's centre.
  ///
  /// Converting through the frame's own [RenderBox] rather than accumulating
  /// pan deltas keeps this correct however the canvas viewport is zoomed or
  /// panned, and means the frame tracks the pointer exactly instead of drifting
  /// over a long drag.
  double? _pointerAngle(Offset globalPosition) {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(globalPosition);
    final centre = Offset(box.size.width / 2, box.size.height / 2);
    final v = local - centre;
    if (v.distance < 1) return null; // Ambiguous at the pivot.
    return math.atan2(v.dy, v.dx);
  }

  void _startRotate(Offset globalPosition) {
    _cubit.selectFrame(widget.frame.id);
    _cubit.beginBatchEdit();
    _rotateStartRotation = widget.frame.rotation;
    _rotateStartPointerAngle = _pointerAngle(globalPosition) ?? 0;
    setState(() => _dragRotation = widget.frame.rotation);
  }

  void _onRotate(Offset globalPosition) {
    final angle = _pointerAngle(globalPosition);
    if (angle == null) return;

    var next = _rotateStartRotation + (angle - _rotateStartPointerAngle);

    // Shift snaps to fixed increments, the usual design-tool shortcut for
    // landing on a clean angle.
    if (HardwareKeyboard.instance.isShiftPressed) {
      final step = BoardFrameWidget.snapDegrees * math.pi / 180;
      next = (next / step).roundToDouble() * step;
    }

    setState(() => _dragRotation = next);
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frame;
    final chrome = widget.showChrome && widget.isSelected;

    // Chrome sizes are board pixels at zoom 1 and grow as the canvas zooms
    // out, so handles stay the same size on screen. Only frames actually
    // drawing chrome subscribe to the zoom, so a board full of unselected
    // frames does not rebuild on every pan.
    final chromeScale = chrome ? BoardViewportScale.of(context) : 1.0;
    final m = BoardViewportScale.size(
      BoardFrameWidget.chromeMargin,
      chromeScale,
    );

    // The box extends past the frame by [chromeMargin] on every side. Flutter
    // will not hit-test a child outside its parent's bounds — it paints under
    // Clip.none but takes no pointer — so affordances that belong *outside* the
    // border only work if the box itself reaches out there. The margin is
    // symmetric, so the box centre is still the frame centre and the rotation
    // pivot is unaffected.
    return Positioned(
      left: _position.dx - m,
      top: _position.dy - m,
      width: _size.width + m * 2,
      height: _size.height + m * 2,
      child: RepaintBoundary(
        key: _boxKey,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Only the frame rect selects and drags. The margin stays inert so
            // a frame does not swallow clicks in the empty space around it.
            Positioned(
              left: m,
              top: m,
              width: _size.width,
              height: _size.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _cubit.selectFrame(frame.id),
                onPanStart: (_) => _startGesture(),
                onPanUpdate: (details) => _onMove(details.delta),
                onPanEnd: (_) => _endGesture(),
                onPanCancel: _endGesture,
                onSecondaryTapUp: (details) =>
                    _showContextMenu(context, details),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Opacity(
                    opacity: frame.opacity.clamp(0.0, 1.0),
                    child: _buildFrameContent(frame),
                  ),
                ),
              ),
            ),
            // Selection chrome turns with the frame, so the box always
            // outlines the device rather than its axis-aligned bounds.
            // Only the in-plane rotation is applied — folding in the
            // perspective tilts would skew the handles out of shape and
            // make them awkward to grab.
            if (chrome)
              Positioned.fill(
                child: Transform.rotate(
                  angle: _rotation,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: m,
                        top: m,
                        width: _size.width,
                        height: _size.height,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: BoardViewportScale.size(6, chromeScale),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Rotation affordances come first so the resize
                      // handles, added last, win where they overlap.
                      ..._buildRotateBands(chromeScale),
                      ..._buildCornerRotatePads(chromeScale),
                      ..._buildResizeHandles(chromeScale),
                    ],
                  ),
                ),
              ),
            // Deliberately outside the rotation: the readout stays upright
            // so the angle is legible whatever the frame is doing.
            if (chrome && _dragRotation != null) _buildAngleBadge(chromeScale),
          ],
        ),
      ),
    );
  }

  /// Rotate pads straddling each corner, around the resize handle.
  ///
  /// Where a pad and the corner handle overlap the handle wins: these are added
  /// to the stack first, and Flutter hit-tests the last child first.
  List<Widget> _buildCornerRotatePads(double scale) {
    final pad = BoardViewportScale.size(
      BoardFrameWidget.rotateCornerSize,
      scale,
    );
    final color = Theme.of(context).colorScheme.primary;

    const corners = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    final m = BoardViewportScale.size(BoardFrameWidget.chromeMargin, scale);

    return corners.map((corner) {
      final hovered = _hoveredRotateCorner == corner;

      // Straddles the frame corner: the inner half surrounds the resize
      // handle, the outer half reaches into the margin. Both halves take
      // pointer events now that the box extends that far.
      return Positioned(
        left: corner.x < 0 ? m - pad / 2 : null,
        right: corner.x > 0 ? m - pad / 2 : null,
        top: corner.y < 0 ? m - pad / 2 : null,
        bottom: corner.y > 0 ? m - pad / 2 : null,
        width: pad,
        height: pad,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          onEnter: (_) => setState(() => _hoveredRotateCorner = corner),
          onExit: (_) => setState(() => _hoveredRotateCorner = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _startRotate(d.globalPosition),
            onPanUpdate: (d) => _onRotate(d.globalPosition),
            onPanEnd: (_) => _endGesture(),
            onPanCancel: _endGesture,
            // Invisible until pointed at, so an idle selection stays clean.
            child: AnimatedOpacity(
              opacity: hovered ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: CustomPaint(
                painter: _CornerRotateGlyphPainter(
                  corner: corner,
                  color: color,
                  haloColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Grab bands along the four edges. Dragging one rotates the frame around
  /// its centre; the corners stay reserved for resizing, so each band stops a
  /// handle's width short of both ends.
  List<Widget> _buildRotateBands(double scale) {
    final band = BoardViewportScale.size(BoardFrameWidget.rotateBand, scale);
    final inset = BoardViewportScale.size(BoardFrameWidget.handleSize, scale);
    final color = Theme.of(context).colorScheme.primary;

    final m = BoardViewportScale.size(BoardFrameWidget.chromeMargin, scale);

    Widget buildBand(Alignment side) {
      final horizontal =
          side == Alignment.topCenter || side == Alignment.bottomCenter;
      final hovered = _hoveredRotateCorner == side;

      // Sits in the margin just outside its edge rather than over the frame,
      // so rotating never competes with dragging the frame itself.
      final along = m + inset;
      final across = m - band;

      return Positioned(
        left: side == Alignment.centerRight
            ? null
            : (horizontal ? along : across),
        right: side == Alignment.centerLeft
            ? null
            : (horizontal ? along : across),
        top: side == Alignment.bottomCenter
            ? null
            : (horizontal ? across : along),
        bottom: side == Alignment.topCenter
            ? null
            : (horizontal ? across : along),
        width: horizontal ? null : band,
        height: horizontal ? band : null,
        child: MouseRegion(
          // Flutter exposes no rotate cursor; grab is the closest signal that
          // the edge is draggable.
          cursor: SystemMouseCursors.grab,
          onEnter: (_) => setState(() => _hoveredRotateCorner = side),
          onExit: (_) => setState(() => _hoveredRotateCorner = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _startRotate(d.globalPosition),
            onPanUpdate: (d) => _onRotate(d.globalPosition),
            onPanEnd: (_) => _endGesture(),
            onPanCancel: _endGesture,
            // Only tinted while pointed at or actively rotating — a standing
            // wash along every edge reads as part of the design.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              color: color.withValues(
                alpha: hovered || _dragRotation != null ? 0.35 : 0.0,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }

    return [
      buildBand(Alignment.topCenter),
      buildBand(Alignment.bottomCenter),
      buildBand(Alignment.centerLeft),
      buildBand(Alignment.centerRight),
    ];
  }

  /// Live angle readout while rotating, so the drag is landable on a number.
  Widget _buildAngleBadge(double scale) {
    final degrees = (_rotation * 180 / math.pi).roundToDouble();
    final theme = Theme.of(context);

    final m = BoardViewportScale.size(BoardFrameWidget.chromeMargin, scale);
    final lift = BoardViewportScale.size(
      BoardFrameWidget.handleSize * 2.4,
      scale,
    );

    return Positioned(
      top: m - lift,
      left: m,
      right: m,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: BoardViewportScale.size(28, scale),
              vertical: BoardViewportScale.size(14, scale),
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${degrees.toStringAsFixed(0)}°',
              style: TextStyle(
                fontSize: BoardViewportScale.size(52, scale),
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(double scale) {
    const corners = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];
    final size = BoardViewportScale.size(BoardFrameWidget.handleSize, scale);
    final m = BoardViewportScale.size(BoardFrameWidget.chromeMargin, scale);
    final color = Theme.of(context).colorScheme.primary;

    return corners.map((corner) {
      // Centred on the frame's corner, which is [chromeMargin] in from the
      // box edge on every side.
      return Positioned(
        left: corner.x < 0 ? m - size / 2 : null,
        right: corner.x > 0 ? m - size / 2 : null,
        top: corner.y < 0 ? m - size / 2 : null,
        bottom: corner.y > 0 ? m - size / 2 : null,
        child: MouseRegion(
          cursor: corner == Alignment.topLeft || corner == Alignment.bottomRight
              ? SystemMouseCursors.resizeUpLeftDownRight
              : SystemMouseCursors.resizeUpRightDownLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _startGesture(),
            onPanUpdate: (details) => _onResize(corner, details.delta),
            onPanEnd: (_) => _endGesture(),
            onPanCancel: _endGesture,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: color,
                  width: BoardViewportScale.size(5, scale),
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFrameContent(FrameElement frame) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(frame.rotationX)
      ..rotateY(frame.rotationY)
      // Live value so the frame follows an edge drag before it is committed.
      ..rotateZ(_rotation);

    final screen = _buildImage(frame);

    Widget content;
    if (frame.device == null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(frame.cornerRadius),
        child: screen,
      );
    } else {
      // Hand-held mock-ups extend past the device bounds, so they fit to
      // height rather than being letterboxed like a plain shell.
      final isHandFrame =
          frame.device!.identifier.name.contains('hand');
      content = FittedBox(
        fit: isHandFrame ? BoxFit.fitHeight : BoxFit.contain,
        child: DeviceFrame(
          device: frame.device!,
          isFrameVisible: true,
          orientation: frame.orientation,
          screen: screen,
        ),
      );
    }

    if (frame.shadowColor != null && frame.shadowBlurRadius > 0) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(frame.cornerRadius),
          boxShadow: [
            BoxShadow(
              color: frame.shadowColor!,
              blurRadius: frame.shadowBlurRadius,
              offset: frame.shadowOffset,
            ),
          ],
        ),
        child: content,
      );
    }

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // Context menu
  // ---------------------------------------------------------------------------

  void _showContextMenu(BuildContext context, TapUpDetails details) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final cubit = _cubit;
    final frame = widget.frame;

    // Per-locale image overrides are keyed by frame id — a board has no slot
    // ordering to key them by.
    TranslationCubit? tCubit;
    try {
      tCubit = context.read<TranslationCubit>();
    } catch (_) {}
    final previewLocale = tCubit?.state.previewLocale;
    final hasLocaleImage =
        previewLocale != null &&
        tCubit?.state.bundle?.getLocaleImageForKey(previewLocale, frame.id) !=
            null;

    cubit.selectFrame(frame.id);

    context
        .showAppPopupMenu<String>(
          position: RelativeRect.fromRect(
            details.globalPosition & const Size(1, 1),
            Offset.zero & overlay.size,
          ),
          items: [
            AppPopupMenuItem(
              value: 'replace',
              title: context.l10n.replaceImage,
              icon: Symbols.image_rounded,
            ),
            if (previewLocale != null)
              AppPopupMenuItem(
                value: 'replaceLocale',
                title: context.l10n.replaceImageForLocale(
                  previewLocale.toUpperCase(),
                ),
                icon: Symbols.translate_rounded,
              ),
            if (previewLocale != null && hasLocaleImage)
              AppPopupMenuItem(
                value: 'revertLocale',
                title: context.l10n.revertToSourceImage,
                icon: Symbols.undo_rounded,
              ),
            AppPopupMenuItem(
              value: 'duplicate',
              title: context.l10n.duplicate,
              icon: Symbols.content_copy_rounded,
            ),
            AppPopupMenuItem(
              value: 'front',
              title: context.l10n.bringToFront,
              icon: Symbols.flip_to_front_rounded,
            ),
            AppPopupMenuItem(
              value: 'back',
              title: context.l10n.sendToBack,
              icon: Symbols.flip_to_back_rounded,
            ),
            AppPopupMenuItem(
              value: 'delete',
              title: context.l10n.delete,
              icon: Symbols.delete_rounded,
              isDestructive: true,
            ),
          ],
        )
        .then((value) async {
          if (!mounted) return;
          switch (value) {
            case 'replace':
              final files = await ImagePickerHelper.pickImage(context: this.context);
              // The picker is modal and can outlive this page — a cubit closed
              // in the meantime throws on emit.
              if (files.isEmpty || !mounted || cubit.isClosed) return;
              await cubit.setFrameImage(frame.id, files.first);
            case 'replaceLocale':
              if (previewLocale == null || tCubit == null) return;
              final files = await ImagePickerHelper.pickImage(context: this.context);
              if (files.isEmpty) return;
              final stable = await BoardCubit.copyToStableStorage(files.first);
              if (!mounted || tCubit.isClosed) return;
              tCubit.setLocaleImageForKey(
                previewLocale,
                frame.id,
                stable.path,
              );
            case 'revertLocale':
              if (previewLocale == null || tCubit == null) return;
              tCubit.removeLocaleImageForKey(previewLocale, frame.id);
            case 'duplicate':
              cubit.duplicateFrame(frame.id);
            case 'front':
              cubit.bringFrameToFront(frame.id);
            case 'back':
              cubit.sendFrameToBack(frame.id);
            case 'delete':
              cubit.removeFrame(frame.id);
          }
        });
  }

  /// Cache for the locale-override existence check below, so a rebuild during
  /// a drag doesn't hit the filesystem on every frame.
  String? _checkedOverridePath;
  bool _checkedOverrideExists = false;

  bool _overrideExists(String path) {
    if (path != _checkedOverridePath) {
      _checkedOverridePath = path;
      _checkedOverrideExists = File(path).existsSync();
    }
    return _checkedOverrideExists;
  }

  /// The screenshot inside the shell, honouring a per-locale override for this
  /// frame when a non-source locale is being previewed.
  Widget _buildImage(FrameElement frame) {
    String? path = frame.imagePath;

    TranslationCubit? tCubit;
    try {
      tCubit = context.watch<TranslationCubit>();
    } catch (_) {}
    if (tCubit != null) {
      final override = tCubit.localeImagePathForKey(frame.id);
      if (override != null && _overrideExists(override)) {
        path = override;
      }
    }

    if (path == null) return const ImportHintPlaceholder();

    final file = File(path);
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.file(file, fit: BoxFit.cover);
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Symbols.error_rounded)),
    );
  }
}
