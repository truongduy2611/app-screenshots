import 'dart:io';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Positioned image overlay with drag, rotate, and resize gestures.
class ImageOverlayWidget extends StatefulWidget {
  final ImageOverlay overlay;
  final bool isSelected;
  final Function(Offset, Offset)? onPanUpdate;

  const ImageOverlayWidget({
    super.key,
    required this.overlay,
    required this.isSelected,
    this.onPanUpdate,
  });

  @override
  State<ImageOverlayWidget> createState() => _ImageOverlayWidgetState();
}

class _ImageOverlayWidgetState extends State<ImageOverlayWidget> {
  double _startRotation = 0.0;
  double _startScale = 1.0;
  bool _isDragging = false;
  Offset? _rawPosition;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    final overlay = widget.overlay;

    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.move,
      child: GestureDetector(
        onScaleStart: (details) {
          setState(() => _isDragging = true);
          _startRotation = overlay.rotation;
          _startScale = overlay.scale;
          _rawPosition = overlay.position;
          context.read<ScreenshotEditorCubit>().selectOverlay(overlay.id);
        },
        onScaleEnd: (_) {
          setState(() => _isDragging = false);
          _rawPosition = null;
          context.read<ScreenshotEditorCubit>().clearSnapLines();
        },
        onScaleUpdate: (details) {
          _rawPosition =
              (_rawPosition ?? overlay.position) + details.focalPointDelta;

          final cubit = context.read<ScreenshotEditorCubit>();
          final canvasSize = ScreenshotUtils.getDimensions(
            cubit.state.design.displayType ?? '',
            cubit.state.design.orientation,
          );
          // Image overlay size for center-based snap
          final elSize = Size(
            overlay.width * overlay.scale,
            overlay.height * overlay.scale,
          );
          final snappedPos = cubit.snapOffset(
            _rawPosition!,
            canvasSize,
            elementSize: elSize,
          );

          widget.onPanUpdate?.call(_rawPosition!, snappedPos);

          final newScale = _startScale * details.scale;
          final newRotation = _startRotation + details.rotation;

          cubit.updateImageOverlay(
            overlay.id,
            overlay.copyWith(
              position: snappedPos,
              scale: newScale,
              rotation: newRotation,
            ),
          );
        },
        child: Opacity(
          opacity: overlay.opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: overlay.rotation,
            child: Transform.scale(
              scale: overlay.scale,
              child: Transform.flip(
                flipX: overlay.flipHorizontal,
                flipY: overlay.flipVertical,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: overlay.width,
                      height: overlay.height,
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                        borderRadius: overlay.cornerRadius > 0
                            ? BorderRadius.circular(overlay.cornerRadius)
                            : null,
                        boxShadow:
                            overlay.shadowColor != null &&
                                overlay.shadowBlurRadius > 0
                            ? [
                                BoxShadow(
                                  color: overlay.shadowColor!,
                                  blurRadius: overlay.shadowBlurRadius,
                                  offset: overlay.shadowOffset,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          overlay.cornerRadius,
                        ),
                        child: overlay.filePath != null
                            ? Image.file(
                                File(overlay.filePath!),
                                fit: overlay.cornerRadius > 0
                                    ? BoxFit.cover
                                    : BoxFit.contain,
                              )
                            : overlay.bytes != null
                            ? Image.memory(
                                overlay.bytes!,
                                fit: overlay.cornerRadius > 0
                                    ? BoxFit.cover
                                    : BoxFit.contain,
                              )
                            : const Placeholder(),
                      ),
                    ),
                    if (widget.isSelected && isDesktop) ...[
                      _buildResizeHandle(Alignment.topLeft),
                      _buildResizeHandle(Alignment.topRight),
                      _buildResizeHandle(Alignment.bottomLeft),
                      _buildResizeHandle(Alignment.bottomRight),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle(Alignment alignment) {
    MouseCursor cursor;
    if (alignment == Alignment.topLeft || alignment == Alignment.bottomRight) {
      cursor = SystemMouseCursors.resizeUpLeftDownRight;
    } else {
      cursor = SystemMouseCursors.resizeUpRightDownLeft;
    }

    return Positioned(
      top: alignment.y == -1 ? -10 : null,
      bottom: alignment.y == 1 ? -10 : null,
      left: alignment.x == -1 ? -10 : null,
      right: alignment.x == 1 ? -10 : null,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanUpdate: (details) {
            _handleResize(details, alignment);
          },
          child: Transform.scale(
            scale: 1 / widget.overlay.scale,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleResize(DragUpdateDetails details, Alignment alignment) {
    final dx = details.delta.dx;
    final dy = details.delta.dy;

    final horizontalGrowth = dx * alignment.x;
    final verticalGrowth = dy * alignment.y;
    final growth = (horizontalGrowth + verticalGrowth) / 2;

    final baseWidth = widget.overlay.width;
    if (baseWidth == 0) return;

    final scaleChange = 1 + (growth / baseWidth);
    var newScale = widget.overlay.scale * scaleChange;

    if (newScale < 0.1) newScale = 0.1;
    if (newScale > 5.0) newScale = 5.0;

    context.read<ScreenshotEditorCubit>().updateImageOverlay(
      widget.overlay.id,
      widget.overlay.copyWith(scale: newScale),
    );
  }
}
