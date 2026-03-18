import 'dart:io';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/design_share_helper.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/multi_screenshot_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/screenshot_editor_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/device_selection_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/move_to_folder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class DraggableDesignCard extends StatelessWidget {
  final SavedDesign design;
  const DraggableDesignCard({super.key, required this.design});

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
            fit: BoxFit.fitWidth,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox(width: 140, height: 100),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: DesignCard(design: design),
      ),
      child: DesignCard(design: design),
    );
  }
}

class DesignCard extends StatefulWidget {
  final SavedDesign design;
  const DesignCard({super.key, required this.design});

  @override
  State<DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<DesignCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final tertiary = theme.colorScheme.tertiary;
    final displayType = widget.design.design.displayType;

    final libraryState = context.watch<ScreenshotLibraryCubit>().state;
    final isSelectionMode =
        libraryState is ScreenshotLibraryLoaded && libraryState.isSelectionMode;
    final isSelected =
        libraryState is ScreenshotLibraryLoaded &&
        libraryState.selectedDesignIds.contains(widget.design.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            _showContextMenu(context, position: details.globalPosition),
        child: AnimatedScale(
          scale: _isHovering ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        primary.withValues(alpha: isDark ? 0.25 : 0.15),
                        tertiary.withValues(alpha: isDark ? 0.15 : 0.08),
                      ]
                    : [
                        primary.withValues(alpha: isDark ? 0.08 : 0.04),
                        tertiary.withValues(alpha: isDark ? 0.05 : 0.02),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primary
                    : _isHovering
                    ? primary.withValues(alpha: isDark ? 0.3 : 0.2)
                    : primary.withValues(alpha: isDark ? 0.10 : 0.06),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: _isHovering || isSelected
                  ? [
                      BoxShadow(
                        color: primary.withValues(
                          alpha: isSelected ? 0.15 : 0.08,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () {
                if (isSelectionMode) {
                  context.read<ScreenshotLibraryCubit>().toggleDesignSelection(
                    widget.design.id,
                  );
                  return;
                }
                final Widget page;
                if (widget.design.isMulti) {
                  page = MultiScreenshotPage(
                    initialSavedDesign: widget.design,
                    displayType: widget.design.design.displayType,
                  );
                } else {
                  page = ScreenshotEditorPage(initialDesign: widget.design);
                }
                final isLarge = MediaQuery.sizeOf(context).width >= 600;
                final sourceRect = isLarge ? rectFromContext(context) : null;
                Navigator.of(context)
                    .push(
                      sourceRect != null
                          ? geniePageRoute(
                              builder: (_) => page,
                              sourceRect: sourceRect,
                            )
                          : MaterialPageRoute(builder: (_) => page),
                    )
                    .then((_) {
                      if (context.mounted) {
                        context.read<ScreenshotLibraryCubit>().loadDesigns();
                      }
                    });
              },
              onLongPress: () {
                if (!isSelectionMode) {
                  context.read<ScreenshotLibraryCubit>().toggleSelectionMode();
                  context.read<ScreenshotLibraryCubit>().toggleDesignSelection(
                    widget.design.id,
                  );
                } else {
                  _showContextMenu(context);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Hero(
                        tag: 'folder_thumb_${widget.design.id}',
                        flightShuttleBuilder:
                            (_, animation, direction, fromCtx, toCtx) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  final t = animation.value;
                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 8 * (1 - t),
                                    borderRadius: BorderRadius.circular(
                                      10 + (0 - 10) * t,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: child,
                                  );
                                },
                                child: direction == HeroFlightDirection.push
                                    ? toCtx.widget
                                    : fromCtx.widget,
                              );
                            },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(widget.design.thumbnailPath),
                              key: ValueKey(
                                '${widget.design.id}_${widget.design.lastModified.millisecondsSinceEpoch}',
                              ),
                              fit: BoxFit.fitWidth,
                              gaplessPlayback: true,
                              width: double.infinity,
                              errorBuilder: (_, _, _) => AspectRatio(
                                aspectRatio: 9 / 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primary.withValues(
                                          alpha: isDark ? 0.12 : 0.06,
                                        ),
                                        tertiary.withValues(
                                          alpha: isDark ? 0.08 : 0.04,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Symbols.broken_image_rounded,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.25),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Info section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.design.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  DateFormat.yMMMd().format(
                                    widget.design.lastModified,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                if (displayType != null &&
                                    displayType.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: _DeviceChip(
                                      label: _formatDisplayType(displayType),
                                      primary: primary,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ], // End Column children
                  ), // End Column
                  if (isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Symbols.check_rounded,
                                size: 16,
                                color: theme.colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ),
                ], // End Stack children
              ), // End Stack
            ), // End InkWell
          ), // End AnimatedContainer
        ), // End AnimatedScale
      ), // End GestureDetector
    ); // End MouseRegion
  }

  String _formatDisplayType(String displayType) {
    // e.g., "iphone_16_pro" → "iPhone 16 Pro"
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
            AppPopupMenuItem(
              value: 'clone_format',
              title: context.l10n.cloneToDevice,
              icon: Symbols.devices_rounded,
            ),
            AppPopupMenuItem(
              value: 'share',
              title: context.l10n.shareDesignFile,
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
        .then((value) async {
          if (!context.mounted || value == null) return;
          if (value == 'clone_format') {
            final newFormatStr = await DeviceSelectionDialog.show(context);
            if (newFormatStr != null && context.mounted) {
              context.read<ScreenshotLibraryCubit>().cloneDesignWithFormat(
                widget.design,
                newFormatStr,
              );
            }
          } else if (value == 'share') {
            if (!context.mounted) return;
            DesignShareHelper.shareDesign(context, widget.design);
          } else if (value == 'move') {
            if (!context.mounted) return;
            _showMoveToFolderDialog(context);
          } else if (value == 'rename') {
            if (!context.mounted) return;
            _showRenameDialog(context);
          } else if (value == 'delete') {
            if (!context.mounted) return;
            _confirmDelete(context);
          }
        });
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.design.name);
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.rename),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.l10n.designName),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l10n.rename),
          ),
        ],
      ),
    ).then((newName) {
      if (newName != null && newName.isNotEmpty && context.mounted) {
        context.read<ScreenshotLibraryCubit>().renameDesign(
          widget.design.id,
          newName,
        );
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    AppDialog.show(
      context,
      title: context.l10n.deleteDesign,
      content: context.l10n.deleteDesignConfirmation,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
      icon: Symbols.delete_rounded,
      sourceRect: rectFromContext(context),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<ScreenshotLibraryCubit>().deleteDesign(widget.design.id);
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
      currentFolderId: widget.design.folderId,
    ).then((result) {
      if (result == null || !context.mounted) return; // cancelled / dismissed
      final newFolderId = result == '__root__' ? null : result;
      if (newFolderId == widget.design.folderId) return; // no change
      cubit.moveDesignToFolder(widget.design.id, newFolderId);
    });
  }
}

/// Small pill-shaped chip for showing the device type
class _DeviceChip extends StatelessWidget {
  final String label;
  final Color primary;
  final bool isDark;

  const _DeviceChip({
    required this.label,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: primary,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
