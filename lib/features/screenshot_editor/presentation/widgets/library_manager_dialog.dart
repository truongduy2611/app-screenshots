import 'dart:io';
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/device_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class LibraryManagerDialog extends StatefulWidget {
  const LibraryManagerDialog({super.key});

  @override
  State<LibraryManagerDialog> createState() => _LibraryManagerDialogState();
}

class _LibraryManagerDialogState extends State<LibraryManagerDialog> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ScreenshotLibraryCubit>()..loadDesigns(),
      child: AlertDialog(
        title: Text(context.l10n.library),
        content: SizedBox(
          width: 600,
          height: 600,
          child: BlocBuilder<ScreenshotLibraryCubit, ScreenshotLibraryState>(
            builder: (context, state) {
              if (state is! ScreenshotLibraryLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.designs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.folder_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(context.l10n.noDesignsYet),
                    ],
                  ),
                );
              }

              return GridView.builder(
                itemCount: state.designs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  return _DesignCard(design: state.designs[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final SavedDesign design;

  const _DesignCard({required this.design});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () {
          context.read<ScreenshotEditorCubit>().loadDesignIntoEditor(design);
          Navigator.of(context).pop();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.file(
                File(design.thumbnailPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Symbols.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          design.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat.yMMMd().format(design.lastModified),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Symbols.more_vert_rounded),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _showDeleteConfirm(context);
                      } else if (value == 'clone_format') {
                        final newFormatStr = await DeviceSelectionDialog.show(
                          context,
                        );
                        if (newFormatStr != null && context.mounted) {
                          context
                              .read<ScreenshotLibraryCubit>()
                              .cloneDesignWithFormat(design, newFormatStr);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'clone_format',
                        child: Row(
                          children: [
                            const Icon(Symbols.devices_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(context.l10n.cloneToDevice),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Symbols.delete_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    AppDialog.show(
      context,
      title: context.l10n.deleteDesign,
      content: context.l10n.deleteDesignConfirmation,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
      icon: Symbols.delete_rounded,
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<ScreenshotLibraryCubit>().deleteDesign(design.id);
      }
    });
  }
}
