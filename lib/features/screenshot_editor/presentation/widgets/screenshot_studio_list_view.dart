import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/design_share_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/multi_screenshot_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/screenshot_editor_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/design_list_tile.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/folder_list_tile.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScreenshotStudioListView extends StatelessWidget {
  /// Top-level folders for the current folder.
  final List<DesignFolder> folders;

  /// Top-level designs for the current folder.
  final List<SavedDesign> designs;

  /// ALL designs across all folders (for expanded sub-folder content).
  final List<SavedDesign> allDesigns;

  /// ALL folders across all levels (for expanded sub-folder content).
  final List<DesignFolder> allFolders;
  final Set<String> expandedFolderIds;
  final Function(String) onToggleExpansion;
  final Function(DesignFolder) onFolderRename;
  final Function(String) onFolderDelete;
  final Function(SavedDesign) onDesignDelete;

  const ScreenshotStudioListView({
    super.key,
    required this.folders,
    required this.designs,
    required this.allDesigns,
    required this.allFolders,
    required this.expandedFolderIds,
    required this.onToggleExpansion,
    required this.onFolderRename,
    required this.onFolderDelete,
    required this.onDesignDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 128),
      children: [
        // Folders (each is a group with its children)
        for (final folder in folders) ...[
          _FolderGroup(
            folder: folder,
            isExpanded: expandedFolderIds.contains(folder.id),
            expandedFolderIds: expandedFolderIds,
            allDesigns: allDesigns,
            allFolders: allFolders,
            onToggleExpansion: onToggleExpansion,
            onFolderRename: onFolderRename,
            onFolderDelete: onFolderDelete,
            onDesignDelete: onDesignDelete,
          ),
          const SizedBox(height: 8),
        ],
        // Top-level designs (not in any folder)
        for (final design in designs) ...[
          _buildDesignTile(context, design),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDesignTile(BuildContext context, SavedDesign design) {
    return DesignListTile(
      design: design,
      onTap: () {
        final Widget page;
        if (design.isMulti) {
          page = MultiScreenshotPage(
            initialSavedDesign: design,
            displayType: design.design.displayType,
          );
        } else {
          page = ScreenshotEditorPage(initialDesign: design);
        }
        final isLarge = MediaQuery.sizeOf(context).width >= 600;
        final sourceRect = isLarge ? rectFromContext(context) : null;
        Navigator.of(context)
            .push(
              sourceRect != null
                  ? geniePageRoute(builder: (_) => page, sourceRect: sourceRect)
                  : MaterialPageRoute(builder: (_) => page),
            )
            .then((_) {
              if (context.mounted) {
                context.read<ScreenshotLibraryCubit>().loadDesigns();
              }
            });
      },
      onDelete: () => onDesignDelete(design),
      onRename: (newName) {
        context.read<ScreenshotLibraryCubit>().renameDesign(design.id, newName);
      },
      onShare: () => DesignShareHelper.shareDesign(context, design),
    );
  }
}

// =============================================================================
// Folder group widget – renders folder header + animated children container
// =============================================================================

class _FolderGroup extends StatelessWidget {
  final DesignFolder folder;
  final bool isExpanded;
  final Set<String> expandedFolderIds;
  final List<SavedDesign> allDesigns;
  final List<DesignFolder> allFolders;
  final Function(String) onToggleExpansion;
  final Function(DesignFolder) onFolderRename;
  final Function(String) onFolderDelete;
  final Function(SavedDesign) onDesignDelete;

  const _FolderGroup({
    required this.folder,
    required this.isExpanded,
    required this.expandedFolderIds,
    required this.allDesigns,
    required this.allFolders,
    required this.onToggleExpansion,
    required this.onFolderRename,
    required this.onFolderDelete,
    required this.onDesignDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final childFolders = allFolders
        .where((f) => f.parentId == folder.id)
        .toList();
    final childDesigns = allDesigns
        .where((d) => d.folderId == folder.id)
        .toList();
    final hasChildren = childFolders.isNotEmpty || childDesigns.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isExpanded
            ? primary.withValues(alpha: isDark ? 0.06 : 0.03)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isExpanded
            ? Border.all(color: primary.withValues(alpha: isDark ? 0.12 : 0.07))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Folder header
          FolderListTile(
            folder: folder,
            isExpanded: isExpanded,
            onTap: () => onToggleExpansion(folder.id),
            onDelete: () => onFolderDelete(folder.id),
            onRename: () => onFolderRename(folder),
            onDrop: (data) {
              if (data is SavedDesign) {
                context.read<ScreenshotLibraryCubit>().moveDesignToFolder(
                  data.id,
                  folder.id,
                );
              } else if (data is DesignFolder) {
                context.read<ScreenshotLibraryCubit>().moveFolderToFolder(
                  data.id,
                  folder.id,
                );
              }
            },
          ),
          // Animated children
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded && hasChildren
                ? _buildChildren(context, childFolders, childDesigns)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildChildren(
    BuildContext context,
    List<DesignFolder> childFolders,
    List<SavedDesign> childDesigns,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-folders (recursive)
          for (final sub in childFolders) ...[
            _FolderGroup(
              folder: sub,
              isExpanded: expandedFolderIds.contains(sub.id),
              expandedFolderIds: expandedFolderIds,
              allDesigns: allDesigns,
              allFolders: allFolders,
              onToggleExpansion: onToggleExpansion,
              onFolderRename: onFolderRename,
              onFolderDelete: onFolderDelete,
              onDesignDelete: onDesignDelete,
            ),
            const SizedBox(height: 6),
          ],
          // Designs in this folder
          for (final design in childDesigns) ...[
            DesignListTile(
              design: design,
              onTap: () {
                final Widget page;
                if (design.isMulti) {
                  page = MultiScreenshotPage(
                    initialSavedDesign: design,
                    displayType: design.design.displayType,
                  );
                } else {
                  page = ScreenshotEditorPage(initialDesign: design);
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
              onDelete: () => onDesignDelete(design),
              onRename: (newName) {
                context.read<ScreenshotLibraryCubit>().renameDesign(
                  design.id,
                  newName,
                );
              },
              onShare: () => DesignShareHelper.shareDesign(context, design),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
