import 'package:flutter/material.dart';

/// Paints a checkerboard pattern to indicate transparency.
class CheckerboardPainter extends CustomPainter {
  static const _cellSize = 20.0;
  static const _lightColor = Color(0xFFFFFFFF);
  static const _darkColor = Color(0xFFCCCCCC);

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = _lightColor;
    final darkPaint = Paint()..color = _darkColor;

    canvas.drawRect(Offset.zero & size, lightPaint);

    final cols = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if ((row + col).isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * _cellSize,
              row * _cellSize,
              _cellSize,
              _cellSize,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints bright cyan snap guide lines on top of all canvas content.
class SnapGuidePainter extends CustomPainter {
  final double? activeSnapX;
  final double? activeSnapY;

  SnapGuidePainter({this.activeSnapX, this.activeSnapY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.0;

    if (activeSnapX != null) {
      canvas.drawLine(
        Offset(activeSnapX!, 0),
        Offset(activeSnapX!, size.height),
        paint,
      );
    }
    if (activeSnapY != null) {
      canvas.drawLine(
        Offset(0, activeSnapY!),
        Offset(size.width, activeSnapY!),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SnapGuidePainter oldDelegate) {
    return oldDelegate.activeSnapX != activeSnapX ||
        oldDelegate.activeSnapY != activeSnapY;
  }
}

/// Selection indicator for text and icon overlays.
/// Shows a blue border when [isSelected] is true.
class OverlaySelectionBorder extends StatelessWidget {
  const OverlaySelectionBorder({
    super.key,
    required this.isSelected,
    required this.child,
  });

  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isSelected) return child;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
