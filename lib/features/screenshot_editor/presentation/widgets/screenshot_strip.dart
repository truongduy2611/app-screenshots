import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Horizontal strip showing mini-preview tiles for each screenshot slot.
///
/// Placed at the bottom of the multi-screenshot editor. Supports tapping to
/// switch active slot, a "+" button to add new slots, and right-click context
/// menus for duplicate/delete.
class ScreenshotStrip extends StatelessWidget {
  const ScreenshotStrip({super.key});

  static const double _tileHeight = 100;
  static const double _tileWidth = 56; // ~9:16 ratio for portrait phones.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<MultiScreenshotCubit, MultiScreenshotState>(
      builder: (context, state) {
        return Container(
          height: _tileHeight + 24, // tile + padding
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              // Screenshot tiles
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: state.designs.length + (state.canAddMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.designs.length) {
                      return _AddTile(
                        onTap: () =>
                            context.read<MultiScreenshotCubit>().addDesign(),
                      );
                    }
                    return _ScreenshotTile(
                      index: index,
                      isActive: index == state.activeIndex,
                      design: state.designs[index],
                      imageFile: state.imageFiles[index],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  const _ScreenshotTile({
    required this.index,
    required this.isActive,
    required this.design,
    this.imageFile,
  });

  final int index;
  final bool isActive;
  final dynamic design; // ScreenshotDesign
  final dynamic imageFile; // File?

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => context.read<MultiScreenshotCubit>().setActiveIndex(index),
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: ScreenshotStrip._tileWidth,
          height: ScreenshotStrip._tileHeight,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                // Mini preview placeholder
                Center(
                  child: Icon(
                    Symbols.image_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                // Slot number badge
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final cubit = context.read<MultiScreenshotCubit>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    context
        .showAppPopupMenu<String>(
          position: RelativeRect.fromRect(
            position & const Size(1, 1),
            Offset.zero & overlay.size,
          ),
          items: [
            if (cubit.state.canAddMore)
              AppPopupMenuItem(
                value: 'duplicate',
                title: context.l10n.duplicate,
                icon: Symbols.content_copy_rounded,
              ),
            if (cubit.state.designs.length > 1)
              AppPopupMenuItem(
                value: 'delete',
                title: context.l10n.delete,
                icon: Symbols.delete_rounded,
                isDestructive: true,
              ),
          ],
        )
        .then((value) {
          if (value == 'duplicate') {
            cubit.duplicateDesign(index);
          } else if (value == 'delete') {
            cubit.removeDesign(index);
          }
        });
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: ScreenshotStrip._tileWidth,
            height: ScreenshotStrip._tileHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Symbols.add_rounded,
                size: 24,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
