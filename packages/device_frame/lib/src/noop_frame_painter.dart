import 'package:flutter/material.dart';

/// A no-op [CustomPainter] used for devices that render their frame
/// via a PNG asset image rather than vector paths.
class NoopFramePainter extends CustomPainter {
  const NoopFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // No-op: frame is rendered via Image.asset
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
