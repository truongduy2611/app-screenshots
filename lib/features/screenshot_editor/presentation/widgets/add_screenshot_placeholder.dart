import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Dashed-border placeholder shown after the last screenshot in the
/// multi-screenshot canvas.  Clicking it triggers the [onTap] callback
/// (typically to add a new design).
class AddScreenshotPlaceholder extends StatefulWidget {
  const AddScreenshotPlaceholder({
    super.key,
    required this.design,
    required this.onTap,
  });

  /// The design whose device dimensions determine the placeholder size.
  final ScreenshotDesign design;
  final VoidCallback onTap;

  @override
  State<AddScreenshotPlaceholder> createState() =>
      _AddScreenshotPlaceholderState();
}

class _AddScreenshotPlaceholderState extends State<AddScreenshotPlaceholder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dims = ScreenshotUtils.getDimensions(
      widget.design.displayType ?? '',
      widget.design.orientation,
    );

    final borderColor = isDark
        ? Colors.white.withValues(alpha: _hovered ? 0.55 : 0.25)
        : Colors.black.withValues(alpha: _hovered ? 0.55 : 0.25);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: _hovered ? 0.6 : 0.3)
        : Colors.black.withValues(alpha: _hovered ? 0.5 : 0.25);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spacer matching the label row height above CanvasSlots
            const SizedBox(height: 92),
            // Dashed-border container
            CustomPaint(
              painter: DashBorderPainter(
                color: borderColor,
                strokeWidth: 4.0,
                dashLength: 20.0,
                gapLength: 14.0,
                radius: 120.0,
              ),
              child: SizedBox(
                width: dims.width,
                height: dims.height,
                child: Center(
                  child: Icon(Symbols.add_rounded, size: 120, color: iconColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect border.
class DashBorderPainter extends CustomPainter {
  DashBorderPainter({
    required this.color,
    this.strokeWidth = 3.0,
    this.dashLength = 16.0,
    this.gapLength = 10.0,
    this.radius = 24.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    double distance = 0;
    while (distance < totalLength) {
      final end = (distance + dashLength).clamp(0.0, totalLength);
      final dash = metrics.extractPath(distance, end);
      canvas.drawPath(dash, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(DashBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.radius != radius;
}
