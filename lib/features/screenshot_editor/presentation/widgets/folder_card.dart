import 'dart:io';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class FolderCard extends StatefulWidget {
  final DesignFolder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final Function(SavedDesign) onDrop;
  final int itemCount;
  final List<String> thumbnailPaths;
  final List<String> thumbnailDesignIds;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onDrop,
    this.itemCount = 0,
    this.thumbnailPaths = const [],
    this.thumbnailDesignIds = const [],
  });

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final tertiary = theme.colorScheme.tertiary;

    return BlocSelector<
      ScreenshotLibraryCubit,
      ScreenshotLibraryState,
      ({bool selectionMode, bool selected})
    >(
      selector: (state) => (
        selectionMode:
            state is ScreenshotLibraryLoaded && state.isSelectionMode,
        selected:
            state is ScreenshotLibraryLoaded &&
            state.selectedFolderIds.contains(widget.folder.id),
      ),
      builder: (context, sel) {
        final isSelectionMode = sel.selectionMode;
        final isSelected = sel.selected;

        return DragTarget<SavedDesign>(
          onWillAcceptWithDetails: (details) {
            HapticFeedback.selectionClick();
            return true;
          },
          onAcceptWithDetails: (details) {
            HapticFeedback.mediumImpact();
            widget.onDrop(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final isDragHovered = candidateData.isNotEmpty;

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
                                tertiary.withValues(
                                  alpha: isDark ? 0.15 : 0.08,
                                ),
                              ]
                            : isDragHovered
                            ? [
                                primary.withValues(alpha: isDark ? 0.25 : 0.15),
                                tertiary.withValues(
                                  alpha: isDark ? 0.15 : 0.08,
                                ),
                              ]
                            : [
                                primary.withValues(alpha: isDark ? 0.08 : 0.05),
                                tertiary.withValues(
                                  alpha: isDark ? 0.05 : 0.03,
                                ),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? primary
                            : isDragHovered
                            ? primary.withValues(alpha: 0.5)
                            : _isHovering
                            ? primary.withValues(alpha: isDark ? 0.3 : 0.2)
                            : primary.withValues(alpha: isDark ? 0.12 : 0.08),
                        width: isSelected || isDragHovered ? 2 : 1,
                      ),
                      boxShadow: _isHovering || isDragHovered || isSelected
                          ? [
                              BoxShadow(
                                color: primary.withValues(
                                  alpha: (isDragHovered || isSelected)
                                      ? 0.15
                                      : 0.08,
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
                          context
                              .read<ScreenshotLibraryCubit>()
                              .toggleFolderSelection(widget.folder.id);
                        } else {
                          widget.onTap();
                        }
                      },
                      onLongPress: () {
                        if (!isSelectionMode) {
                          context
                              .read<ScreenshotLibraryCubit>()
                              .toggleSelectionMode();
                          context
                              .read<ScreenshotLibraryCubit>()
                              .toggleFolderSelection(widget.folder.id);
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
                              // Thumbnail stack or empty folder icon
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: widget.thumbnailPaths.isNotEmpty
                                    ? _FolderThumbnailStack(
                                        thumbnailPaths: widget.thumbnailPaths,
                                        thumbnailDesignIds:
                                            widget.thumbnailDesignIds,
                                        primary: primary,
                                        isDark: isDark,
                                      )
                                    : AspectRatio(
                                        aspectRatio: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: primary.withValues(
                                              alpha: isDark ? 0.05 : 0.03,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Symbols.folder_open_rounded,
                                              size: 48,
                                              color: primary.withValues(
                                                alpha: isDark ? 0.3 : 0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              // Folder name & item count
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.folder.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.itemCount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.itemCount} ${widget.itemCount == 1 ? 'item' : 'items'}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.45),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                                  color: isSelected
                                      ? primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.3),
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
                        ], // Stack children
                      ), // Stack
                    ), // InkWell
                  ), // AnimatedContainer
                ), // AnimatedScale
              ), // GestureDetector
            ); // MouseRegion
          },
        ); // DragTarget
      }, // BlocSelector builder
    ); // BlocSelector
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
            widget.onRename();
          } else if (value == 'delete') {
            widget.onDelete();
          }
        });
  }
}

/// Stacked fan of up to 3 screenshot thumbnails with a folder badge.
/// Fills the available width and adapts height to the dominant aspect ratio.
class _FolderThumbnailStack extends StatefulWidget {
  final List<String> thumbnailPaths;
  final List<String> thumbnailDesignIds;
  final Color primary;
  final bool isDark;

  const _FolderThumbnailStack({
    required this.thumbnailPaths,
    this.thumbnailDesignIds = const [],
    required this.primary,
    required this.isDark,
  });

  @override
  State<_FolderThumbnailStack> createState() => _FolderThumbnailStackState();
}

class _FolderThumbnailStackState extends State<_FolderThumbnailStack> {
  /// The dominant aspect ratio used for the overall container shape.
  double? _dominantRatio;

  /// Per-path aspect ratios – each card keeps its own natural shape.
  final Map<String, double> _perPathRatios = {};

  @override
  void initState() {
    super.initState();
    _resolveAllThumbnails();
  }

  @override
  void didUpdateWidget(covariant _FolderThumbnailStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailPaths != widget.thumbnailPaths) {
      _perPathRatios.clear();
      _dominantRatio = null;
      _resolveAllThumbnails();
    }
  }

  void _resolveAllThumbnails() {
    final paths = widget.thumbnailPaths.take(3).toList();
    if (paths.isEmpty) return;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final file = File(path);
      if (!file.existsSync()) continue;

      final image = FileImage(file);
      image
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener((info, _) {
              if (!mounted) return;
              final ratio =
                  info.image.width.toDouble() / info.image.height.toDouble();
              _perPathRatios[path] = ratio;

              setState(() {
                _dominantRatio = _pickDominantRatio(
                  _perPathRatios.values.toList(),
                );
              });
            }),
          );
    }
  }

  /// Picks the dominant aspect ratio by majority vote:
  /// Group ratios into portrait (<0.9), landscape (>1.1), or square,
  /// then return the average of the largest group.
  double _pickDominantRatio(List<double> ratios) {
    if (ratios.isEmpty) return 9 / 16;
    if (ratios.length == 1) return ratios.first;

    final portrait = <double>[];
    final landscape = <double>[];
    final square = <double>[];

    for (final r in ratios) {
      if (r < 0.9) {
        portrait.add(r);
      } else if (r > 1.1) {
        landscape.add(r);
      } else {
        square.add(r);
      }
    }

    // Pick the group with the most entries.
    List<double> dominant = portrait;
    if (landscape.length > dominant.length) dominant = landscape;
    if (square.length > dominant.length) dominant = square;
    if (dominant.isEmpty) dominant = ratios;

    return dominant.reduce((a, b) => a + b) / dominant.length;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.thumbnailPaths.length.clamp(0, 3);
    final paths = widget.thumbnailPaths.take(count).toList();
    final containerRatio = _dominantRatio ?? (9 / 16);

    // Use the dominant ratio for the overall section aspect ratio.
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: containerRatio,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primary.withValues(alpha: widget.isDark ? 0.10 : 0.05),
                widget.primary.withValues(alpha: widget.isDark ? 0.05 : 0.02),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final areaWidth = constraints.maxWidth;
              final areaHeight = constraints.maxHeight;

              // Adaptive card width: fewer cards → fill more of the area.
              final widthFraction = switch (count) {
                1 => 0.85,
                2 => 0.78,
                _ => 0.72,
              };
              final baseCardWidth = areaWidth * widthFraction;

              // Per-card depth: subtle size difference.
              const scales = [0.92, 0.96, 1.0];

              // Tight pile with subtle fan.
              const rotations = [-0.05, 0.04, 0.0];
              final xOffsets = [-areaWidth * 0.06, areaWidth * 0.04, 0.0];
              final yOffsets = [-areaHeight * 0.02, areaHeight * 0.01, 0.0];

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < paths.length; i++) ...[
                    () {
                      final idx = 3 - count + i;
                      final scale = scales[idx];

                      // Use each card's own aspect ratio, falling back
                      // to the container ratio if not yet resolved.
                      final cardRatio =
                          _perPathRatios[paths[i]] ?? containerRatio;

                      final w = baseCardWidth * scale;
                      // Height from the card's own ratio, but capped so
                      // extreme ratios don't overflow the container.
                      final h = (w / cardRatio).clamp(
                        areaHeight * 0.25,
                        areaHeight * 0.90,
                      );

                      // Three-tier shadow system.
                      final depthFactor = idx / 2.0; // 0.0 → 1.0
                      final isFront = idx == 2;
                      // Wrap entire card in Hero when we have a matching
                      // design ID, so the frame + shadow fly together.
                      Widget card = Container(
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: widget.isDark ? 0.12 : 0.7,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            // 1. Contact shadow — tight, dark.
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: widget.isDark
                                    ? 0.30 + depthFactor * 0.10
                                    : 0.10 + depthFactor * 0.06,
                              ),
                              blurRadius: 3 + depthFactor * 3,
                              offset: Offset(0, 1 + depthFactor * 1.5),
                            ),
                            // 2. Ambient shadow — wide, soft.
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: widget.isDark
                                    ? 0.12 + depthFactor * 0.06
                                    : 0.04 + depthFactor * 0.04,
                              ),
                              blurRadius: 10 + depthFactor * 6,
                              offset: Offset(0, 3 + depthFactor * 3),
                              spreadRadius: 1,
                            ),
                            // 3. Colored glow on front card only.
                            if (isFront)
                              BoxShadow(
                                color: widget.primary.withValues(
                                  alpha: widget.isDark ? 0.12 : 0.06,
                                ),
                                blurRadius: 16,
                                spreadRadius: -2,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.5),
                          child: Stack(
                            children: [
                              // Thumbnail image.
                              Positioned.fill(
                                child: _buildThumbnailImage(paths[i], w, h),
                              ),
                              // Top highlight strip — paper/glass edge.
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 1,
                                child: Container(
                                  color: Colors.white.withValues(
                                    alpha: widget.isDark ? 0.08 : 0.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      // Wrap in Hero if we have a design ID for this card.
                      if (i < widget.thumbnailDesignIds.length) {
                        final designId = widget.thumbnailDesignIds[i];
                        card = Hero(
                          tag: 'folder_thumb_$designId',
                          flightShuttleBuilder:
                              (_, animation, direction, fromCtx, toCtx) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    final t = animation.value;
                                    return Material(
                                      color: Colors.transparent,
                                      elevation: 8 * t,
                                      borderRadius: BorderRadius.circular(
                                        8 + (10 - 8) * t,
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
                          child: card,
                        );
                      }

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setTranslationRaw(xOffsets[idx], yOffsets[idx], 0)
                          ..rotateZ(rotations[idx]),
                        child: card,
                      );
                    }(),
                  ],

                  // Folder badge – bottom-right with frosted glass look
                  Positioned(
                    right: areaWidth * 0.06,
                    bottom: areaHeight * 0.04,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            (widget.isDark
                                    ? Colors.grey.shade800
                                    : Colors.white)
                                .withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: widget.isDark ? 0.35 : 0.14,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Symbols.folder_rounded,
                        size: 14,
                        color: widget.primary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(String path, double w, double h) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: w,
      height: h,
      cacheWidth: 400,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Container(
        color: widget.primary.withValues(alpha: widget.isDark ? 0.15 : 0.08),
        child: Icon(
          Symbols.broken_image_rounded,
          size: 20,
          color: widget.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
