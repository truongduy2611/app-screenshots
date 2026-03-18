import 'dart:math' as math;
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:flutter/material.dart';

class DoodleBackground extends StatelessWidget {
  final DoodleSettings settings;
  final Size canvasSize;

  const DoodleBackground({
    super.key,
    required this.settings,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    if (!settings.enabled) return const SizedBox.shrink();

    final isEmoji = settings.iconSource == DoodleIconSource.emoji;
    if (isEmoji && settings.emojiCharacters.isEmpty) {
      return const SizedBox.shrink();
    }
    if (!isEmoji && settings.iconCodePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final child = CustomPaint(
      size: canvasSize,
      painter: _DoodlePainter(settings: settings, canvasSize: canvasSize),
    );

    if (settings.iconGradient != null && !isEmoji) {
      return ShaderMask(
        shaderCallback: (bounds) {
          return settings.iconGradient!.createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: child,
      );
    }

    return child;
  }
}

class _DoodlePainter extends CustomPainter {
  final DoodleSettings settings;
  final Size canvasSize;

  _DoodlePainter({required this.settings, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    final isEmoji = settings.iconSource == DoodleIconSource.emoji;
    final itemCount = isEmoji
        ? settings.emojiCharacters.length
        : settings.iconCodePoints.length;
    if (itemCount == 0) return;

    canvas.save();

    if (settings.rotation != 0) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(settings.rotation * math.pi / 180);
      canvas.translate(-center.dx, -center.dy);
    }

    final spacing = settings.spacing;
    final iconSize = settings.iconSize;

    final extraMargin = settings.rotation != 0 ? spacing * 2 : 0.0;
    final startX = -extraMargin;
    final startY = -extraMargin;
    final endX = size.width + extraMargin;
    final endY = size.height + extraMargin;

    String? fontFamily;
    String? fontPackage;
    if (!isEmoji) {
      fontFamily = settings.iconSource == DoodleIconSource.sfSymbols
          ? 'sficons'
          : 'MaterialSymbolsRounded';
      fontPackage = settings.iconSource == DoodleIconSource.sfSymbols
          ? 'flutter_sficon'
          : 'material_symbols_icons';
    }

    int iconIndex = 0;
    final rng = math.Random(42);

    double y = startY;
    int rowIndex = 0;
    while (y < endY) {
      final xOffset = (rowIndex % 2 == 1) ? spacing / 2 : 0.0;

      double x = startX + xOffset;
      while (x < endX) {
        final String text;
        if (isEmoji) {
          text = settings.emojiCharacters[iconIndex % itemCount];
        } else {
          text = String.fromCharCode(
            settings.iconCodePoints[iconIndex % itemCount],
          );
        }

        final individualRotation = settings.randomizeRotation
            ? (rng.nextDouble() - 0.5) * 0.6
            : 0.0;

        final textStyle = TextStyle(
          fontFamily: fontFamily,
          package: fontPackage,
          fontSize: iconSize,
          color: isEmoji
              ? Colors.white.withValues(alpha: settings.iconOpacity)
              : settings.iconGradient != null
              ? Colors.white.withValues(alpha: settings.iconOpacity)
              : settings.iconColor.withValues(alpha: settings.iconOpacity),
        );

        final textPainter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        canvas.save();
        final iconCenter = Offset(
          x + textPainter.width / 2,
          y + textPainter.height / 2,
        );
        canvas.translate(iconCenter.dx, iconCenter.dy);
        canvas.rotate(individualRotation);
        canvas.translate(-iconCenter.dx, -iconCenter.dy);

        textPainter.paint(canvas, Offset(x, y));
        canvas.restore();

        x += spacing;
        iconIndex++;
      }
      y += spacing;
      rowIndex++;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.canvasSize != canvasSize;
  }
}
