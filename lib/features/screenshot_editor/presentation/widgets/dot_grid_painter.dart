import 'package:flutter/material.dart';

/// Paints a dot-grid background pattern.
///
/// Used in both the single-screenshot and multi-screenshot editors.
class DotGridPainter extends CustomPainter {
  DotGridPainter({required this.dotColor, required this.backgroundColor});

  final Color dotColor;
  final Color backgroundColor;
  final double spacing = 24.0;
  final double dotRadius = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    if (dotColor == Colors.transparent) return;

    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.dotColor != dotColor ||
      old.backgroundColor != backgroundColor ||
      old.spacing != spacing ||
      old.dotRadius != dotRadius;
}
