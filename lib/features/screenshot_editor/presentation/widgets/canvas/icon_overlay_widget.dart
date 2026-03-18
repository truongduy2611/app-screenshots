import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Positioned icon overlay with drag, rotate, and resize gestures.
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
  Offset? _rawPosition;
  double _startRotation = 0.0;
  double _startScale = 1.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;

    return Positioned(
      key: ValueKey(overlay.id),
      left: overlay.position.dx,
      top: overlay.position.dy,
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: GestureDetector(
          onScaleStart: (details) {
            setState(() => _isDragging = true);
            _rawPosition = overlay.position;
            _startRotation = overlay.rotation;
            _startScale = overlay.scale;
            context.read<ScreenshotEditorCubit>().selectOverlay(overlay.id);
          },
          onScaleUpdate: (details) {
            _rawPosition =
                (_rawPosition ?? overlay.position) + details.focalPointDelta;

            final cubit = context.read<ScreenshotEditorCubit>();
            final canvasSize = ScreenshotUtils.getDimensions(
              cubit.state.design.displayType ?? '',
              cubit.state.design.orientation,
            );
            // Icon element size for center-based snap
            final iconDim =
                (overlay.size + overlay.padding * 2) * overlay.scale;
            final snappedPos = cubit.snapOffset(
              _rawPosition!,
              canvasSize,
              elementSize: Size(iconDim, iconDim),
            );
            widget.onSnapHaptics(_rawPosition!, snappedPos);

            final newScale = _startScale * details.scale;
            final newRotation = _startRotation + details.rotation;

            cubit.updateIconOverlay(
              overlay.id,
              overlay.copyWith(
                position: snappedPos,
                scale: newScale,
                rotation: newRotation,
              ),
            );
          },
          onScaleEnd: (_) {
            setState(() => _isDragging = false);
            _rawPosition = null;
            context.read<ScreenshotEditorCubit>().clearSnapLines();
          },
          onTap: () =>
              context.read<ScreenshotEditorCubit>().selectOverlay(overlay.id),
          child: Opacity(
            opacity: overlay.opacity.clamp(0.0, 1.0),
            child: OverlaySelectionBorder(
              isSelected: widget.isSelected,
              child: Transform.rotate(
                angle: overlay.rotation,
                child: Transform.scale(
                  scale: overlay.scale,
                  child: Container(
                    padding: EdgeInsets.all(overlay.padding),
                    decoration: BoxDecoration(
                      color: overlay.backgroundColor,
                      borderRadius: overlay.borderRadius > 0
                          ? BorderRadius.circular(overlay.borderRadius)
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
