import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';

import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/settings/presentation/pages/settings_page.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/models/screenshot_studio_item.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/multi_screenshot_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/screenshot_editor_page.dart';

import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/device_selection_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/move_to_folder_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_studio_grid_view.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_studio_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Standalone page for viewing the content of a single folder.
/// Pushed via Navigator so that Hero animations can fly thumbnails
/// from the FolderCard stack to their DesignCard positions.
class FolderDetailPage extends StatefulWidget {
  final DesignFolder folder;

  const FolderDetailPage({super.key, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  bool _isGridView = true;
  final Set<String> _expandedFolderIds = {};
  final GlobalKey _fabKey = GlobalKey();

  late final ScreenshotLibraryCubit _cubit;
  Animation<double>? _routeAnimation;
  bool _hasReset = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ScreenshotLibraryCubit>();
    _cubit.openFolder(widget.folder.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeAnimation = ModalRoute.of(context)?.animation;
      _routeAnimation?.addStatusListener(_onAnimationStatus);
    });
  }

  void _onAnimationStatus(AnimationStatus status) {
    // Fires when the reverse animation finishes (value = 0),
    // so Heroes have already landed and cubit resets instantly.
    if (status == AnimationStatus.dismissed && !_hasReset) {
      _hasReset = true;
      _cubit.navigateBack();
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onAnimationStatus);
    if (!_hasReset) {
      _cubit.navigateBack();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ScreenshotLibraryCubit, ScreenshotLibraryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state, theme),
          floatingActionButton: Hero(
            tag: 'new_design_fab',
            child: _GradientFab(
              key: _fabKey,
              onPressed: () => _showDeviceSelectionDialog(context),
              label: context.l10n.newDesign,
              primary: theme.colorScheme.primary,
              tertiary: theme.colorScheme.tertiary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ScreenshotLibraryState state,
    ThemeData theme,
  ) {
    // Selection mode app bar
    if (state is ScreenshotLibraryLoaded && state.isSelectionMode) {
      final selectedCount =
          state.selectedDesignIds.length + state.selectedFolderIds.length;
      return AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close_rounded),
          onPressed: () =>
              context.read<ScreenshotLibraryCubit>().clearSelection(),
        ),
        title: Text(
          context.l10n.selectedCount(selectedCount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.select_all_rounded),
            tooltip: context.l10n.selectAll,
            onPressed: () => context.read<ScreenshotLibraryCubit>().selectAll(),
          ),
          if (state.selectedDesignIds.isNotEmpty)
            IconButton(
              icon: const Icon(Symbols.download_rounded),
              tooltip: context.l10n.export,
              onPressed: () async {
                final cubit = context.read<ScreenshotLibraryCubit>();
                final file = await cubit.exportSelected();
                if (file != null && context.mounted) {
                  context.showAppSnackbar(context.l10n.exportedDesigns);
                  cubit.clearSelection();
                }
              },
            ),
          IconButton(
            icon: const Icon(Symbols.drive_file_move_rounded),
            tooltip: context.l10n.move,
            onPressed: () => _showMoveSelectedToFolderDialog(context, state),
          ),
          IconButton(
            icon: const Icon(Symbols.delete_rounded),
            tooltip: context.l10n.delete,
            onPressed: () => _confirmDeleteSelected(context),
          ),
          const SizedBox(width: 4),
        ],
      );
    }

    // Default app bar
    return AppBar(
      titleSpacing: 0,
      leading: DragTarget<SavedDesign>(
        onWillAcceptWithDetails: (details) {
          HapticFeedback.selectionClick();
          return true;
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.mediumImpact();
          context.read<ScreenshotLibraryCubit>().moveDesignToFolder(
            details.data.id,
            null, // move to root
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isDragOver = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDragOver
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isDragOver
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      width: 2,
                    )
                  : null,
            ),
            child: const BackButton(),
          );
        },
      ),
      title: _routeAnimation != null
          ? AnimatedBuilder(
              animation: _routeAnimation!,
              builder: (context, child) {
                final value = CurvedAnimation(
                  parent: _routeAnimation!,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                  reverseCurve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                ).value;
                return Transform.translate(
                  offset: Offset(0, 12 * (1 - value)),
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                );
              },
              child: Text(
                widget.folder.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Text(
              widget.folder.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
      actions: [
        if (state is ScreenshotLibraryLoaded &&
            (state.designs.isNotEmpty || state.folders.isNotEmpty))
          IconButton(
            icon: const Icon(Symbols.checklist_rounded),
            tooltip: context.l10n.select,
            onPressed: () =>
                context.read<ScreenshotLibraryCubit>().toggleSelectionMode(),
          ),
        Hero(
          tag: 'view_toggle_action',
          child: IconButton(
            icon: Icon(
              _isGridView
                  ? Symbols.view_list_rounded
                  : Symbols.grid_view_rounded,
            ),
            tooltip: _isGridView
                ? context.l10n.listView
                : context.l10n.gridView,
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ),
        Hero(
          tag: 'settings_action',
          child: Builder(
            builder: (btnContext) => IconButton(
              icon: const Icon(Symbols.settings_rounded),
              tooltip: context.l10n.settings,
              onPressed: () => SettingsDialog.show(
                context,
                sourceRect: rectFromContext(btnContext),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showMoveSelectedToFolderDialog(
    BuildContext context,
    ScreenshotLibraryLoaded state,
  ) async {
    final cubit = context.read<ScreenshotLibraryCubit>();
    final newFolderId = await MoveToFolderDialog.show(
      context,
      folders: state.allFolders,
      excludeFolderIds: state.selectedFolderIds,
    );

    if (newFolderId != null && context.mounted) {
      cubit.moveSelectedToFolder(
        newFolderId == '__root__' ? null : newFolderId,
      );
    }
  }

  void _confirmDeleteSelected(BuildContext context) {
    AppDialog.show(
      context,
      title: context.l10n.delete,
      content: context.l10n.deleteSelectedConfirmation,
      confirmLabel: context.l10n.delete,
      cancelLabel: context.l10n.cancel,
      isDestructive: true,
      icon: Symbols.delete_rounded,
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<ScreenshotLibraryCubit>().deleteSelected();
      }
    });
  }

  Widget _buildBody(BuildContext context, ScreenshotLibraryState state) {
    if (state is! ScreenshotLibraryLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final designs = state.filteredDesigns;
    final folders = state.filteredFolders;
    final hasItems = designs.isNotEmpty || folders.isNotEmpty;

    if (!hasItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.folder_open_rounded,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.emptyFolder,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      final items = [
        ...folders.map((f) => ScreenshotStudioItem.folder(f)),
        ...designs.map((d) => ScreenshotStudioItem.design(d)),
      ];
      return ScreenshotStudioGridView(
        items: items,
        onFolderRename: (f) => _showRenameFolderDialog(context, f),
        onFolderDelete: (id) => _confirmDeleteFolder(context, id),
      );
    } else {
      return ScreenshotStudioListView(
        folders: folders,
        designs: designs,
        allFolders: state.allFolders,
        allDesigns: state.allDesigns,
        expandedFolderIds: _expandedFolderIds,
        onToggleExpansion: (id) {
          setState(() {
            if (_expandedFolderIds.contains(id)) {
              _expandedFolderIds.remove(id);
            } else {
              _expandedFolderIds.add(id);
            }
          });
        },
        onFolderRename: (f) => _showRenameFolderDialog(context, f),
        onFolderDelete: (id) => _confirmDeleteFolder(context, id),
        onDesignDelete: (d) => _confirmDeleteDesign(context, d),
      );
    }
  }

  // ------------------------------------------------------------------
  // Actions (dialogs, context menus, etc.)
  // ------------------------------------------------------------------

  void _showDeviceSelectionDialog(BuildContext context) {
    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? sourceRect;
    if (renderBox != null && renderBox.hasSize) {
      sourceRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    }
    DeviceSelectionDialog.show(context, sourceRect: sourceRect).then((value) {
      if (!context.mounted || value == null) return;
      final Widget page;
      if (value.startsWith('multi:')) {
        page = MultiScreenshotPage(
          displayType: value.substring(6),
          folderId: widget.folder.id,
        );
      } else {
        page = ScreenshotEditorPage(
          displayType: value,
          folderId: widget.folder.id,
        );
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((
        _,
      ) {
        if (context.mounted) {
          context.read<ScreenshotLibraryCubit>().loadDesigns();
        }
      });
    });
  }

  void _confirmDeleteDesign(BuildContext context, SavedDesign design) {
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
        context.read<ScreenshotLibraryCubit>().deleteDesign(design.id);
      }
    });
  }

  void _showRenameFolderDialog(
    BuildContext context,
    DesignFolder folder,
  ) async {
    final name = await showAppInputDialog(
      context,
      title: context.l10n.renameFolder,
      initialValue: folder.name,
      hintText: context.l10n.folderName,
      confirmLabel: context.l10n.confirm,
      cancelLabel: context.l10n.cancel,
    );
    if (name != null &&
        name.isNotEmpty &&
        name != folder.name &&
        context.mounted) {
      context.read<ScreenshotLibraryCubit>().renameFolder(folder.id, name);
    }
  }

  void _confirmDeleteFolder(BuildContext context, String folderId) {
    var deleteDesigns = false;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.error;

    final dialog = StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Symbols.folder_delete_rounded,
            color: accentColor,
            size: 28,
          ),
        ),
        title: Text(
          context.l10n.deleteFolder,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.deleteFolderConfirmation,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    setDialogState(() => deleteDesigns = !deleteDesigns),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: deleteDesigns,
                          onChanged: (v) =>
                              setDialogState(() => deleteDesigns = v ?? false),
                          activeColor: accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.alsoDeleteAllDesigns,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(deleteDesigns),
                  style: FilledButton.styleFrom(backgroundColor: accentColor),
                  child: Text(context.l10n.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    showDialog<bool>(context: context, builder: (_) => dialog).then((
      shouldDeleteDesigns,
    ) {
      if (shouldDeleteDesigns != null && context.mounted) {
        final cubit = context.read<ScreenshotLibraryCubit>();
        if (shouldDeleteDesigns) {
          cubit.deleteFolderWithDesigns(folderId);
        } else {
          cubit.deleteFolder(folderId);
        }
      }
    });
  }
}

class _GradientFab extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final Color primary;
  final Color tertiary;
  final Color onPrimary;

  const _GradientFab({
    super.key,
    required this.onPressed,
    required this.label,
    required this.primary,
    required this.tertiary,
    required this.onPrimary,
  });

  @override
  State<_GradientFab> createState() => _GradientFabState();
}

class _GradientFabState extends State<_GradientFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _bounceBack() {
    _controller.reverse().then((_) {
      if (mounted) {
        _controller
            .animateTo(
              -0.3,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            )
            .then((_) {
              if (mounted) {
                _controller.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeInOut,
                );
              }
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [widget.primary, widget.tertiary]
        : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) => _controller.forward(),
        onPointerUp: (_) => _bounceBack(),
        onPointerCancel: (_) => _bounceBack(),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) =>
                Transform.scale(scale: _scaleAnimation.value, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.add_rounded, color: widget.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
