import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_list_tile.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

class FolderListTile extends StatelessWidget {
  final DesignFolder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final Function(Object) onDrop;
  final bool isExpanded;

  const FolderListTile({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onDrop,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<DesignFolder>(
      data: folder,
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Symbols.folder_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildTile(context, isDragOver: false),
      ),
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (details) {
          final data = details.data;
          if (data is SavedDesign) {
            HapticFeedback.selectionClick();
            return true;
          }
          if (data is DesignFolder && data.id != folder.id) {
            HapticFeedback.selectionClick();
            return true;
          }
          return false;
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.mediumImpact();
          onDrop(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          return _buildTile(context, isDragOver: candidateData.isNotEmpty);
        },
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required bool isDragOver}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return AppListTile(
      isHighlighted: isDragOver,
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, position: details.globalPosition),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Symbols.folder_rounded,
          size: 22,
          color: isDragOver ? theme.colorScheme.onPrimaryContainer : primary,
        ),
      ),
      title: Text(
        folder.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: AnimatedRotation(
        turns: isExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          Icons.expand_more,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
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
          if (value == 'rename') {
            onRename();
          } else if (value == 'delete') {
            onDelete();
          }
        });
  }
}
