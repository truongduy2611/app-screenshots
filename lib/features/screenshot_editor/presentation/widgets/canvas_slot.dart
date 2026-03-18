import 'dart:io';

import 'package:app_screenshots/core/extensions/context_extensions.dart';

import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/static_canvas_preview.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/editor_canvas.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:screenshot/screenshot.dart';

/// A single frame slot in the multi-screenshot canvas row.
///
/// Shows the frame label, the canvas (active = [EditorCanvas], inactive =
/// [StaticCanvasPreview]), a dimensions badge on hover/active, and a
/// right-click context menu for duplicate/delete.
class CanvasSlot extends StatefulWidget {
  const CanvasSlot({
    super.key,
    required this.index,
    required this.design,
    required this.imageFile,
    required this.isActive,
    required this.onTap,
    this.screenshotController,
    this.onDelete,
    this.onDuplicate,
    this.onReplaceImage,
    this.onMoveLeft,
    this.onMoveRight,
  });

  final int index;
  final ScreenshotDesign design;
  final File? imageFile;
  final bool isActive;
  final VoidCallback onTap;
  final ScreenshotController? screenshotController;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onReplaceImage;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;

  @override
  State<CanvasSlot> createState() => _CanvasSlotState();
}

class _CanvasSlotState extends State<CanvasSlot> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectionColor = isDark ? Colors.white : Colors.black;
    final dims = ScreenshotUtils.getDimensions(
      widget.design.displayType ?? '',
      widget.design.orientation,
    );

    // Match the corner radius used by EditorCanvas / StaticCanvasPreview.
    final cornerRadius = dims.shortestSide * 0.08;

    final borderColor = widget.isActive
        ? selectionColor
        : _hovered
        ? selectionColor.withValues(alpha: 0.4)
        : Colors.transparent;
    final borderWidth = 10.0;

    return MouseRegion(
      cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) => setState(() => _dragging = true),
        onPanEnd: (_) => setState(() => _dragging = false),
        onPanCancel: () => setState(() => _dragging = false),
        onSecondaryTapUp: (details) => _showContextMenu(context, details),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Frame label + dimensions ──
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 42),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.frame_inspect_rounded,
                    size: 60,
                    color: widget.isActive
                        ? selectionColor
                        : _hovered
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.screenshotLabel(widget.index + 1),
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isActive
                          ? selectionColor
                          : _hovered
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (widget.isActive || _hovered) ...[
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${dims.width.toInt()} × ${dims.height.toInt()}',
                        style: TextStyle(
                          fontSize: 40,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Frame canvas with shadow ──
            // Outer: border + shadow (no clipping so the outside-
            // stroke border is fully visible).
            Container(
              width: dims.width + (widget.isActive ? borderWidth * 2 : 0),
              height: dims.height + (widget.isActive ? borderWidth * 2 : 0),
              padding: widget.isActive ? EdgeInsets.all(borderWidth) : null,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cornerRadius + 4),
                border: Border.all(
                  color: widget.isActive ? borderColor : Colors.transparent,
                  width: 4,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: widget.isActive ? 24 : 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.isActive && widget.screenshotController != null
                  ? EditorCanvas(
                      screenshotController: widget.screenshotController!,
                    )
                  : StaticCanvasPreview(
                      design: widget.design,
                      borderRadius: cornerRadius,
                      imageFile: widget.imageFile,
                      designIndex: widget.index,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapUpDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    context
        .showAppPopupMenu<String>(
          position: RelativeRect.fromRect(
            details.globalPosition & const Size(1, 1),
            Offset.zero & overlay.size,
          ),
          items: [
            if (widget.onReplaceImage != null)
              AppPopupMenuItem(
                value: 'replace',
                title: context.l10n.replaceImage,
                icon: Symbols.image_rounded,
              ),
            if (widget.onDuplicate != null)
              AppPopupMenuItem(
                value: 'duplicate',
                title: context.l10n.duplicate,
                icon: Symbols.content_copy_rounded,
              ),
            if (widget.onMoveLeft != null)
              AppPopupMenuItem(
                value: 'moveLeft',
                title: context.l10n.moveLeft,
                icon: Symbols.arrow_back_rounded,
              ),
            if (widget.onMoveRight != null)
              AppPopupMenuItem(
                value: 'moveRight',
                title: context.l10n.moveRight,
                icon: Symbols.arrow_forward_rounded,
              ),
            if (widget.onDelete != null)
              AppPopupMenuItem(
                value: 'delete',
                title: context.l10n.delete,
                icon: Symbols.delete_rounded,
                isDestructive: true,
              ),
          ],
        )
        .then((value) {
          if (value == 'replace') widget.onReplaceImage?.call();
          if (value == 'duplicate') widget.onDuplicate?.call();
          if (value == 'moveLeft') widget.onMoveLeft?.call();
          if (value == 'moveRight') widget.onMoveRight?.call();
          if (value == 'delete') widget.onDelete?.call();
        });
  }
}
