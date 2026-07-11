import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/draggable_frame_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/icon_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/image_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/magnifier_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/snap_lines.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/text_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/grid_overlay.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/doodle_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Canvas capture for magnifier. The snapshot lives in a ValueNotifier so
  // updating it repaints only the magnifier lenses instead of rebuilding the
  // whole canvas (a setState here would re-trigger capture scheduling in
  // build, looping full-canvas toImage readbacks every frame).
  final GlobalKey _canvasBoundaryKey = GlobalKey();
  final ValueNotifier<ui.Image?> _canvasSnapshot = ValueNotifier<ui.Image?>(
    null,
  );
  bool _captureScheduled = false;

  // Signature of the content in the current snapshot. Captures are skipped
  // while lens-relevant content is unchanged (e.g. while a magnifier itself
  // is dragged or an overlay is merely selected/deselected... except the
  // selection border is part of the captured pixels, so selection is
  // included in the signature).
  ScreenshotDesign? _capturedDesign;
  String? _capturedSelectedOverlayId;
  String? _capturedImagePath;
  String? _capturedImageUrl;

  @override
  void dispose() {
    _canvasSnapshot.value?.dispose();
    _canvasSnapshot.dispose();
    super.dispose();
  }

  /// Whether anything rendered inside the capture boundary differs from what
  /// the current snapshot shows. Magnifier overlays themselves render outside
  /// the boundary and are deliberately excluded, so dragging a lens never
  /// triggers a capture. List/object fields use identity: the cubit always
  /// allocates new instances when content changes.
  bool _lensContentChanged(ScreenshotEditorState state) {
    final last = _capturedDesign;
    if (last == null) return true;
    final d = state.design;
    return !identical(last.overlays, d.overlays) ||
        !identical(last.imageOverlays, d.imageOverlays) ||
        !identical(last.iconOverlays, d.iconOverlays) ||
        !identical(last.meshGradient, d.meshGradient) ||
        !identical(last.doodleSettings, d.doodleSettings) ||
        !identical(last.gridSettings, d.gridSettings) ||
        !identical(last.deviceFrame, d.deviceFrame) ||
        last.backgroundColor != d.backgroundColor ||
        last.backgroundGradient != d.backgroundGradient ||
        last.padding != d.padding ||
        last.imagePosition != d.imagePosition ||
        last.frameRotationX != d.frameRotationX ||
        last.frameRotationY != d.frameRotationY ||
        last.frameRotation != d.frameRotation ||
        last.cornerRadius != d.cornerRadius ||
        last.orientation != d.orientation ||
        last.displayType != d.displayType ||
        last.transparentBackground != d.transparentBackground ||
        _capturedSelectedOverlayId != state.selectedOverlayId ||
        _capturedImagePath != state.selectedImageFile?.path ||
        _capturedImageUrl != state.selectedImageUrl;
  }

  void _maybeScheduleCapture(ScreenshotEditorState state) {
    if (state.design.magnifierOverlays.isEmpty) return;
    if (!_lensContentChanged(state)) return;
    if (_captureScheduled) return;
    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      _captureCanvas();
    });
  }

  Future<void> _captureCanvas() async {
    if (!mounted) return;
    final state = context.read<ScreenshotEditorCubit>().state;
    try {
      // If the screenshot image changed, wait for it to decode and paint so
      // the snapshot doesn't capture a half-loaded frame.
      final file = state.selectedImageFile;
      final url = state.selectedImageUrl;
      if (file != null && file.path != _capturedImagePath) {
        await precacheImage(FileImage(file), context);
        await WidgetsBinding.instance.endOfFrame;
      } else if (url != null && url != _capturedImageUrl) {
        await precacheImage(NetworkImage(url), context);
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;
      final boundary =
          _canvasBoundaryKey.currentContext?.findRenderObject()
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
      _capturedDesign = state.design;
      _capturedSelectedOverlayId = state.selectedOverlayId;
      _capturedImagePath = state.selectedImageFile?.path;
      _capturedImageUrl = state.selectedImageUrl;
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

  // ─────────────────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      // Skip rebuilds for changes that don't affect the canvas (undo/redo
      // button state, saved-design metadata).
      buildWhen: (prev, curr) =>
          !identical(prev.design, curr.design) ||
          prev.selectedOverlayId != curr.selectedOverlayId ||
          prev.selectedImageUrl != curr.selectedImageUrl ||
          prev.selectedImageFile?.path != curr.selectedImageFile?.path,
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
                            // Schedule canvas capture for magnifier after this
                            // frame, only if lens-relevant content changed.
                            _maybeScheduleCapture(state);
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
                                            DraggableFrameWidget(
                                              canvasSize: canvasSize,
                                              onSnapHaptics: _handleSnapHaptics,
                                            ),
                                            ...overlays.inFront,
                                          ];
                                        })(),
                                        _buildSnapGuides(context, canvasSize),
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

  // The cubit always allocates a new ScreenshotDesign on every edit, even
  // when meshGradient itself is untouched — so re-mapping its points/options
  // into fresh lists on every build defeats MeshGradientPainter's
  // identity-based shouldRepaint and forces a full shader repaint per
  // keystroke/slider tick. Cache the built widget keyed on the settings
  // object's identity so unrelated edits reuse the same instance.
  Widget? _cachedMeshWidget;
  MeshGradientSettings? _cachedMeshSettings;

  Widget? _buildMeshGradientLayer(MeshGradientSettings? settings) {
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

  List<Widget> _buildBackgroundLayers(
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    final meshLayer = _buildMeshGradientLayer(state.design.meshGradient);
    return [
      ?meshLayer,
      if (state.design.doodleSettings != null)
        DoodleBackground(
          settings: state.design.doodleSettings!,
          canvasSize: canvasSize,
        ),
      GridOverlay(settings: state.design.gridSettings, canvasSize: canvasSize),
    ];
  }

  // ─────────────────────────────────────────────────────────────────
  // Overlay lists
  // ─────────────────────────────────────────────────────────────────

  // Cached result of the last sort, keyed on the inputs that actually affect
  // it. TextOverlayWidget/ImageOverlayWidget/IconOverlayWidget only read
  // overlay data + selection state (verified), so any other design edit
  // (background, padding, frame rotation...) can safely reuse this list
  // instead of re-mapping + re-sorting every overlay on every build.
  ({List<Widget> behind, List<Widget> inFront})? _cachedSortedOverlays;
  List<TextOverlay>? _cachedTextOverlaySource;
  List<ImageOverlay>? _cachedImageOverlaySource;
  List<IconOverlay>? _cachedIconOverlaySource;
  String? _cachedOverlaySelectedId;
  Size? _cachedOverlayCanvasSize;

  ({List<Widget> behind, List<Widget> inFront}) _buildSortedOverlays(
    BuildContext context,
    ScreenshotEditorState state,
    Size canvasSize,
  ) {
    final cached = _cachedSortedOverlays;
    if (cached != null &&
        identical(_cachedTextOverlaySource, state.design.overlays) &&
        identical(_cachedImageOverlaySource, state.design.imageOverlays) &&
        identical(_cachedIconOverlaySource, state.design.iconOverlays) &&
        _cachedOverlaySelectedId == state.selectedOverlayId &&
        _cachedOverlayCanvasSize == canvasSize) {
      return cached;
    }

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

    final result = (behind: behind, inFront: inFront);
    _cachedSortedOverlays = result;
    _cachedTextOverlaySource = state.design.overlays;
    _cachedImageOverlaySource = state.design.imageOverlays;
    _cachedIconOverlaySource = state.design.iconOverlays;
    _cachedOverlaySelectedId = state.selectedOverlayId;
    _cachedOverlayCanvasSize = canvasSize;
    return result;
  }

  List<Widget> _buildImageOverlays(ScreenshotEditorState state) {
    return state.design.imageOverlays.map((overlay) {
      return ImageOverlayWidget(
        key: ValueKey(overlay.id),
        overlay: overlay,
        isSelected: state.selectedOverlayId == overlay.id,
        onPanUpdate: (raw, snapped) => _handleSnapHaptics(raw, snapped),
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
          key: ValueKey(overlay.id),
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
        key: ValueKey(overlay.id),
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
        key: ValueKey(overlay.id),
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

  Widget _buildSnapGuides(BuildContext context, Size canvasSize) {
    final cubit = context.read<ScreenshotEditorCubit>();
    return IgnorePointer(
      child: ValueListenableBuilder<SnapLines>(
        valueListenable: cubit.snapLines,
        builder: (context, lines, _) {
          if (lines.isEmpty) return const SizedBox.shrink();
          return CustomPaint(
            size: canvasSize,
            painter: SnapGuidePainter(
              activeSnapX: lines.x,
              activeSnapY: lines.y,
            ),
          );
        },
      ),
    );
  }

}

class _ZIndexedWidget {
  final Widget widget;
  final int zIndex;
  final bool behindFrame;

  _ZIndexedWidget(this.widget, this.zIndex, this.behindFrame);
}
