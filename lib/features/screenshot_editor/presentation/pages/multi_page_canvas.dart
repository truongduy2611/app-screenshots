part of 'multi_screenshot_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Canvas area with interactive viewer, dot grid, and drag-drop
// ─────────────────────────────────────────────────────────────────────────────

class _MultiCanvasArea extends StatefulWidget {
  final ScreenshotController screenshotController;
  final TransformationController transformController;
  final VoidCallback onSyncBack;
  final VoidCallback onSyncActiveDesign;
  final VoidCallback onZoomToFit;

  const _MultiCanvasArea({
    required this.screenshotController,
    required this.transformController,
    required this.onSyncBack,
    required this.onSyncActiveDesign,
    required this.onZoomToFit,
  });

  @override
  State<_MultiCanvasArea> createState() => _MultiCanvasAreaState();
}

class _MultiCanvasAreaState extends State<_MultiCanvasArea> {
  bool _isPanning = false;

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
              MouseRegion(
                cursor: _isPanning
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: Listener(
                  onPointerDown: (_) => setState(() => _isPanning = true),
                  onPointerUp: (_) => setState(() => _isPanning = false),
                  onPointerCancel: (_) => setState(() => _isPanning = false),
                  child: InteractiveViewer(
                    transformationController: widget.transformController,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.05,
                    maxScale: 4.0,
                    child:
                        BlocBuilder<MultiScreenshotCubit, MultiScreenshotState>(
                          builder: (context, multiState) {
                            return Padding(
                              padding: const EdgeInsets.all(100),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    int i = 0;
                                    i < multiState.designs.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const SizedBox(width: _gap),
                                    CanvasSlot(
                                      index: i,
                                      design: multiState.designs[i],
                                      imageFile: multiState.imageFiles[i],
                                      isActive: i == multiState.activeIndex,
                                      screenshotController:
                                          i == multiState.activeIndex
                                          ? widget.screenshotController
                                          : null,
                                      onTap: () {
                                        if (i != multiState.activeIndex) {
                                          widget.onSyncBack();
                                          context
                                              .read<MultiScreenshotCubit>()
                                              .setActiveIndex(i);
                                        }
                                      },
                                      onDelete: multiState.designs.length > 1
                                          ? () {
                                              context
                                                  .read<MultiScreenshotCubit>()
                                                  .removeDesign(i);
                                            }
                                          : null,
                                      onDuplicate: multiState.canAddMore
                                          ? () {
                                              widget.onSyncBack();
                                              context
                                                  .read<MultiScreenshotCubit>()
                                                  .duplicateDesign(i);
                                            }
                                          : null,
                                      onReplaceImage: () async {
                                        if (i != multiState.activeIndex) {
                                          widget.onSyncBack();
                                          context
                                              .read<MultiScreenshotCubit>()
                                              .setActiveIndex(i);
                                        }
                                        final result = await FilePicker.platform
                                            .pickFiles(type: FileType.image);
                                        if (result != null &&
                                            result.files.single.path != null) {
                                          if (!context.mounted) return;
                                          context
                                              .read<MultiScreenshotCubit>()
                                              .updateImageForSlot(
                                                i,
                                                File(result.files.single.path!),
                                              );
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (context.mounted) {
                                                  widget.onSyncActiveDesign();
                                                }
                                              });
                                        }
                                      },
                                      onMoveLeft: i > 0
                                          ? () {
                                              widget.onSyncBack();
                                              context
                                                  .read<MultiScreenshotCubit>()
                                                  .moveDesignLeft(i);
                                            }
                                          : null,
                                      onMoveRight:
                                          i < multiState.designs.length - 1
                                          ? () {
                                              widget.onSyncBack();
                                              context
                                                  .read<MultiScreenshotCubit>()
                                                  .moveDesignRight(i);
                                            }
                                          : null,
                                    ),
                                  ],
                                  // ── Add-new placeholder ──
                                  if (multiState.canAddMore) ...[
                                    const SizedBox(width: _gap),
                                    AddScreenshotPlaceholder(
                                      design: multiState.designs.last,
                                      onTap: () {
                                        widget.onSyncBack();
                                        context
                                            .read<MultiScreenshotCubit>()
                                            .addDesign();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                  ),
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
