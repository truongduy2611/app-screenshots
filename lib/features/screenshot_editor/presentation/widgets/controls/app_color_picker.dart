import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:flutter/material.dart';

/// A preset color palette for quick selection.
const _presetColors = <Color>[
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF3B30),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFF34C759),
  Color(0xFF00C7BE),
  Color(0xFF30B0C7),
  Color(0xFF007AFF),
  Color(0xFF5856D6),
  Color(0xFFAF52DE),
  Color(0xFFFF2D55),
  // Pastels
  Color(0xFFFFC5C5),
  Color(0xFFFFE0B2),
  Color(0xFFFFF9C4),
  Color(0xFFC8E6C9),
  Color(0xFFB2EBF2),
  Color(0xFFBBDEFB),
  Color(0xFFD1C4E9),
  Color(0xFFF8BBD0),
  // Greys
  Color(0xFF8E8E93),
  Color(0xFFAEAEB2),
  Color(0xFFC7C7CC),
  Color(0xFFE5E5EA),
];

/// A compact, premium color picker designed for sidebar panels.
///
/// Shows a saturation/brightness rectangle, a hue slider,
/// a preset palette, and a hex input.
class AppColorPicker extends StatefulWidget {
  const AppColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.onEditStart,
    this.onEditEnd,
    this.enableAlpha = false,
    this.compact = false,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;

  /// Called when a continuous drag begins (e.g. color picker pan start).
  final VoidCallback? onEditStart;

  /// Called when the drag ends.
  final VoidCallback? onEditEnd;
  final bool enableAlpha;
  final bool compact;

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  late HSVColor _hsv;
  late double _alpha;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
    _alpha = widget.color.a;
    _hexController = TextEditingController(text: _hexString);
  }

  @override
  void didUpdateWidget(covariant AppColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hsv = HSVColor.fromColor(widget.color);
      _alpha = widget.color.a;
      _hexController.text = _hexString;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String get _hexString {
    final color = _hsv.toColor().withValues(alpha: _alpha);
    return color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase()
        .substring(2);
  }

  void _updateHSV(HSVColor hsv) {
    setState(() => _hsv = hsv);
    final color = hsv.toColor().withValues(alpha: _alpha);
    _hexController.text = color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase()
        .substring(2);
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickerHeight = widget.compact ? 120.0 : 150.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pickerWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (widget.compact ? 220.0 : 260.0);

        return SizedBox(
          width: pickerWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saturation/Brightness rectangle
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: pickerWidth,
                  height: pickerHeight,
                  child: _SatBrightRect(
                    hue: _hsv.hue,
                    saturation: _hsv.saturation,
                    value: _hsv.value,
                    onChanged: (sat, val) =>
                        _updateHSV(_hsv.withSaturation(sat).withValue(val)),
                    onEditStart: widget.onEditStart,
                    onEditEnd: widget.onEditEnd,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Hue slider
              _HueBar(
                hue: _hsv.hue,
                width: pickerWidth,
                onChanged: (hue) => _updateHSV(_hsv.withHue(hue)),
                onEditStart: widget.onEditStart,
                onEditEnd: widget.onEditEnd,
              ),

              if (widget.enableAlpha) ...[
                const SizedBox(height: 8),
                _AlphaBar(
                  color: _hsv.toColor(),
                  alpha: _alpha,
                  width: pickerWidth,
                  onChanged: (alpha) {
                    setState(() => _alpha = alpha);
                    final color = _hsv.toColor().withValues(alpha: alpha);
                    _hexController.text = color
                        .toARGB32()
                        .toRadixString(16)
                        .padLeft(8, '0')
                        .toUpperCase()
                        .substring(2);
                    widget.onColorChanged(color);
                  },
                  onEditStart: widget.onEditStart,
                  onEditEnd: widget.onEditEnd,
                ),
              ],

              const SizedBox(height: 10),

              // Hex input + preview swatch
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview swatch
                    Container(
                      width: 36,
                      decoration: BoxDecoration(
                        color: _hsv.toColor().withValues(alpha: _alpha),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        decoration: InputDecoration(
                          prefixText: '# ',
                          prefixStyle: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        onSubmitted: (val) {
                          final hex = val.replaceAll('#', '');
                          if (hex.length == 6) {
                            final newColor = Color(
                              int.parse('FF$hex', radix: 16),
                            );
                            _updateHSV(HSVColor.fromColor(newColor));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Preset palette
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _presetColors.map((c) {
                  final isSelected = _hsv.toColor().toARGB32() == c.toARGB32();
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _updateHSV(HSVColor.fromColor(c)),
                      child: Container(
                        width: widget.compact ? 22 : 24,
                        height: widget.compact ? 22 : 24,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (c == const Color(0xFFFFFFFF)
                                      ? theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.4)
                                      : Colors.transparent),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Sat/Brightness rectangle
// ─────────────────────────────────────────────

class _SatBrightRect extends StatelessWidget {
  const _SatBrightRect({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
    this.onEditStart,
    this.onEditEnd,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;
  final VoidCallback? onEditStart;
  final VoidCallback? onEditEnd;

  void _handleInteraction(Offset localPosition, Size size) {
    final sat = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final val = 1.0 - (localPosition.dy / size.height).clamp(0.0, 1.0);
    onChanged(sat, val);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: (d) {
            onEditStart?.call();
            _handleInteraction(d.localPosition, size);
          },
          onPanUpdate: (d) => _handleInteraction(d.localPosition, size),
          onPanEnd: (_) => onEditEnd?.call(),
          onPanCancel: () => onEditEnd?.call(),
          child: CustomPaint(
            size: size,
            painter: _SatBrightPainter(hue: hue),
            child: Stack(
              children: [
                Positioned(
                  left: saturation * size.width - 8,
                  top: (1 - value) * size.height - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SatBrightPainter extends CustomPainter {
  _SatBrightPainter({required this.hue});
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // White to hue (saturation)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );

    // Transparent to black (brightness)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SatBrightPainter old) => old.hue != hue;
}

// ─────────────────────────────────────────────
// Hue bar
// ─────────────────────────────────────────────

class _HueBar extends StatelessWidget {
  const _HueBar({
    required this.hue,
    required this.width,
    required this.onChanged,
    this.onEditStart,
    this.onEditEnd,
  });

  final double hue;
  final double width;
  final ValueChanged<double> onChanged;
  final VoidCallback? onEditStart;
  final VoidCallback? onEditEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        onEditStart?.call();
        onChanged((d.localPosition.dx / width).clamp(0.0, 1.0) * 360);
      },
      onPanUpdate: (d) =>
          onChanged((d.localPosition.dx / width).clamp(0.0, 1.0) * 360),
      onPanEnd: (_) => onEditEnd?.call(),
      onPanCancel: () => onEditEnd?.call(),
      child: SizedBox(
        width: width,
        height: 18,
        child: CustomPaint(
          painter: _HueBarPainter(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: (hue / 360) * width - 6,
                top: 1,
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                      ),
                    ],
                    color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
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

class _HueBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = List.generate(
      7,
      (i) => HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor(),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Alpha bar
// ─────────────────────────────────────────────

class _AlphaBar extends StatelessWidget {
  const _AlphaBar({
    required this.color,
    required this.alpha,
    required this.width,
    required this.onChanged,
    this.onEditStart,
    this.onEditEnd,
  });

  final Color color;
  final double alpha;
  final double width;
  final ValueChanged<double> onChanged;
  final VoidCallback? onEditStart;
  final VoidCallback? onEditEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        onEditStart?.call();
        onChanged((d.localPosition.dx / width).clamp(0.0, 1.0));
      },
      onPanUpdate: (d) =>
          onChanged((d.localPosition.dx / width).clamp(0.0, 1.0)),
      onPanEnd: (_) => onEditEnd?.call(),
      onPanCancel: () => onEditEnd?.call(),
      child: SizedBox(
        width: width,
        height: 18,
        child: CustomPaint(
          painter: _AlphaBarPainter(color: color),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: alpha * width - 6,
                top: 1,
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                      ),
                    ],
                    color: color.withValues(alpha: alpha),
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

class _AlphaBarPainter extends CustomPainter {
  _AlphaBarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    // Checkerboard background
    const checkerSize = 4.0;
    for (var x = 0.0; x < size.width; x += checkerSize) {
      for (var y = 0.0; y < size.height; y += checkerSize) {
        final isEven =
            ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          Paint()..color = isEven ? Colors.grey.shade300 : Colors.white,
        );
      }
    }
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0), color],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AlphaBarPainter old) => old.color != color;
}

/// Shows the [AppColorPicker] in a dialog.
Future<void> showColorPickerDialog({
  required BuildContext context,
  required Color color,
  required ValueChanged<Color> onColorChanged,
  bool enableAlpha = true,
  Rect? sourceRect,
  VoidCallback? onEditStart,
  VoidCallback? onEditEnd,
}) {
  final content = AlertDialog(
    contentPadding: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: SizedBox(
      width: 280,
      child: AppColorPicker(
        color: color,
        onColorChanged: onColorChanged,
        enableAlpha: enableAlpha,
        onEditStart: onEditStart,
        onEditEnd: onEditEnd,
      ),
    ),
  );

  if (sourceRect != null) {
    return showGenieDialog(
      context: context,
      sourceRect: sourceRect,
      builder: (_) => content,
    );
  }
  return showDialog(context: context, builder: (_) => content);
}
