import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:app_screenshots/core/services/file_open_service.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/models/screenshot_studio_item.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/screenshot_editor_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/multi_screenshot_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/device_selection_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_studio_empty_state.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/move_to_folder_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_studio_grid_view.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_studio_list_view.dart';
import 'package:app_screenshots/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class ScreenshotStudioPage extends StatelessWidget {
  const ScreenshotStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ScreenshotLibraryCubit>()..loadDesigns(),
      child: const ScreenshotStudioView(),
    );
  }
}

class ScreenshotStudioView extends StatefulWidget {
  const ScreenshotStudioView({super.key});

  @override
  State<ScreenshotStudioView> createState() => _ScreenshotStudioViewState();
}

class _ScreenshotStudioViewState extends State<ScreenshotStudioView> {
  bool _isGridView = true;
  final Set<String> _expandedFolderIds = {};
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    AppLogger.d('initState — wiring FileOpenService callback', tag: 'Studio');
    // Wire up file open events — directly open the editor
    sl<FileOpenService>().onFileOpened = (file) async {
      AppLogger.d('onFileOpened callback fired: ${file.path}', tag: 'Studio');
      if (!mounted) {
        AppLogger.d('Widget not mounted, aborting', tag: 'Studio');
        return;
      }

      // Parse the .appshots file
      final designFileService = sl<DesignFileService>();
      final design = await designFileService.parseExportFile(file);
      if (!mounted) return;

      if (design == null) {
        context.showAppSnackbar(
          context.l10n.failedToImportDesign,
          type: AppSnackbarType.error,
        );
        return;
      }

      // Open the appropriate editor with sourceFilePath set
      if (design.isMulti) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiScreenshotPage(
              initialSavedDesign: design,
              sourceFilePath: file.path,
            ),
          ),
        );
      } else {
        ScreenshotEditorPage.show(
          context,
          initialDesign: design,
          sourceFilePath: file.path,
        );
      }
    };

    // Register CLI navigation so `multi open` can push the editor page
    sl<CommandServer>().registerNavigation(
      openMulti: (displayType) async {
        if (!mounted) return;
        final currentFolderId = context
            .read<ScreenshotLibraryCubit>()
            .currentFolderId;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiScreenshotPage(
              displayType: displayType,
              folderId: currentFolderId,
            ),
          ),
        );
        // Small delay for the page to mount and register its cubits
        await Future.delayed(const Duration(milliseconds: 500));
      },
    );
  }

  @override
  void dispose() {
    sl<FileOpenService>().onFileOpened = null;
    sl<CommandServer>().unregisterNavigation();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotLibraryCubit, ScreenshotLibraryState>(
      builder: (context, state) {
        final theme = Theme.of(context);

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
          body: Column(
            children: [
              // Search bar
              if (state is ScreenshotLibraryLoaded &&
                  (state.designs.isNotEmpty || state.folders.isNotEmpty))
                _SearchBar(
                  controller: _searchController,
                  onChanged: (query) =>
                      context.read<ScreenshotLibraryCubit>().search(query),
                ),
              // Body content
              Expanded(
                child: GestureDetector(
                  onSecondaryTapDown: (details) =>
                      _showContextMenu(context, details.globalPosition),
                  behavior: HitTestBehavior.translucent,
                  child: _buildBody(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ScreenshotLibraryState state,
    ThemeData theme,
  ) {
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

    return AppBar(
      title: Text(
        context.l10n.appTitle,
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
        Builder(
            builder: (btnContext) => IconButton(
              icon: const Icon(Symbols.create_new_folder_rounded),
              tooltip: context.l10n.newFolder,
              onPressed: () => _showCreateFolderDialog(
                context,
                sourceRect: rectFromContext(btnContext),
              ),
            ),
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

  void _confirmDeleteSelected(BuildContext context) {
    AppDialog.show(
      context,
      title: context.l10n.delete, // Default to localized strings
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
    if (state is ScreenshotLibraryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ScreenshotLibraryLoaded) {
      // When searching, use filtered results across all levels;
      // otherwise show root-level content only.
      final isSearching = state.searchQuery.isNotEmpty;
      final designs = isSearching
          ? state.filteredDesigns
          : state.allDesigns.where((d) => d.folderId == null).toList();
      final folders = isSearching
          ? state.filteredFolders
          : state.allFolders.where((f) => f.parentId == null).toList();
      final hasItems = designs.isNotEmpty || folders.isNotEmpty;

      if (!hasItems && state.searchQuery.isEmpty) {
        return const ScreenshotStudioEmptyState();
      }

      if (!hasItems && state.searchQuery.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.search_off_rounded,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.noResultsFor(state.searchQuery),
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
          isSearching: isSearching,
          onFolderRename: (f) => _showRenameFolderDialog(
            context,
            f,
            sourceRect: rectFromContext(context),
          ),
          onFolderDelete: (id) => _confirmDeleteFolder(
            context,
            id,
            sourceRect: rectFromContext(context),
          ),
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
          onFolderRename: (f) => _showRenameFolderDialog(
            context,
            f,
            sourceRect: rectFromContext(context),
          ),
          onFolderDelete: (id) => _confirmDeleteFolder(
            context,
            id,
            sourceRect: rectFromContext(context),
          ),
          onDesignDelete: (d) => _confirmDeleteDesign(
            context,
            d,
            sourceRect: rectFromContext(context),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _confirmDeleteDesign(
    BuildContext context,
    SavedDesign design, {
    Rect? sourceRect,
  }) {
    AppDialog.show(
      context,
      title: context.l10n.deleteDesign,
      content: context.l10n.deleteDesignConfirmation,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
      icon: Symbols.delete_rounded,
      sourceRect: sourceRect,
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<ScreenshotLibraryCubit>().deleteDesign(design.id);
      }
    });
  }

  void _showCreateFolderDialog(BuildContext context, {Rect? sourceRect}) async {
    final name = await showAppInputDialog(
      context,
      title: context.l10n.newFolder,
      hintText: context.l10n.folderName,
      confirmLabel: context.l10n.confirm,
      cancelLabel: context.l10n.cancel,
      sourceRect: sourceRect,
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<ScreenshotLibraryCubit>().createFolder(name);
    }
  }

  void _showRenameFolderDialog(
    BuildContext context,
    DesignFolder folder, {
    Rect? sourceRect,
  }) async {
    final name = await showAppInputDialog(
      context,
      title: context.l10n.renameFolder,
      initialValue: folder.name,
      hintText: context.l10n.folderName,
      confirmLabel: context.l10n.confirm,
      cancelLabel: context.l10n.cancel,
      sourceRect: sourceRect,
    );
    if (name != null &&
        name.isNotEmpty &&
        name != folder.name &&
        context.mounted) {
      context.read<ScreenshotLibraryCubit>().renameFolder(folder.id, name);
    }
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

  void _confirmDeleteFolder(
    BuildContext context,
    String folderId, {
    Rect? sourceRect,
  }) {
    final Future<bool?> result;
    final dialog = _DeleteFolderDialog();
    if (sourceRect != null) {
      result = showGenieDialog<bool>(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => dialog,
      );
    } else {
      result = showDialog<bool>(context: context, builder: (_) => dialog);
    }

    result.then((shouldDeleteDesigns) {
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

  Rect? _getFabRect() {
    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position & renderBox.size;
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final relativeRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    );

    final result = await context.showAppPopupMenu<String>(
      position: relativeRect,
      items: [
        AppPopupMenuItem<String>(
          value: 'new_folder',
          title: context.l10n.newFolder,
          icon: Symbols.create_new_folder_rounded,
        ),
        AppPopupMenuItem<String>(
          value: 'new_design',
          title: context.l10n.newDesign,
          icon: Symbols.add_photo_alternate_rounded,
        ),
      ],
    );

    if (!context.mounted || result == null) return;

    switch (result) {
      case 'new_folder':
        _showCreateFolderDialog(context);
        break;
      case 'new_design':
        _showDeviceSelectionDialog(context);
        break;
    }
  }

  void _showDeviceSelectionDialog(BuildContext context) {
    final sourceRect = _getFabRect();
    DeviceSelectionDialog.show(context, sourceRect: sourceRect).then((value) {
      if (!context.mounted) return;
      if (value != null) {
        final currentFolderId = context
            .read<ScreenshotLibraryCubit>()
            .currentFolderId;
        final Widget page;
        if (value.startsWith('multi:')) {
          final displayType = value.substring(6);
          page = MultiScreenshotPage(
            displayType: displayType,
            folderId: currentFolderId,
          );
        } else {
          page = ScreenshotEditorPage(
            displayType: value,
            folderId: currentFolderId,
          );
        }
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => page)).then((_) {
          if (context.mounted) {
            context.read<ScreenshotLibraryCubit>().loadDesigns();
          }
        });
      }
    });
  }
}

/// Rounded search bar with glassmorphism styling
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final isSmall = MediaQuery.sizeOf(context).width < 600;
    final horizontalPad = isSmall ? 12.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: context.l10n.searchDesignsAndFolders,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          prefixIcon: Icon(
            Symbols.search_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Symbols.close_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: primary.withValues(alpha: isDark ? 0.06 : 0.03),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Gradient-filled floating action button with bounce animation
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
    // Light mode: richer indigo → violet for more visual pop
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

// ─────────────────────────────────────────────────────────────────────────────
// Delete folder confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Dialog that asks whether to delete a folder and optionally its designs.
/// Returns `true` to delete folder + designs, `false` for folder only, `null`
/// if cancelled.
class _DeleteFolderDialog extends StatefulWidget {
  const _DeleteFolderDialog();

  @override
  State<_DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<_DeleteFolderDialog> {
  bool _deleteDesigns = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.error;

    return AlertDialog(
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
              onTap: () => setState(() => _deleteDesigns = !_deleteDesigns),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _deleteDesigns,
                        onChanged: (v) =>
                            setState(() => _deleteDesigns = v ?? false),
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
              child: AppButton.outlined(
                label: context.l10n.cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.destructive(
                label: context.l10n.delete,
                onPressed: () => Navigator.of(context).pop(_deleteDesigns),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
