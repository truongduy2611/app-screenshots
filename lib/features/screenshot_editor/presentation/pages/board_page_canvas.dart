part of 'board_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Canvas area — viewport, dot grid, drag-and-drop import
// ─────────────────────────────────────────────────────────────────────────────

class _BoardCanvasArea extends StatelessWidget {
  const _BoardCanvasArea({
    required this.screenshotController,
    required this.viewportController,
    required this.isExporting,
  });

  final ScreenshotController screenshotController;
  final CanvasViewportController viewportController;

  /// Suppresses selection chrome while a capture is in flight.
  final bool isExporting;

  /// Slack around the board inside the viewport, so the crop zone labels
  /// (which sit above each zone) have somewhere to render. Zoom helpers offset
  /// board rects by this to stay in sync.
  static const double canvasPadding = 200;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0);

    return DropTarget(
      onDragDone: (details) async {
        if (details.files.isEmpty) return;
        final files = details.files.map((f) => File(f.path)).toList();
        await context.read<BoardCubit>().importImages(files);
      },
      child: BlocSelector<ScreenshotEditorCubit, ScreenshotEditorState, bool>(
        selector: (state) => state.design.gridSettings.showDotGrid,
        builder: (context, showDots) {
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
                controller: viewportController,
                child: BlocSelector<BoardCubit, BoardState, bool>(
                  selector: (state) => state.showCropZones,
                  builder: (context, showCropZones) {
                    return Padding(
                      padding: const EdgeInsets.all(canvasPadding),
                      child: RepaintBoundary(
                        child: BoardCanvas(
                          screenshotController: screenshotController,
                          showCropZones: showCropZones,
                          interactive: !isExporting,
                        ),
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
// Export-in-progress overlay
// ─────────────────────────────────────────────────────────────────────────────

class _BoardExportOverlay extends StatelessWidget {
  const _BoardExportOverlay();

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
                    context.l10n.exportingBoard,
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
