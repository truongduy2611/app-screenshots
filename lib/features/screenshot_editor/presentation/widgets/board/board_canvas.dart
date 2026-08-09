import 'dart:ui' as ui;

import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/frame_element.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_frame_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/crop_zone_layer.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/icon_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/image_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/magnifier_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/text_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/doodle_background.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/grid_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:screenshot/screenshot.dart';

/// The board editing surface: one large canvas holding every frame, overlay,
/// and crop zone.
///
/// Layering, bottom to top:
///
/// 1. background fill / gradient, then mesh, doodle, grid
/// 2. overlays flagged `behindFrame`, z-sorted
/// 3. frame elements, z-sorted
/// 4. remaining overlays, z-sorted
/// 5. magnifier lenses
/// 6. crop zone outlines — **outside** the capture boundary
///
/// Steps 1–5 sit inside [Screenshot], so a capture yields exactly the board's
/// pixels. Step 6 cannot reach the export no matter what is toggled, which is
/// what makes zone visibility a free editor-only switch.
///
/// The board's background and overlays come from [ScreenshotEditorCubit] — the
/// same [ScreenshotDesign] the single-artboard editor uses — so every existing
/// control panel drives a board without modification. Only the frame list and
/// the zones come from [BoardCubit].
class BoardCanvas extends StatefulWidget {
  const BoardCanvas({
    super.key,
    required this.screenshotController,
    this.showCropZones = true,
    this.interactive = true,
  });

  final ScreenshotController screenshotController;

  /// Whether zone outlines are drawn. Never affects captured pixels.
  final bool showCropZones;

  /// When false, selection chrome is suppressed — used while capturing.
  final bool interactive;

  /// Corner radius of the board card, in board pixels.
  ///
  /// Editor chrome only. It is applied *outside* the capture boundary, so the
  /// rounding never reaches an exported image — App Store screenshots must be
  /// full-bleed rectangles, and crop zones sit well inside the board margin
  /// anyway. Board pixels are screenshot-resolution, so this needs to be large
  /// to read as a subtle radius on screen.
  static const double cornerRadius = 96.0;

  @override
  State<BoardCanvas> createState() => _BoardCanvasState();
}

class _BoardCanvasState extends State<BoardCanvas> {
  // Canvas snapshot feeding the magnifier lenses. Held in a ValueNotifier so a
  // new capture repaints only the lenses rather than rebuilding the board
  // (a setState here would re-trigger capture scheduling and loop).
  final GlobalKey _captureKey = GlobalKey();
  final ValueNotifier<ui.Image?> _canvasSnapshot = ValueNotifier(null);
  bool _captureScheduled = false;
  ScreenshotDesign? _capturedDesign;
  List<FrameElement>? _capturedFrames;

  @override
  void dispose() {
    _canvasSnapshot.value?.dispose();
    _canvasSnapshot.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Magnifier snapshot
  // ---------------------------------------------------------------------------

  void _maybeScheduleCapture(ScreenshotDesign design, BoardDesign board) {
    if (design.magnifierOverlays.isEmpty) return;
    if (identical(_capturedDesign, design) &&
        identical(_capturedFrames, board.frames)) {
      return;
    }
    if (_captureScheduled) return;
    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      _captureCanvas(design, board);
    });
  }

  Future<void> _captureCanvas(ScreenshotDesign design, BoardDesign board) async {
    if (!mounted) return;
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || !boundary.attached) return;
      final image = await boundary.toImage(pixelRatio: 1.0);
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _canvasSnapshot.value;
      _canvasSnapshot.value = image;
      old?.dispose();
      _capturedDesign = design;
      _capturedFrames = board.frames;
    } catch (_) {
      // Ignore capture errors (e.g. mid-layout).
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardCubit, BoardState>(
      // Deliberately ignores `board.background`: the page syncs it into the
      // board on every overlay/background edit, and the inner builder already
      // rebuilds from the editor cubit for those. Reacting here too would
      // rebuild the whole board twice per keystroke.
      buildWhen: (prev, curr) =>
          !identical(prev.board.frames, curr.board.frames) ||
          !identical(prev.board.cropZones, curr.board.cropZones) ||
          prev.board.size != curr.board.size ||
          prev.selectedFrameId != curr.selectedFrameId ||
          prev.selectedZoneId != curr.selectedZoneId,
      builder: (context, boardState) {
        final board = boardState.board;

        return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
          buildWhen: (prev, curr) =>
              !identical(prev.design, curr.design) ||
              prev.selectedOverlayId != curr.selectedOverlayId,
          builder: (context, editorState) {
            final design = editorState.design;
            _maybeScheduleCapture(design, board);

            final radius = BorderRadius.circular(BoardCanvas.cornerRadius);

            return SizedBox(
              width: board.size.width,
              height: board.size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Card shadow, lifting the board off the dot grid.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: BoardCanvas.cornerRadius,
                              spreadRadius: BoardCanvas.cornerRadius / 8,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Only the board's own pixels are rounded. The crop zone
                  // layer below stays outside this clip so zone labels, which
                  // sit above the board's top edge, are not cut off.
                  ClipRRect(
                    borderRadius: radius,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (design.transparentBackground)
                          Positioned.fill(
                            child: CustomPaint(painter: CheckerboardPainter()),
                          ),
                        Screenshot(
                          controller: widget.screenshotController,
                          child: RepaintBoundary(
                            key: _captureKey,
                            child: Container(
                              width: board.size.width,
                              height: board.size.height,
                              decoration: BoxDecoration(
                                color: design.transparentBackground
                                    ? Colors.transparent
                                    : design.backgroundColor,
                                gradient: design.transparentBackground
                                    ? null
                                    : design.backgroundGradient,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ..._buildBackgroundLayers(design, board.size),
                                  ..._buildContentLayers(
                                    context,
                                    editorState,
                                    boardState,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hairline ring so the rounded edge stays crisp against the
                  // canvas at any zoom.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Magnifier lenses render above the captured boundary so
                  // their own pixels are never fed back into the lens source.
                  ..._buildMagnifiers(editorState, board.size),
                  if (widget.showCropZones)
                    Positioned.fill(
                      child: CropZoneLayer(
                        zones: board.cropZones,
                        selectedZoneId: boardState.selectedZoneId,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------

  // The cubit allocates a fresh ScreenshotDesign on every edit even when the
  // mesh settings are untouched, so re-mapping points/options each build would
  // defeat MeshGradientPainter's identity-based shouldRepaint and re-run the
  // shader on every keystroke. Cache on the settings object's identity.
  Widget? _cachedMeshWidget;
  MeshGradientSettings? _cachedMeshSettings;

  Widget? _buildMeshLayer(MeshGradientSettings? settings) {
    if (settings == null) {
      _cachedMeshWidget = null;
      _cachedMeshSettings = null;
      return null;
    }
    if (_cachedMeshWidget != null && identical(_cachedMeshSettings, settings)) {
      return _cachedMeshWidget;
    }
    final widget = Positioned.fill(
      child: MeshGradient(
        points: settings.points
            .map((p) => MeshGradientPoint(position: p.position, color: p.color))
            .toList(),
        options: MeshGradientOptions(
          blend: settings.blend,
          noiseIntensity: settings.noiseIntensity,
        ),
      ),
    );
    _cachedMeshWidget = widget;
    _cachedMeshSettings = settings;
    return widget;
  }

  List<Widget> _buildBackgroundLayers(ScreenshotDesign design, Size boardSize) {
    final mesh = _buildMeshLayer(design.meshGradient);
    return [
      ?mesh,
      if (design.doodleSettings != null)
        DoodleBackground(
          settings: design.doodleSettings!,
          canvasSize: boardSize,
        ),
      GridOverlay(settings: design.gridSettings, canvasSize: boardSize),
    ];
  }

  // ---------------------------------------------------------------------------
  // Frames + overlays
  // ---------------------------------------------------------------------------

  List<Widget> _buildContentLayers(
    BuildContext context,
    ScreenshotEditorState editorState,
    BoardState boardState,
  ) {
    final design = editorState.design;
    final board = boardState.board;
    final boardSize = board.size;

    final behind = <({Widget widget, int zIndex})>[];
    final inFront = <({Widget widget, int zIndex})>[];

    void add(Widget widget, int zIndex, bool isBehind) {
      (isBehind ? behind : inFront).add((widget: widget, zIndex: zIndex));
    }

    for (final overlay in design.imageOverlays) {
      add(
        ImageOverlayWidget(
          key: ValueKey(overlay.id),
          overlay: overlay,
          isSelected: editorState.selectedOverlayId == overlay.id,
        ),
        overlay.zIndex,
        overlay.behindFrame,
      );
    }

    for (final overlay in design.overlays) {
      add(
        _buildTextOverlay(context, overlay, editorState, boardSize),
        overlay.zIndex,
        overlay.behindFrame,
      );
    }

    for (final overlay in design.iconOverlays) {
      add(
        IconOverlayWidget(
          key: ValueKey(overlay.id),
          overlay: overlay,
          isSelected: editorState.selectedOverlayId == overlay.id,
          canvasSize: boardSize,
          onSnapHaptics: (_, _) {},
        ),
        overlay.zIndex,
        overlay.behindFrame,
      );
    }

    behind.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    inFront.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final frames = List<FrameElement>.from(board.frames)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return [
      ...behind.map((e) => e.widget),
      for (final frame in frames)
        BoardFrameWidget(
          key: ValueKey(frame.id),
          frame: frame,
          isSelected: boardState.selectedFrameId == frame.id,
          showChrome: widget.interactive,
        ),
      ...inFront.map((e) => e.widget),
    ];
  }

  /// Text overlays are locale-aware, so they subscribe to [TranslationCubit]
  /// individually rather than rebuilding the whole board on a locale change.
  /// Board overlay ids are global (no slot prefix), so `designIndex` is null.
  Widget _buildTextOverlay(
    BuildContext context,
    TextOverlay overlay,
    ScreenshotEditorState editorState,
    Size boardSize,
  ) {
    TranslationCubit? translationCubit;
    try {
      translationCubit = context.read<TranslationCubit>();
    } catch (_) {}

    if (translationCubit == null) {
      return TextOverlayWidget(
        key: ValueKey(overlay.id),
        overlay: overlay,
        canvasSize: boardSize,
        state: editorState,
        previewLocale: null,
        localeOverride: null,
        tCubit: null,
        onSnapHaptics: (_, _) {},
      );
    }

    return BlocBuilder<TranslationCubit, TranslationState>(
      key: ValueKey(overlay.id),
      builder: (ctx, tState) {
        final previewLocale = tState.previewLocale;
        return TextOverlayWidget(
          overlay: overlay,
          canvasSize: boardSize,
          state: editorState,
          previewLocale: previewLocale,
          localeOverride: previewLocale != null
              ? tState.bundle?.getOverride(previewLocale, overlay.id)
              : null,
          tCubit: ctx.read<TranslationCubit>(),
          onSnapHaptics: (_, _) {},
        );
      },
    );
  }

  List<Widget> _buildMagnifiers(ScreenshotEditorState state, Size boardSize) {
    return state.design.magnifierOverlays.map((overlay) {
      return Positioned(
        key: ValueKey(overlay.id),
        left: overlay.position.dx,
        top: overlay.position.dy,
        child: MagnifierOverlayWidget(
          overlay: overlay,
          isSelected: state.selectedOverlayId == overlay.id,
          canvasSnapshot: _canvasSnapshot,
          canvasSize: boardSize,
        ),
      );
    }).toList();
  }
}
