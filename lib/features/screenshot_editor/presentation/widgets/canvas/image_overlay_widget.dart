import 'dart:io';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/overlay_interaction_box.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Positioned image overlay with drag, rotate, and resize gestures.
///
/// During a gesture the transform is kept in local state and the cubit is
/// committed only once on gesture end — so a drag never emits per frame and
/// produces a single undo entry. The widget owns its [Positioned] so its own
/// `setState` can move it without rebuilding the whole canvas.
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
  bool _isDragging = false;

  // Live gesture state — authoritative only while [_isDragging].
  double _startRotation = 0.0;
  double _startScale = 1.0;
  Offset _rawPosition = Offset.zero; // unsnapped accumulator
  Offset _dragPosition = Offset.zero; // snapped, rendered + committed
  double _dragScale = 1.0;
  double _dragRotation = 0.0;

  ScreenshotEditorCubit get _cubit => context.read<ScreenshotEditorCubit>();

  void _beginDrag() {
    final o = widget.overlay;
    _rawPosition = o.position;
    _dragPosition = o.position;
    _dragScale = o.scale;
    _dragRotation = o.rotation;
    _startScale = o.scale;
    _startRotation = o.rotation;
    setState(() => _isDragging = true);
    _cubit.selectOverlay(o.id);
  }

  void _endDrag() {
    if (!_isDragging) return;
    final o = widget.overlay;
    _cubit.updateImageOverlay(
      o.id,
      o.copyWith(
        position: _dragPosition,
        scale: _dragScale,
        rotation: _dragRotation,
      ),
    );
    _cubit.clearSnapLines();
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    final overlay = widget.overlay;

    // Effective transform — local while dragging, model otherwise.
    final position = _isDragging ? _dragPosition : overlay.position;
    final scale = _isDragging ? _dragScale : overlay.scale;
    final rotation = _isDragging ? _dragRotation : overlay.rotation;
    final contentSize = Size(overlay.width, overlay.height);

    final aabbOffset = OverlayInteractionBox.aabbOffset(
      contentSize,
      scale,
      rotation,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: RepaintBoundary(
        child: Transform.translate(
          offset: aabbOffset,
          child: MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.move,
            child: Opacity(
              opacity: overlay.opacity.clamp(0.0, 1.0),
              child: OverlaySelectionBorder(
                isSelected: widget.isSelected,
                child: OverlayInteractionBox(
                  contentSize: contentSize,
                  scale: scale,
                  rotation: rotation,
                  flipX: overlay.flipHorizontal,
                  flipY: overlay.flipVertical,
                  gestureChild: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _cubit.selectOverlay(overlay.id),
                    onScaleStart: (_) => _beginDrag(),
                    onScaleEnd: (_) => _endDrag(),
                    onScaleUpdate: (details) {
                      _rawPosition += details.focalPointDelta;
                      _dragScale = _startScale * details.scale;
                      _dragRotation = _startRotation + details.rotation;

                      final canvasSize = ScreenshotUtils.getDimensions(
                        _cubit.state.design.displayType ?? '',
                        _cubit.state.design.orientation,
                      );
                      // Snap on the unscaled size — `position` and the visual
                      // center relate through unscaled dimensions because
                      // scaling is center-aligned.
                      final snappedPos = _cubit.snapOffset(
                        _rawPosition,
                        canvasSize,
                        elementSize: contentSize,
                      );
                      widget.onPanUpdate?.call(_rawPosition, snappedPos);
                      setState(() => _dragPosition = snappedPos);
                    },
                  ),
                  content: _buildImageContent(overlay),
                  overlayChildren: [
                    if (widget.isSelected && isDesktop)
                      _buildResizeHandles(overlay, scale, rotation),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(ImageOverlay overlay) {
    return Container(
      width: overlay.width,
      height: overlay.height,
      decoration: BoxDecoration(
        borderRadius: overlay.cornerRadius > 0
            ? BorderRadius.circular(overlay.cornerRadius)
            : null,
        boxShadow:
            overlay.shadowColor != null && overlay.shadowBlurRadius > 0
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
        borderRadius: BorderRadius.circular(overlay.cornerRadius),
        child: overlay.filePath != null
            ? Image.file(File(overlay.filePath!), fit: overlay.fit)
            : overlay.bytes != null
            ? Image.memory(overlay.bytes!, fit: overlay.fit)
            : const Placeholder(),
      ),
    );
  }

  /// Builds the 4 corner resize handles, rotated to track the rotated image.
  Widget _buildResizeHandles(
    ImageOverlay overlay,
    double scale,
    double rotation,
  ) {
    const handleSize = 20.0;
    final aabb = OverlayInteractionBox.aabbSize(
      Size(overlay.width, overlay.height),
      scale,
      rotation,
    );
    // Visible (scaled, pre-rotation) image rect, centered within the AABB.
    final ws = overlay.width * scale;
    final hs = overlay.height * scale;
    final vx = (aabb.width - ws) / 2;
    final vy = (aabb.height - hs) / 2;
    // Handles sit just inside each corner so they stay fully within the
    // bounding box and remain fully hit-testable.
    final right = vx + ws - handleSize;
    final bottom = vy + hs - handleSize;

    return Positioned.fill(
      child: Transform.rotate(
        angle: rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildResizeHandle(Alignment.topLeft, Offset(vx, vy)),
            _buildResizeHandle(Alignment.topRight, Offset(right, vy)),
            _buildResizeHandle(Alignment.bottomLeft, Offset(vx, bottom)),
            _buildResizeHandle(Alignment.bottomRight, Offset(right, bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle(Alignment alignment, Offset topLeft) {
    MouseCursor cursor;
    if (alignment == Alignment.topLeft || alignment == Alignment.bottomRight) {
      cursor = SystemMouseCursors.resizeUpLeftDownRight;
    } else {
      cursor = SystemMouseCursors.resizeUpRightDownLeft;
    }

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (_) => _beginDrag(),
          onPanUpdate: (details) => _handleResize(details, alignment),
          onPanEnd: (_) => _endDrag(),
          onPanCancel: _endDrag,
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
    var newScale = _dragScale * scaleChange;

    if (newScale < 0.1) newScale = 0.1;
    if (newScale > 50.0) newScale = 50.0;

    setState(() => _dragScale = newScale);
  }
}
