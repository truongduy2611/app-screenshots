import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:flutter/material.dart';

class GridOverlay extends StatelessWidget {
  final GridSettings settings;
  final Size canvasSize;

  const GridOverlay({
    super.key,
    required this.settings,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    if (!settings.showGrid && !settings.showCenterLines) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: canvasSize,
        painter: _GridPainter(settings: settings),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridSettings settings;

  _GridPainter({required this.settings});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = settings.gridColor
      ..strokeWidth = 1.0;

    if (settings.showGrid) {
      for (double x = 0; x <= size.width; x += settings.gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y <= size.height; y += settings.gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }

    if (settings.showCenterLines) {
      final centerPaint = Paint()
        ..color = settings.gridColor.withValues(alpha: 0.8)
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        centerPaint,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        centerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.settings != settings;
  }
}
