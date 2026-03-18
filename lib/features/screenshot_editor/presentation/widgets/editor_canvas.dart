import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:flutter/rendering.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/grab_cursor_region.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/icon_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/image_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/import_hint_placeholder.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/magnifier_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/text_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/grid_overlay.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/doodle_background.dart';
import 'package:device_frame/device_frame.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:screenshot/screenshot.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({super.key, required this.screenshotController});
  final ScreenshotController screenshotController;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  bool _isSnapped = false;
  Offset? _rawImagePosition;

  // Canvas capture for magnifier
  final GlobalKey _canvasBoundaryKey = GlobalKey();
  ui.Image? _canvasSnapshot;
  bool _captureScheduled = false;

  @override
  void dispose() {
    _canvasSnapshot?.dispose();
    super.dispose();
  }

  void _scheduleCaptureCanvas() {
    if (_captureScheduled) return;
    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      _captureCanvas();
    });
  }

  Future<void> _captureCanvas() async {
    try {
      final boundary =
          _canvasBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || !boundary.attached) return;
      final image = await boundary.toImage(pixelRatio: 1.0);
      if (mounted) {
        setState(() {
          _canvasSnapshot?.dispose();
          _canvasSnapshot = image;
        });
      } else {
        image.dispose();
      }
    } catch (_) {
      // Ignore capture errors (e.g. during layout)
    }
  }

  void _handleSnapHaptics(Offset original, Offset snapped) {
    final snappedX = (original.dx - snapped.dx).abs() > 0;
    final snappedY = (original.dy - snapped.dy).abs() > 0;
    final nowSnapped = snappedX || snappedY;

    if (nowSnapped && !_isSnapped) {
      HapticFeedback.lightImpact();
    }
    _isSnapped = nowSnapped;
  }

  Future<void> _pickImageForCanvas(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      context.read<ScreenshotEditorCubit>().updateImageFile(
        File(result.files.single.path!),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      builder: (context, state) {
        final canvasSize = ScreenshotUtils.getDimensions(
          state.design.displayType ?? '',
          state.design.orientation,
        );
        final cornerRadius = canvasSize.shortestSide * 0.08;

        return Material(
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: FittedBox(
            fit: BoxFit.contain,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Stack(
                  children: [
                    if (state.design.transparentBackground)
                      Positioned.fill(
                        child: CustomPaint(painter: CheckerboardPainter()),
                      ),
                    Screenshot(
                      controller: widget.screenshotController,
                      child: SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: Builder(
                          builder: (context) {
                            // Schedule canvas capture for magnifier after this frame
                            if (state.design.magnifierOverlays.isNotEmpty) {
                              _scheduleCaptureCanvas();
                            }
                            return Stack(
                              children: [
                                // RepaintBoundary wraps everything except magnifiers
                                // (including background) so we can capture it for the magnifier lens
                                RepaintBoundary(
                                  key: _canvasBoundaryKey,
                                  child: Container(
                                    width: canvasSize.width,
                                    height: canvasSize.height,
                                    decoration: _buildBackgroundDecoration(
                                      state,
                                    ),
                                    child: Stack(
                                      children: [
                                        ..._buildBackgroundLayers(
                                          state,
                                          canvasSize,
                                        ),
                                        ...(() {
                                          final overlays = _buildSortedOverlays(
                                            context,
                                            state,
                                            canvasSize,
                                          );
                                          return [
                                            ...overlays.behind,
                                            _buildDraggableFrame(
                                              context,
                                              state,
                                              canvasSize,
                                            ),
                                            ...overlays.inFront,
                                          ];
                                        })(),
                                        _buildSnapGuides(state, canvasSize),
                                      ],
                                    ),
                                  ),
                                ),
                                // Magnifiers always render on top of everything
                                ..._buildMagnifierOverlays(state, canvasSize),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Background
  // ─────────────────────────────────────────────────────────────────

  BoxDecoration _buildBackgroundDecoration(ScreenshotEditorState state) {
    return BoxDecoration(
      color: state.design.transparentBackground
          ? Colors.transparent
          : state.design.backgroundColor,
      gradient: state.design.transparentBackground
          ? null
          : state.design.backgroundGradient,
    );
  }

  List<Widget> _buildBackgroundLayers(
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    return [
      if (state.design.meshGradient != null)
        Positioned.fill(
          child: MeshGradient(
            points: state.design.meshGradient!.points
                .map(
                  (p) =>
                      MeshGradientPoint(position: p.position, color: p.color),
                )
                .toList(),
            options: MeshGradientOptions(
              blend: state.design.meshGradient!.blend,
              noiseIntensity: state.design.meshGradient!.noiseIntensity,
            ),
          ),
        ),
      if (state.design.doodleSettings != null)
        DoodleBackground(
          settings: state.design.doodleSettings!,
          canvasSize: canvasSize,
        ),
      GridOverlay(settings: state.design.gridSettings, canvasSize: canvasSize),
    ];
  }

  // ─────────────────────────────────────────────────────────────────
  // Draggable frame (background image + frame drag gestures)
  // ─────────────────────────────────────────────────────────────────

  Widget _buildDraggableFrame(
    BuildContext context,
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    return Positioned.fill(
      child: GrabCursorRegion(
        child: GestureDetector(
          onTap:
              state.selectedImageFile == null && state.selectedImageUrl == null
              ? () => _pickImageForCanvas(context)
              : () {
                  AppLogger.d(
                    'FrameTap: Deselecting overlay. Was: ${state.selectedOverlayId}',
                    tag: 'Canvas',
                  );
                  context.read<ScreenshotEditorCubit>().deselectOverlay();
                },
          onPanStart: (_) {
            AppLogger.d(
              'FrameDrag: PanStart — selectedOverlayId: ${state.selectedOverlayId}',
              tag: 'Canvas',
            );
            context.read<ScreenshotEditorCubit>().deselectOverlay();
            _rawImagePosition = state.design.imagePosition;
          },
          onPanUpdate: (details) {
            _rawImagePosition =
                (_rawImagePosition ?? state.design.imagePosition) +
                details.delta;
            final cubit = context.read<ScreenshotEditorCubit>();
            final halfCanvas = Offset(
              canvasSize.width / 2,
              canvasSize.height / 2,
            );
            final frameCenter = halfCanvas + _rawImagePosition!;
            final snappedCenter = cubit.snapOffset(frameCenter, canvasSize);
            final snappedPos = snappedCenter - halfCanvas;
            _handleSnapHaptics(frameCenter, snappedCenter);
            cubit.updateImagePosition(snappedPos);
          },
          onPanEnd: (_) {
            _rawImagePosition = null;
            context.read<ScreenshotEditorCubit>().clearSnapLines();
          },
          onPanCancel: () {
            _rawImagePosition = null;
            context.read<ScreenshotEditorCubit>().clearSnapLines();
          },
          child: Padding(
            padding: EdgeInsets.all(state.design.padding),
            child: Center(
              child: _buildFrameContent(context, state, canvasSize),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Overlay lists
  // ─────────────────────────────────────────────────────────────────

  ({List<Widget> behind, List<Widget> inFront}) _buildSortedOverlays(
    BuildContext context,
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    final imageOverlays = _buildImageOverlays(state);
    final textOverlays = _buildTextOverlays(context, state, canvasSize);
    final iconOverlays = _buildIconOverlays(state, canvasSize);

    final List<_ZIndexedWidget> zWidgets = [];

    for (int i = 0; i < state.design.imageOverlays.length; i++) {
      zWidgets.add(
        _ZIndexedWidget(
          imageOverlays[i],
          state.design.imageOverlays[i].zIndex,
          state.design.imageOverlays[i].behindFrame,
        ),
      );
    }
    for (int i = 0; i < state.design.overlays.length; i++) {
      zWidgets.add(
        _ZIndexedWidget(
          textOverlays[i],
          state.design.overlays[i].zIndex,
          state.design.overlays[i].behindFrame,
        ),
      );
    }
    for (int i = 0; i < state.design.iconOverlays.length; i++) {
      zWidgets.add(
        _ZIndexedWidget(
          iconOverlays[i],
          state.design.iconOverlays[i].zIndex,
          state.design.iconOverlays[i].behindFrame,
        ),
      );
    }

    zWidgets.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final behind = zWidgets
        .where((z) => z.behindFrame)
        .map((z) => z.widget)
        .toList();
    final inFront = zWidgets
        .where((z) => !z.behindFrame)
        .map((z) => z.widget)
        .toList();

    return (behind: behind, inFront: inFront);
  }

  List<Widget> _buildImageOverlays(ScreenshotEditorState state) {
    return state.design.imageOverlays.map((overlay) {
      return Positioned(
        key: ValueKey(overlay.id),
        left: overlay.position.dx,
        top: overlay.position.dy,
        child: ImageOverlayWidget(
          overlay: overlay,
          isSelected: state.selectedOverlayId == overlay.id,
          onPanUpdate: (raw, snapped) => _handleSnapHaptics(raw, snapped),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTextOverlays(
    BuildContext context,
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    TranslationCubit? translationCubit;
    try {
      translationCubit = context.read<TranslationCubit>();
    } catch (_) {}
    final hasTranslationCubit = translationCubit != null;

    // Resolve design index for scoped translation keys.
    int? designIndex;
    try {
      final multiState = context.read<MultiScreenshotCubit>().state;
      designIndex = multiState.activeIndex;
    } catch (_) {}

    return state.design.overlays.map((overlay) {
      if (!hasTranslationCubit) {
        return TextOverlayWidget(
          overlay: overlay,
          canvasSize: canvasSize,
          state: state,
          previewLocale: null,
          localeOverride: null,
          tCubit: null,
          onSnapHaptics: _handleSnapHaptics,
          designIndex: designIndex,
        );
      }

      return BlocBuilder<TranslationCubit, TranslationState>(
        builder: (ctx, tState) {
          final tCubit = ctx.read<TranslationCubit>();
          final pvLocale = tState.previewLocale;

          // Use scoped key for override lookup.
          final overrideKey = designIndex != null
              ? '$designIndex:${overlay.id}'
              : overlay.id;
          final localeOverride = pvLocale != null
              ? tState.bundle?.getOverride(pvLocale, overrideKey)
              : null;

          return TextOverlayWidget(
            overlay: overlay,
            canvasSize: canvasSize,
            state: state,
            previewLocale: pvLocale,
            localeOverride: localeOverride,
            tCubit: tCubit,
            onSnapHaptics: _handleSnapHaptics,
            designIndex: designIndex,
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildIconOverlays(
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    return state.design.iconOverlays.map((overlay) {
      return IconOverlayWidget(
        overlay: overlay,
        isSelected: state.selectedOverlayId == overlay.id,
        canvasSize: canvasSize,
        onSnapHaptics: _handleSnapHaptics,
      );
    }).toList();
  }

  List<Widget> _buildMagnifierOverlays(
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    return state.design.magnifierOverlays.map((overlay) {
      return Positioned(
        key: ValueKey(overlay.id),
        left: overlay.position.dx,
        top: overlay.position.dy,
        child: MagnifierOverlayWidget(
          overlay: overlay,
          isSelected: state.selectedOverlayId == overlay.id,
          canvasSnapshot: _canvasSnapshot,
          canvasSize: canvasSize,
        ),
      );
    }).toList();
  }

  Widget _buildSnapGuides(ScreenshotEditorState state, Size canvasSize) {
    if (state.activeSnapX == null && state.activeSnapY == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: canvasSize,
        painter: SnapGuidePainter(
          activeSnapX: state.activeSnapX,
          activeSnapY: state.activeSnapY,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Frame content & image
  // ─────────────────────────────────────────────────────────────────

  Widget _buildFrameContent(
    BuildContext context,
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    if (state.design.deviceFrame == null) {
      return Transform.translate(
        offset: state.design.imagePosition,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateX(state.design.frameRotationX)
            ..rotateY(state.design.frameRotationY)
            ..rotateZ(state.design.frameRotation),
          alignment: Alignment.center,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    state.design.cornerRadius,
                  ),
                  child: _buildImage(state, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Transform.translate(
      offset: state.design.imagePosition,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(state.design.frameRotationX)
          ..rotateY(state.design.frameRotationY)
          ..rotateZ(state.design.frameRotation),
        alignment: Alignment.center,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: DeviceFrame(
              device: state.design.deviceFrame!,
              isFrameVisible: true,
              orientation: state.design.orientation,
              screen: _buildImage(state, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ScreenshotEditorState state, {BoxFit fit = BoxFit.cover}) {
    // Check for per-locale image override via TranslationCubit.
    TranslationCubit? tCubit;
    try {
      tCubit = context.read<TranslationCubit>();
    } catch (_) {}
    
    if (tCubit != null) {
      final localeImagePath = tCubit.currentLocaleImagePath;
      if (localeImagePath != null) {
        final localeFile = File(localeImagePath);
        if (localeFile.existsSync()) {
          return Image.file(
            localeFile,
            fit: fit,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Symbols.error_rounded)),
          );
        }
      }
    }

    if (state.selectedImageFile != null) {
      return Image.file(
        state.selectedImageFile!,
        fit: fit,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Symbols.error_rounded)),
      );
    }
    if (state.selectedImageUrl != null) {
      return Image.network(
        state.selectedImageUrl!,
        fit: fit,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Symbols.error_rounded)),
        loadingBuilder: (_, child, loading) {
          if (loading == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return const ImportHintPlaceholder();
  }
}

class _ZIndexedWidget {
  final Widget widget;
  final int zIndex;
  final bool behindFrame;

  _ZIndexedWidget(this.widget, this.zIndex, this.behindFrame);
}
