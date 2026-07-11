part of 'multi_screenshot_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Canvas area with interactive viewer, dot grid, and drag-drop
// ─────────────────────────────────────────────────────────────────────────────

class _MultiCanvasArea extends StatefulWidget {
  final ScreenshotController screenshotController;
  final CanvasViewportController viewportController;
  final VoidCallback onSyncBack;
  final VoidCallback onSyncActiveDesign;
  final VoidCallback onZoomToFit;

  const _MultiCanvasArea({
    required this.screenshotController,
    required this.viewportController,
    required this.onSyncBack,
    required this.onSyncActiveDesign,
    required this.onZoomToFit,
  });

  @override
  State<_MultiCanvasArea> createState() => _MultiCanvasAreaState();
}

class _MultiCanvasAreaState extends State<_MultiCanvasArea> {
  static const _gap = 200.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0);

    return DropTarget(
      onDragDone: (details) async {
        if (details.files.isNotEmpty) {
          widget.onSyncBack();
          final files = details.files.map((f) => File(f.path)).toList();
          final multiCubit = context.read<MultiScreenshotCubit>();
          await multiCubit.replaceActiveImageAndImport(files);
          // Update the editor cubit's image directly (without going through
          // loadDesignForMultiMode which would clear the undo/redo stacks).
          if (!context.mounted) return;
          final newImage = multiCubit.state.activeImageFile;
          if (newImage != null) {
            context.read<ScreenshotEditorCubit>().updateImageFile(newImage);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onZoomToFit();
          });
        }
      },
      child: BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        buildWhen: (prev, curr) =>
            prev.design.gridSettings.showDotGrid !=
            curr.design.gridSettings.showDotGrid,
        builder: (context, editorState) {
          final showDots = editorState.design.gridSettings.showDotGrid;

          return Stack(
            children: [
              if (showDots)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotGridPainter(
                      dotColor: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.2,
                      ),
                      backgroundColor: canvasBg,
                    ),
                  ),
                )
              else
                Positioned.fill(child: ColoredBox(color: canvasBg)),
              FigmaCanvasViewport(
                controller: widget.viewportController,
                // Only the row *skeleton* depends on the whole multi state;
                // each slot scopes its own rebuilds via _CanvasSlotHost so a
                // sync-back or active-index change doesn't rebuild all
                // previews.
                child:
                    BlocSelector<
                      MultiScreenshotCubit,
                      MultiScreenshotState,
                      (int, bool)
                    >(
                      selector: (state) => (
                        state.designs.length,
                        state.canAddMore,
                      ),
                      builder: (context, skeleton) {
                        final (designCount, canAddMore) = skeleton;
                        return Padding(
                          padding: const EdgeInsets.all(100),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < designCount; i++) ...[
                                if (i > 0) const SizedBox(width: _gap),
                                _CanvasSlotHost(
                                  key: ValueKey('slot-$i'),
                                  index: i,
                                  screenshotController:
                                      widget.screenshotController,
                                  onSyncBack: widget.onSyncBack,
                                  onSyncActiveDesign:
                                      widget.onSyncActiveDesign,
                                ),
                              ],
                              // ── Add-new placeholder ──
                              if (canAddMore) ...[
                                const SizedBox(width: _gap),
                                _AddPlaceholderHost(
                                  onSyncBack: widget.onSyncBack,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-slot host — scopes rebuilds to the slot's own data
// ─────────────────────────────────────────────────────────────────────────────

/// Hosts one [CanvasSlot] and rebuilds it only when that slot's design,
/// image, active flag, or the previewed locale changes — not on every
/// [MultiScreenshotState] emit. Also isolates the slot's repaints behind a
/// [RepaintBoundary] so pan/zoom re-composites cached layers.
class _CanvasSlotHost extends StatelessWidget {
  const _CanvasSlotHost({
    super.key,
    required this.index,
    required this.screenshotController,
    required this.onSyncBack,
    required this.onSyncActiveDesign,
  });

  final int index;
  final ScreenshotController screenshotController;
  final VoidCallback onSyncBack;
  final VoidCallback onSyncActiveDesign;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      MultiScreenshotCubit,
      MultiScreenshotState,
      (ScreenshotDesign?, File?, bool, int)
    >(
      // Guard the index: on removal this selector runs against the shrunken
      // state before the row skeleton unmounts this host.
      selector: (state) => (
        index < state.designs.length ? state.designs[index] : null,
        index < state.imageFiles.length ? state.imageFiles[index] : null,
        index == state.activeIndex,
        state.designs.length,
      ),
      builder: (context, vm) {
        final (design, imageFile, isActive, designCount) = vm;
        if (design == null) return const SizedBox.shrink();

        // Locale preview state, selected per slot so only actual locale /
        // locale-image changes rebuild this slot.
        final (previewLocale, hasLocaleImage) = context
            .select<TranslationCubit, (String?, bool)>((cubit) {
              final locale = cubit.state.previewLocale;
              return (
                locale,
                locale != null &&
                    cubit.state.bundle?.getLocaleImage(locale, index) != null,
              );
            });

        return RepaintBoundary(
          child: CanvasSlot(
            index: index,
            design: design,
            imageFile: imageFile,
            isActive: isActive,
            screenshotController: isActive ? screenshotController : null,
            onTap: () {
              if (!isActive) {
                onSyncBack();
                context.read<MultiScreenshotCubit>().setActiveIndex(index);
              }
            },
            onDelete: designCount > 1
                ? () {
                    context.read<MultiScreenshotCubit>().removeDesign(index);
                  }
                : null,
            onDuplicate: designCount < 10
                ? () {
                    onSyncBack();
                    context.read<MultiScreenshotCubit>().duplicateDesign(index);
                  }
                : null,
            onReplaceImage: () async {
              if (!isActive) {
                onSyncBack();
                context.read<MultiScreenshotCubit>().setActiveIndex(index);
              }
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
              );
              if (result != null && result.files.single.path != null) {
                if (!context.mounted) return;
                context.read<MultiScreenshotCubit>().updateImageForSlot(
                  index,
                  File(result.files.single.path!),
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    onSyncActiveDesign();
                  }
                });
              }
            },
            onMoveLeft: index > 0
                ? () {
                    onSyncBack();
                    context.read<MultiScreenshotCubit>().moveDesignLeft(index);
                  }
                : null,
            onMoveRight: index < designCount - 1
                ? () {
                    onSyncBack();
                    context.read<MultiScreenshotCubit>().moveDesignRight(index);
                  }
                : null,
            previewLocale: previewLocale,
            hasLocaleImage: hasLocaleImage,
            onReplaceLocaleImage: previewLocale != null
                ? () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null && result.files.single.path != null) {
                      if (!context.mounted) return;
                      context.read<TranslationCubit>().setLocaleImage(
                        previewLocale,
                        index,
                        result.files.single.path!,
                      );
                    }
                  }
                : null,
            onRevertLocaleImage: previewLocale != null
                ? () {
                    context.read<TranslationCubit>().removeLocaleImage(
                      previewLocale,
                      index,
                    );
                  }
                : null,
            onApplyFrameToAll: () {
              onSyncBack();
              context.read<MultiScreenshotCubit>().applyFrameSettingsToAll(
                index,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  onSyncActiveDesign();
                }
              });
            },
          ),
        );
      },
    );
  }
}

/// Hosts the trailing add-new placeholder; rebuilds only when the last
/// design changes (it mirrors that design's dimensions).
class _AddPlaceholderHost extends StatelessWidget {
  const _AddPlaceholderHost({required this.onSyncBack});

  final VoidCallback onSyncBack;

  @override
  Widget build(BuildContext context) {
    final lastDesign = context.select<MultiScreenshotCubit, ScreenshotDesign?>(
      (cubit) =>
          cubit.state.designs.isNotEmpty ? cubit.state.designs.last : null,
    );
    if (lastDesign == null) return const SizedBox.shrink();
    return AddScreenshotPlaceholder(
      design: lastDesign,
      onTap: () {
        onSyncBack();
        context.read<MultiScreenshotCubit>().addDesign();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export-in-progress overlay
// ─────────────────────────────────────────────────────────────────────────────

class _ExportOverlay extends StatelessWidget {
  const _ExportOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.exportingScreenshots,
                    style: theme.textTheme.bodyLarge,
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
