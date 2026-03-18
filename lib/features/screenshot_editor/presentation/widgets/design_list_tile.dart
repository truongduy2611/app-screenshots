import 'dart:io';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_list_tile.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/move_to_folder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class DesignListTile extends StatefulWidget {
  final SavedDesign design;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;
  final VoidCallback? onShare;

  const DesignListTile({
    super.key,
    required this.design,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    this.onShare,
  });

  @override
  State<DesignListTile> createState() => _DesignListTileState();
}

class _DesignListTileState extends State<DesignListTile> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant DesignListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.design.thumbnailPath != widget.design.thumbnailPath ||
        oldWidget.design.lastModified != widget.design.lastModified) {
      _aspectRatio = null;
      _resolveAspectRatio();
    }
  }

  void _resolveAspectRatio() {
    final file = File(widget.design.thumbnailPath);
    if (!file.existsSync()) return;

    final image = FileImage(file);
    image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(() {
                _aspectRatio =
                    info.image.width.toDouble() / info.image.height.toDouble();
              });
            }
          }),
        );
  }

  SavedDesign get design => widget.design;
  VoidCallback get onTap => widget.onTap;
  VoidCallback get onDelete => widget.onDelete;
  ValueChanged<String> get onRename => widget.onRename;
  VoidCallback? get onShare => widget.onShare;

  @override
  Widget build(BuildContext context) {
    return Draggable<SavedDesign>(
      data: design,
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 140,
          child: Image.file(
            File(design.thumbnailPath),
            key: ValueKey(
              '${design.id}_${design.lastModified.millisecondsSinceEpoch}',
            ),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox(width: 140, height: 100),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _buildTile(context)),
      child: _buildTile(context),
    );
  }

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final displayType = design.design.displayType;

    // Fixed height, width adapts to image ratio.
    const thumbHeight = 56.0;
    final ratio = _aspectRatio ?? (9 / 16);
    final thumbWidth = thumbHeight * ratio;

    return AppListTile(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, position: details.globalPosition),
      leading: Container(
        width: thumbWidth,
        height: thumbHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(design.thumbnailPath),
          key: ValueKey(
            '${design.id}_${design.lastModified.millisecondsSinceEpoch}',
          ),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          width: thumbWidth,
          height: thumbHeight,
          errorBuilder: (_, _, _) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: isDark ? 0.1 : 0.05),
                  primary.withValues(alpha: isDark ? 0.05 : 0.02),
                ],
              ),
            ),
            child: Icon(
              Symbols.broken_image_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        design.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        DateFormat.yMMMd().format(design.lastModified),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
      trailing: displayType != null && displayType.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDisplayType(displayType),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            )
          : null,
    );
  }

  String _formatDisplayType(String displayType) {
    return displayType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          if (w.toLowerCase() == 'iphone') return 'iPhone';
          if (w.toLowerCase() == 'ipad') return 'iPad';
          return '${w[0].toUpperCase()}${w.substring(1)}';
        })
        .join(' ');
  }

  void _showContextMenu(BuildContext context, {Offset? position}) {
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect menuPosition;
    if (position != null) {
      menuPosition = RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      );
    } else {
      final RenderBox button = context.findRenderObject() as RenderBox;
      menuPosition = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );
    }
    context
        .showAppPopupMenu<String>(
          position: menuPosition,
          items: [
            if (onShare != null)
              AppPopupMenuItem(
                value: 'share',
                title: context.l10n.share,
                icon: Symbols.share_rounded,
              ),
            AppPopupMenuItem(
              value: 'move',
              title: context.l10n.moveToFolder,
              icon: Symbols.drive_file_move_rounded,
            ),
            AppPopupMenuItem(
              value: 'rename',
              title: context.l10n.rename,
              icon: Symbols.edit_rounded,
            ),
            AppPopupMenuItem(
              value: 'delete',
              title: context.l10n.delete,
              icon: Symbols.delete_rounded,
              isDestructive: true,
            ),
          ],
        )
        .then((value) {
          if (!context.mounted) return;
          if (value == 'share') onShare?.call();
          if (value == 'move') _showMoveToFolderDialog(context);
          if (value == 'rename') _showRenameDialog(context);
          if (value == 'delete') onDelete();
        });
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: design.name);
    final sourceRect = rectFromContext(context);
    final dialogContent = AlertDialog(
      title: Text(context.l10n.rename),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: context.l10n.designName),
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(context.l10n.rename),
        ),
      ],
    );

    final Future<String?> result;
    if (sourceRect != null) {
      result = showGenieDialog<String>(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => dialogContent,
      );
    } else {
      result = showDialog<String>(
        context: context,
        builder: (_) => dialogContent,
      );
    }
    result.then((newName) {
      if (newName != null && newName.isNotEmpty) {
        onRename(newName);
      }
    });
  }

  void _showMoveToFolderDialog(BuildContext context) {
    final cubit = context.read<ScreenshotLibraryCubit>();
    final state = cubit.state;
    if (state is! ScreenshotLibraryLoaded) return;

    MoveToFolderDialog.show(
      context,
      folders: state.allFolders,
      currentFolderId: design.folderId,
    ).then((result) {
      if (result == null || !context.mounted) return; // cancelled / dismissed
      final newFolderId = result == '__root__' ? null : result;
      if (newFolderId == design.folderId) return; // no change
      cubit.moveDesignToFolder(design.id, newFolderId);
    });
  }
}
