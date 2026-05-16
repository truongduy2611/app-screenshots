import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/grab_cursor_region.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/import_hint_placeholder.dart';
import 'package:device_frame/device_frame.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The device frame / background screenshot image — draggable to reposition.
///
/// Holds its own drag state so dragging the frame never emits to the cubit
/// mid-gesture (the cubit is committed once on pan end, a single undo entry),
/// and is wrapped in a [RepaintBoundary] so frame drags don't repaint the rest
/// of the canvas.
class DraggableFrameWidget extends StatefulWidget {
  const DraggableFrameWidget({
    super.key,
    required this.canvasSize,
    required this.onSnapHaptics,
  });

  final Size canvasSize;
  final void Function(Offset original, Offset snapped) onSnapHaptics;

  @override
  State<DraggableFrameWidget> createState() => _DraggableFrameWidgetState();
}

class _DraggableFrameWidgetState extends State<DraggableFrameWidget> {
  bool _isDragging = false;
  Offset _rawImagePosition = Offset.zero; // unsnapped accumulator
  Offset _dragImagePosition = Offset.zero; // snapped, rendered + committed

  ScreenshotEditorCubit get _cubit => context.read<ScreenshotEditorCubit>();

  Future<void> _pickImageForCanvas() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      _cubit.updateImageFile(File(result.files.single.path!));
    }
  }

  void _commitDrag() {
    if (!_isDragging) return;
    _cubit.updateImagePosition(_dragImagePosition);
    _cubit.clearSnapLines();
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
          buildWhen: (p, c) =>
              !identical(p.design, c.design) ||
              p.selectedImageFile?.path != c.selectedImageFile?.path ||
              p.selectedImageUrl != c.selectedImageUrl,
          builder: (context, state) {
            final hasImage = state.selectedImageFile != null ||
                state.selectedImageUrl != null;
            final imagePos = _isDragging
                ? _dragImagePosition
                : state.design.imagePosition;

            return GrabCursorRegion(
              child: GestureDetector(
                onTap: !hasImage
                    ? _pickImageForCanvas
                    : () => _cubit.deselectOverlay(),
                onPanStart: (_) {
                  _cubit.deselectOverlay();
                  _rawImagePosition = state.design.imagePosition;
                  _dragImagePosition = state.design.imagePosition;
                  setState(() => _isDragging = true);
                },
                onPanUpdate: (details) {
                  _rawImagePosition += details.delta;
                  final halfCanvas = Offset(
                    widget.canvasSize.width / 2,
                    widget.canvasSize.height / 2,
                  );
                  final frameCenter = halfCanvas + _rawImagePosition;
                  final snappedCenter = _cubit.snapOffset(
                    frameCenter,
                    widget.canvasSize,
                  );
                  widget.onSnapHaptics(frameCenter, snappedCenter);
                  setState(
                    () => _dragImagePosition = snappedCenter - halfCanvas,
                  );
                },
                onPanEnd: (_) => _commitDrag(),
                onPanCancel: _commitDrag,
                child: Padding(
                  padding: EdgeInsets.all(state.design.padding),
                  child: Center(
                    child: _buildFrameContent(context, state, imagePos),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrameContent(
    BuildContext context,
    ScreenshotEditorState state,
    Offset imagePos,
  ) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(state.design.frameRotationX)
      ..rotateY(state.design.frameRotationY)
      ..rotateZ(state.design.frameRotation);

    if (state.design.deviceFrame == null) {
      return Transform.translate(
        offset: imagePos,
        child: Transform(
          transform: transform,
          alignment: Alignment.center,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: widget.canvasSize.width,
                height: widget.canvasSize.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    state.design.cornerRadius,
                  ),
                  child: _buildImage(context, state, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Transform.translate(
      offset: imagePos,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: DeviceFrame(
              device: state.design.deviceFrame!,
              isFrameVisible: true,
              orientation: state.design.orientation,
              screen: _buildImage(context, state, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    ScreenshotEditorState state, {
    BoxFit fit = BoxFit.cover,
  }) {
    // Check for a per-locale image override via TranslationCubit.
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
