import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/overlay_interaction_box.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Positioned icon overlay with drag, rotate, and scale gestures.
///
/// During a gesture the transform is kept in local state and the cubit is
/// committed only once on gesture end — so a drag never emits per frame and
/// produces a single undo entry.
class IconOverlayWidget extends StatefulWidget {
  const IconOverlayWidget({
    super.key,
    required this.overlay,
    required this.isSelected,
    required this.canvasSize,
    required this.onSnapHaptics,
  });

  final IconOverlay overlay;
  final bool isSelected;
  final Size canvasSize;
  final void Function(Offset original, Offset snapped) onSnapHaptics;

  @override
  State<IconOverlayWidget> createState() => _IconOverlayWidgetState();
}

class _IconOverlayWidgetState extends State<IconOverlayWidget> {
  bool _isDragging = false;

  double _startRotation = 0.0;
  double _startScale = 1.0;
  Offset _rawPosition = Offset.zero;
  Offset _dragPosition = Offset.zero;
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
    _cubit.updateIconOverlay(
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
    final overlay = widget.overlay;

    final position = _isDragging ? _dragPosition : overlay.position;
    final scale = _isDragging ? _dragScale : overlay.scale;
    final rotation = _isDragging ? _dragRotation : overlay.rotation;

    // Intrinsic (unscaled) icon box: glyph + padding on each side.
    final dim = overlay.size + overlay.padding * 2;
    final contentSize = Size(dim, dim);

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
                : SystemMouseCursors.grab,
            child: Opacity(
              opacity: overlay.opacity.clamp(0.0, 1.0),
              child: OverlaySelectionBorder(
                isSelected: widget.isSelected,
                child: OverlayInteractionBox(
                  contentSize: contentSize,
                  scale: scale,
                  rotation: rotation,
                  gestureChild: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (_) => _beginDrag(),
                    onScaleUpdate: (details) {
                      _rawPosition += details.focalPointDelta;
                      _dragScale = _startScale * details.scale;
                      _dragRotation = _startRotation + details.rotation;

                      final canvasSize = ScreenshotUtils.getDimensions(
                        _cubit.state.design.displayType ?? '',
                        _cubit.state.design.orientation,
                      );
                      final snappedPos = _cubit.snapOffset(
                        _rawPosition,
                        canvasSize,
                        elementSize: contentSize,
                      );
                      widget.onSnapHaptics(_rawPosition, snappedPos);
                      setState(() => _dragPosition = snappedPos);
                    },
                    onScaleEnd: (_) => _endDrag(),
                    onTap: () => _cubit.selectOverlay(overlay.id),
                  ),
                  content: _buildIconContent(overlay),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContent(IconOverlay overlay) {
    return Container(
      padding: EdgeInsets.all(overlay.padding),
      decoration: BoxDecoration(
        color: overlay.backgroundColor,
        borderRadius: overlay.borderRadius > 0
            ? BorderRadius.circular(overlay.borderRadius)
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
      child: Text(
        String.fromCharCode(overlay.codePoint),
        style: TextStyle(
          fontFamily: overlay.fontFamily,
          package: overlay.fontPackage,
          fontSize: overlay.size,
          color: overlay.color,
          fontVariations: overlay.isSFSymbol
              ? null
              : [FontVariation('wght', overlay.fontWeight)],
        ),
      ),
    );
  }
}
