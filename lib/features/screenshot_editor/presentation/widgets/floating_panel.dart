import 'package:flutter/material.dart';

/// A draggable, resizable floating panel that overlays on a [Stack].
///
/// Must be placed inside a [Stack] wrapped in a [LayoutBuilder] so the
/// panel can read the available [constraints].
class FloatingPanel extends StatefulWidget {
  const FloatingPanel({
    super.key,
    required this.constraints,
    required this.child,
    this.initialTop = 12,
    this.initialRight = 12,
    this.initialWidth = 320,
    this.minWidth = 260,
    this.maxWidth = 480,
    this.minHeight = 200,
  });

  final BoxConstraints constraints;
  final Widget child;
  final double initialTop;
  final double initialRight;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final double minHeight;

  @override
  State<FloatingPanel> createState() => _FloatingPanelState();
}

class _FloatingPanelState extends State<FloatingPanel> {
  late double _top = widget.initialTop;
  late double _right = widget.initialRight;
  late double _width = widget.initialWidth;
  double? _height;

  double get _effectiveHeight =>
      _height ?? (widget.constraints.maxHeight - _top - 12);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main panel
        Positioned(
          top: _top,
          right: _right,
          child: Container(
            width: _width,
            constraints: BoxConstraints(maxHeight: _effectiveHeight),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(-4, 0),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  _DragHandle(
                    onPanUpdate: (details) {
                      setState(() {
                        _top = (_top + details.delta.dy).clamp(
                          0.0,
                          widget.constraints.maxHeight - 100,
                        );
                        _right = (_right - details.delta.dx).clamp(
                          0.0,
                          widget.constraints.maxWidth - _width,
                        );
                      });
                    },
                  ),
                  // Content
                  Flexible(child: widget.child),
                ],
              ),
            ),
          ),
        ),
        // Left edge resize
        Positioned(
          top: _top + 30,
          right: _right + _width - 4,
          bottom: widget.constraints.maxHeight - _top - _effectiveHeight,
          child: _ResizeHandle(
            cursor: SystemMouseCursors.resizeColumn,
            width: 10,
            onDrag: (details) {
              setState(() {
                _width = (_width - details.delta.dx).clamp(
                  widget.minWidth,
                  widget.maxWidth,
                );
              });
            },
          ),
        ),
        // Bottom edge resize
        Positioned(
          left: widget.constraints.maxWidth - _right - _width,
          right: _right,
          top: _top + _effectiveHeight - 4,
          child: _ResizeHandle(
            cursor: SystemMouseCursors.resizeRow,
            height: 10,
            onDrag: (details) {
              setState(() {
                final maxH = widget.constraints.maxHeight - _top - 12;
                _height = ((_height ?? maxH) + details.delta.dy).clamp(
                  widget.minHeight,
                  maxH,
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.onPanUpdate});

  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.cursor,
    required this.onDrag,
    this.width,
    this.height,
  });

  final MouseCursor cursor;
  final GestureDragUpdateCallback onDrag;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDrag,
        child: Container(
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}
