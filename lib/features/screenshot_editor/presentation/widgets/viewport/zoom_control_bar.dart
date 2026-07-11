import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_icon_button.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'canvas_viewport_controller.dart';
import 'figma_canvas_viewport.dart';

/// A Figma-style zoom widget: -/percentage/+ pill anchored to the bottom
/// left of a canvas, showing the live zoom level of [controller] with
/// quick actions to reset it. Desktop only — mobile has no equivalent
/// concept of an explicit zoom level since it relies on pinch + auto-fit.
class ZoomControlBar extends StatefulWidget {
  const ZoomControlBar({
    super.key,
    required this.constraints,
    required this.controller,
    required this.onZoomToFit,
    this.onZoomToSelection,
    this.initialLeft = 16,
    this.initialBottom = 16,
  });

  final BoxConstraints constraints;
  final CanvasViewportController controller;

  /// Frames the page's own content bounds — computed per page (single
  /// editor: the canvas; multi canvas: the full design row), since this
  /// shared widget has no notion of what "the content" is.
  final VoidCallback onZoomToFit;

  /// When non-null, adds a "Zoom to Selection" menu action (multi-canvas
  /// only — the single editor has nothing to select between).
  final VoidCallback? onZoomToSelection;

  final double initialLeft;
  final double initialBottom;

  @override
  State<ZoomControlBar> createState() => _ZoomControlBarState();
}

class _ZoomControlBarState extends State<ZoomControlBar> {
  late double _left = widget.initialLeft;
  late double _bottom = widget.initialBottom;
  bool _isDragging = false;

  static const double _barWidth = 200;
  static const double _barHeight = 40;

  @override
  Widget build(BuildContext context) {
    if (!FigmaCanvasViewport.isDesktopPlatform) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxLeft = widget.constraints.maxWidth - _barWidth;
    final maxBottom = widget.constraints.maxHeight - _barHeight;
    final effectiveLeft = _left.clamp(0.0, maxLeft > 0 ? maxLeft : 0.0);
    final effectiveBottom = _bottom.clamp(0.0, maxBottom > 0 ? maxBottom : 0.0);

    return Positioned(
      left: effectiveLeft,
      bottom: effectiveBottom,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final percent = (widget.controller.scale * 100).round();
          return Container(
            height: _barHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _left = (_left + details.delta.dx).clamp(
                        0.0,
                        widget.constraints.maxWidth - _barWidth,
                      );
                      _bottom = (_bottom - details.delta.dy).clamp(
                        0.0,
                        widget.constraints.maxHeight - _barHeight,
                      );
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: MouseRegion(
                    cursor: _isDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Icon(
                        Symbols.drag_indicator_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                AppIconButton(
                  icon: Symbols.remove_rounded,
                  size: 32,
                  showBackground: false,
                  tooltip: context.l10n.zoomOut,
                  onPressed: () => widget.controller.zoomBy(0.8, animate: true),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showZoomMenu(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$percent%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                AppIconButton(
                  icon: Symbols.add_rounded,
                  size: 32,
                  showBackground: false,
                  tooltip: context.l10n.zoomIn,
                  onPressed: () => widget.controller.zoomBy(1.25, animate: true),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showZoomMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, -8), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    context
        .showAppPopupMenu<String>(
          position: position,
          items: [
            AppPopupMenuItem(
              value: 'fit',
              title: context.l10n.zoomToFit,
              icon: Symbols.fit_screen_rounded,
              trailing: const _ShortcutLabel('⌘0'),
            ),
            AppPopupMenuItem(
              value: '100',
              title: context.l10n.zoomTo100Percent,
              icon: Symbols.filter_center_focus_rounded,
              trailing: const _ShortcutLabel('⌘1'),
            ),
            if (widget.onZoomToSelection != null)
              AppPopupMenuItem(
                value: 'selection',
                title: context.l10n.zoomToSelection,
                icon: Symbols.center_focus_strong_rounded,
              ),
          ],
        )
        .then((value) {
          switch (value) {
            case 'fit':
              widget.onZoomToFit();
            case '100':
              widget.controller.setScale(1.0);
            case 'selection':
              widget.onZoomToSelection?.call();
          }
        });
  }
}

class _ShortcutLabel extends StatelessWidget {
  const _ShortcutLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.disabledColor,
      ),
    );
  }
}
