import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/models/screenshot_studio_item.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/pages/folder_detail_page.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/design_card.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/folder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ScreenshotStudioGridView extends StatelessWidget {
  final List<ScreenshotStudioItem> items;
  final Function(DesignFolder) onFolderRename;
  final Function(String) onFolderDelete;
  final bool isSearching;

  const ScreenshotStudioGridView({
    super.key,
    required this.items,
    required this.onFolderRename,
    required this.onFolderDelete,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 6);

        return MasonryGridView.count(
          padding: const EdgeInsets.all(16).copyWith(bottom: 128),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.isFolder) {
              final cubit = context.read<ScreenshotLibraryCubit>();
              final allDesigns = cubit.state is ScreenshotLibraryLoaded
                  ? (cubit.state as ScreenshotLibraryLoaded).allDesigns
                  : <SavedDesign>[];
              final folderDesigns = allDesigns
                  .where((d) => d.folderId == item.folder!.id)
                  .toList();
              final previewDesigns = folderDesigns.take(3).toList();

              return Builder(
                builder: (cardContext) => FolderCard(
                  folder: item.folder!,
                  itemCount: folderDesigns.length,
                  thumbnailPaths: previewDesigns
                      .map((d) => d.thumbnailPath)
                      .toList(),
                  thumbnailDesignIds: isSearching
                      ? const []
                      : previewDesigns.map((d) => d.id).toList(),
                  onTap: () => _openFolder(cardContext, item.folder!),
                  onDelete: () => onFolderDelete(item.folder!.id),
                  onRename: () => onFolderRename(item.folder!),
                  onDrop: (design) => context
                      .read<ScreenshotLibraryCubit>()
                      .moveDesignToFolder(design.id, item.folder!.id),
                ),
              );
            } else {
              return DraggableDesignCard(design: item.design!);
            }
          },
        );
      },
    );
  }

  void _openFolder(BuildContext cardContext, DesignFolder folder) {
    final cubit = cardContext.read<ScreenshotLibraryCubit>();
    final sourceRect =
        rectFromContext(cardContext) ??
        Rect.fromCenter(
          center: const Offset(200, 400),
          width: 180,
          height: 280,
        );

    Navigator.of(cardContext).push(
      geniePageRoute(
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: FolderDetailPage(folder: folder),
        ),
        sourceRect: sourceRect,
      ),
    );
  }
}
