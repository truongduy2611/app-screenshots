import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/screenshot_design.dart';
import '../../cubit/screenshot_editor_cubit.dart';

/// Interactive magnifier overlay for the editor canvas.
///
/// Renders a lens in various shapes (circle, rounded rect, star, hexagon,
/// diamond, heart) that shows a zoomed-in portion of the full canvas content
/// (including device frame, background, overlays, and padding).
class MagnifierOverlayWidget extends StatefulWidget {
  const MagnifierOverlayWidget({
    super.key,
    required this.overlay,
    required this.isSelected,
    required this.canvasSnapshot,
    required this.canvasSize,
  });

  final MagnifierOverlay overlay;
  final bool isSelected;
  final ui.Image? canvasSnapshot;
  final Size canvasSize;

  @override
  State<MagnifierOverlayWidget> createState() => _MagnifierOverlayWidgetState();
}

class _MagnifierOverlayWidgetState extends State<MagnifierOverlayWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;

    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.move,
      child: GestureDetector(
        onTap: () {
          context.read<ScreenshotEditorCubit>().selectOverlay(overlay.id);
        },
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          context.read<ScreenshotEditorCubit>().updateMagnifierOverlay(
            overlay.id,
            overlay.copyWith(position: overlay.position + details.delta),
          );
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: Opacity(
          opacity: overlay.opacity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildMagnifierLens(overlay),
              if (widget.isSelected) ..._buildResizeHandles(overlay),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagnifierLens(MagnifierOverlay overlay) {
    final w = overlay.width;
    final h = overlay.height;
    final shadowPad = overlay.shadowBlurRadius + overlay.borderWidth;
    final clipper = MagnifierShapeClipper(
      overlay.shape,
      cornerRadius: overlay.cornerRadius,
      starPoints: overlay.starPoints,
    );

    return Padding(
      padding: EdgeInsets.all(shadowPad),
      child: Transform.translate(
        offset: Offset(-shadowPad, -shadowPad),
        child: CustomPaint(
          painter: MagnifierBorderPainter(
            clipper: clipper,
            borderColor: overlay.borderColor,
            borderWidth: overlay.borderWidth,
            shadowColor: overlay.shadowColor,
            shadowBlurRadius: overlay.shadowBlurRadius,
          ),
          child: SizedBox(
            width: w,
            height: h,
            child: ClipPath(
              clipper: clipper,
              child: _buildZoomedContent(overlay),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomedContent(MagnifierOverlay overlay) {
    final snapshot = widget.canvasSnapshot;
    if (snapshot == null) {
      return Container(
        color: Colors.grey.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(Icons.search, color: Colors.white54, size: 40),
        ),
      );
    }

    final w = overlay.width;
    final h = overlay.height;
    final zoom = overlay.zoomLevel;

    // Source center in canvas coordinates
    final sourceCenterX = overlay.position.dx + w / 2 + overlay.sourceOffset.dx;
    final sourceCenterY = overlay.position.dy + h / 2 + overlay.sourceOffset.dy;

    // Scale the full canvas snapshot uniformly
    final imgWidth = widget.canvasSize.width * zoom;
    final imgHeight = widget.canvasSize.height * zoom;

    // Position so that sourceCenterX/Y maps to the center of the viewport
    final translateX = w / 2 - sourceCenterX * zoom;
    final translateY = h / 2 - sourceCenterY * zoom;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: translateX,
            top: translateY,
            width: imgWidth,
            height: imgHeight,
            child: RawImage(
              image: snapshot,
              width: imgWidth,
              height: imgHeight,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResizeHandles(MagnifierOverlay overlay) {
    const handleSize = 20.0;
    final w = overlay.width;
    final h = overlay.height;

    Widget handle({
      required double left,
      required double top,
      required MouseCursor cursor,
      required void Function(DragUpdateDetails) onPan,
    }) {
      return Positioned(
        left: left,
        top: top,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            onPanUpdate: onPan,
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    void resize(DragUpdateDetails details) {
      final cubit = context.read<ScreenshotEditorCubit>();
      final delta = details.delta.dx.abs() > details.delta.dy.abs()
          ? details.delta.dx
          : details.delta.dy;
      final ratio = overlay.height / overlay.width;
      final maxW = widget.canvasSize.width;
      final maxH = widget.canvasSize.height;
      final newW = (overlay.width + delta).clamp(40.0, maxW);
      final newH = (newW * ratio).clamp(40.0, maxH);
      cubit.updateMagnifierOverlay(
        overlay.id,
        overlay.copyWith(width: newW, height: newH),
      );
    }

    return [
      handle(
        left: w - handleSize / 2,
        top: h - handleSize / 2,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        onPan: resize,
      ),
      handle(
        left: -handleSize / 2,
        top: -handleSize / 2,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        onPan: (details) {
          final cubit = context.read<ScreenshotEditorCubit>();
          final delta = -(details.delta.dx.abs() > details.delta.dy.abs()
              ? details.delta.dx
              : details.delta.dy);
          final ratio = overlay.height / overlay.width;
          final maxW = widget.canvasSize.width;
          final maxH = widget.canvasSize.height;
          final newW = (overlay.width + delta).clamp(40.0, maxW);
          final newH = (newW * ratio).clamp(40.0, maxH);
          final wDiff = newW - overlay.width;
          final hDiff = newH - overlay.height;
          cubit.updateMagnifierOverlay(
            overlay.id,
            overlay.copyWith(
              width: newW,
              height: newH,
              position: overlay.position - Offset(wDiff, hDiff),
            ),
          );
        },
      ),
    ];
  }
}

// ─── Shape clipper ───────────────────────────────────────────────────────────

/// Custom clipper that clips content to the magnifier shape.
/// Also used by the static preview to produce the same clip path.
class MagnifierShapeClipper extends CustomClipper<Path> {
  final MagnifierShape shape;
  final double cornerRadius;
  final int starPoints;

  MagnifierShapeClipper(
    this.shape, {
    this.cornerRadius = 20.0,
    this.starPoints = 5,
  });

  @override
  Path getClip(Size size) => buildPath(
    size,
    shape,
    cornerRadius: cornerRadius,
    starPoints: starPoints,
  );

  @override
  bool shouldReclip(covariant MagnifierShapeClipper old) =>
      shape != old.shape ||
      cornerRadius != old.cornerRadius ||
      starPoints != old.starPoints;

  /// Builds a path for the given [shape] inscribed in [size].
  static Path buildPath(
    Size size,
    MagnifierShape shape, {
    double cornerRadius = 20.0,
    int starPoints = 5,
  }) {
    final rect = Offset.zero & size;
    switch (shape) {
      case MagnifierShape.circle:
        return Path()..addOval(rect);

      case MagnifierShape.roundedRectangle:
        return Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
        );

      case MagnifierShape.star:
        return _starPath(size, starPoints);

      case MagnifierShape.hexagon:
        return _polygonPath(size, 6);

      case MagnifierShape.diamond:
        return _diamondPath(size);

      case MagnifierShape.heart:
        return _heartPath(size);
    }
  }

  static Path _starPath(Size size, int points) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy);
    final innerR = outerR * 0.45;
    final totalPoints = points * 2;
    const startAngle = -math.pi / 2;

    for (int i = 0; i < totalPoints; i++) {
      final angle = startAngle + (i * math.pi / points);
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _polygonPath(Size size, int sides) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);
    const startAngle = -math.pi / 2;

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + (i * 2 * math.pi / sides);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _diamondPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    return Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width, cy)
      ..lineTo(cx, size.height)
      ..lineTo(0, cy)
      ..close();
  }

  static Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w / 2, h * 0.3);

    // Left bump
    path.cubicTo(w * 0.15, h * 0.0, -w * 0.05, h * 0.35, w / 2, h * 0.95);

    path.moveTo(w / 2, h * 0.3);

    // Right bump
    path.cubicTo(w * 0.85, h * 0.0, w * 1.05, h * 0.35, w / 2, h * 0.95);

    path.close();
    return path;
  }
}

// ─── Border painter ──────────────────────────────────────────────────────────

/// Paints a border (and optional shadow) that follows the clip path exactly.
class MagnifierBorderPainter extends CustomPainter {
  final MagnifierShapeClipper clipper;
  final Color borderColor;
  final double borderWidth;
  final Color? shadowColor;
  final double shadowBlurRadius;

  MagnifierBorderPainter({
    required this.clipper,
    required this.borderColor,
    required this.borderWidth,
    this.shadowColor,
    this.shadowBlurRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);

    // Shadow
    if (shadowColor != null && shadowBlurRadius > 0) {
      final shadowPaint = Paint()
        ..color = shadowColor!
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlurRadius);
      canvas.drawPath(path, shadowPaint);
    }

    // Border
    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MagnifierBorderPainter old) =>
      borderColor != old.borderColor ||
      borderWidth != old.borderWidth ||
      shadowColor != old.shadowColor ||
      shadowBlurRadius != old.shadowBlurRadius;
}
