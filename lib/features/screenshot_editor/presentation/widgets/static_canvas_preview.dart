import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/magnifier_overlay_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/doodle_background.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/grid_overlay.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/font_fallback.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

/// Read-only preview of a screenshot canvas.
///
/// Used for inactive frames in the multi-screenshot editor. Renders the
/// background, device frame (if any), text overlays, and image overlays —
/// matching [EditorCanvas] but without interactive editing features.
class StaticCanvasPreview extends StatelessWidget {
  const StaticCanvasPreview({
    super.key,
    required this.design,
    this.imageFile,
    this.borderRadius = 20,
    this.designIndex,
  });

  final ScreenshotDesign design;
  final File? imageFile;
  final double borderRadius;

  /// Design slot index in multi-screenshot mode.
  /// When non-null, translation keys are scoped as `"$designIndex:$overlayId"`.
  final int? designIndex;

  @override
  Widget build(BuildContext context) {
    final canvasSize = ScreenshotUtils.getDimensions(
      design.displayType ?? '',
      design.orientation,
    );

    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            children: [
              if (design.transparentBackground)
                Positioned.fill(
                  child: CustomPaint(painter: _CheckerboardPainter()),
                ),
              Container(
                width: canvasSize.width,
                height: canvasSize.height,
                decoration: BoxDecoration(
                  color: design.transparentBackground
                      ? Colors.transparent
                      : design.backgroundColor,
                  gradient: design.transparentBackground
                      ? null
                      : design.backgroundGradient,
                ),
                child: Stack(
                  children: [
                    // ── Mesh gradient / doodle / grid layers ──
                    if (design.meshGradient != null)
                      Positioned.fill(
                        child: MeshGradient(
                          points: design.meshGradient!.points
                              .map(
                                (p) => MeshGradientPoint(
                                  position: p.position,
                                  color: p.color,
                                ),
                              )
                              .toList(),
                          options: MeshGradientOptions(
                            blend: design.meshGradient!.blend,
                            noiseIntensity: design.meshGradient!.noiseIntensity,
                          ),
                        ),
                      ),
                    if (design.doodleSettings != null)
                      DoodleBackground(
                        settings: design.doodleSettings!,
                        canvasSize: canvasSize,
                      ),
                    GridOverlay(
                      settings: design.gridSettings,
                      canvasSize: canvasSize,
                    ),
                    // ── Sorted overlays + frame (split by behindFrame) ──
                    ...(() {
                      // Build the frame widget
                      final frameWidget = Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(design.padding),
                          child: Center(
                            child: Transform.translate(
                              offset: design.imagePosition,
                              child: Transform.rotate(
                                angle: design.frameRotation,
                                child: design.deviceFrame != null
                                    ? SizedBox.expand(
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: DeviceFrame(
                                            device: design.deviceFrame!,
                                            isFrameVisible: true,
                                            orientation: design.orientation,
                                            screen: imageFile != null
                                                ? Image.file(
                                                    imageFile!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: const Color(
                                                      0xFF1C1C1E,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      )
                                    : SizedBox.expand(
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: SizedBox(
                                            width: canvasSize.width,
                                            height: canvasSize.height,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    design.cornerRadius,
                                                  ),
                                              child: imageFile != null
                                                  ? Image.file(
                                                      imageFile!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: const Color(
                                                        0xFF1C1C1E,
                                                      ),
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

                      final allOverlays =
                          <({Widget widget, int zIndex, bool behindFrame})>[];

                      // Text overlays
                      for (final overlay in design.overlays) {
                        TranslationCubit? translationCubit;
                        try {
                          translationCubit = context.watch<TranslationCubit>();
                        } catch (_) {}

                        final previewLocale =
                            translationCubit?.state.previewLocale;
                        final translationKey = designIndex != null
                            ? '$designIndex:${overlay.id}'
                            : overlay.id;
                        final localeOverride = previewLocale != null
                            ? translationCubit?.state.bundle?.getOverride(
                                previewLocale,
                                translationKey,
                              )
                            : null;
                        final effectivePos =
                            localeOverride?.position ?? overlay.position;
                        final effectiveScale =
                            localeOverride?.scale ?? overlay.scale;
                        final effectiveWidth =
                            localeOverride?.width ?? overlay.width;

                        String displayText = overlay.text;
                        if (previewLocale != null &&
                            translationCubit?.state.bundle != null) {
                          displayText =
                              translationCubit!.state.bundle!.getTranslation(
                                previewLocale,
                                translationKey,
                              ) ??
                              overlay.text;
                        }

                        var textStyle = overlay.style;
                        if (localeOverride?.fontSize != null) {
                          textStyle = textStyle.copyWith(
                            fontSize: localeOverride!.fontSize,
                          );
                        }

                        final baseStyle = GoogleFonts.getFont(
                          overlay.googleFont ?? 'Roboto',
                          textStyle: textStyle,
                        );
                        final resolvedStyle = previewLocale != null
                            ? FontFallback.resolve(baseStyle, previewLocale)
                            : baseStyle;

                        allOverlays.add((
                          widget: Positioned(
                            left: effectivePos.dx,
                            top: effectivePos.dy,
                            child: Transform.rotate(
                              angle: overlay.rotation,
                              child: Transform.scale(
                                scale: effectiveScale,
                                child: SizedBox(
                                  width: effectiveWidth,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: overlay.backgroundColor,
                                      border:
                                          overlay.borderColor != null &&
                                              overlay.borderWidth > 0
                                          ? Border.all(
                                              color: overlay.borderColor!,
                                              width: overlay.borderWidth,
                                            )
                                          : null,
                                      borderRadius: overlay.borderRadius > 0
                                          ? BorderRadius.circular(
                                              overlay.borderRadius,
                                            )
                                          : null,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: overlay.horizontalPadding,
                                      vertical: overlay.verticalPadding,
                                    ),
                                    child: Text(
                                      displayText,
                                      textAlign: overlay.textAlign,
                                      style: resolvedStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          zIndex: overlay.zIndex,
                          behindFrame: overlay.behindFrame,
                        ));
                      }

                      // Image overlays
                      for (final overlay in design.imageOverlays) {
                        allOverlays.add((
                          widget: Positioned(
                            left: overlay.position.dx,
                            top: overlay.position.dy,
                            child: Opacity(
                              opacity: overlay.opacity.clamp(0.0, 1.0),
                              child: Transform.rotate(
                                angle: overlay.rotation,
                                child: Transform.scale(
                                  scale: overlay.scale,
                                  child: Transform.flip(
                                    flipX: overlay.flipHorizontal,
                                    flipY: overlay.flipVertical,
                                    child: Container(
                                      width: overlay.width,
                                      height: overlay.height,
                                      decoration: BoxDecoration(
                                        borderRadius: overlay.cornerRadius > 0
                                            ? BorderRadius.circular(
                                                overlay.cornerRadius,
                                              )
                                            : null,
                                        boxShadow:
                                            overlay.shadowColor != null &&
                                                overlay.shadowBlurRadius > 0
                                            ? [
                                                BoxShadow(
                                                  color: overlay.shadowColor!,
                                                  blurRadius:
                                                      overlay.shadowBlurRadius,
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
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          zIndex: overlay.zIndex,
                          behindFrame: overlay.behindFrame,
                        ));
                      }

                      // Icon overlays
                      for (final overlay in design.iconOverlays) {
                        allOverlays.add((
                          widget: Positioned(
                            left: overlay.position.dx,
                            top: overlay.position.dy,
                            child: Opacity(
                              opacity: overlay.opacity.clamp(0.0, 1.0),
                              child: Transform.rotate(
                                angle: overlay.rotation,
                                child: Transform.scale(
                                  scale: overlay.scale,
                                  child: Container(
                                    padding: EdgeInsets.all(overlay.padding),
                                    decoration: BoxDecoration(
                                      color: overlay.backgroundColor,
                                      borderRadius: overlay.borderRadius > 0
                                          ? BorderRadius.circular(
                                              overlay.borderRadius,
                                            )
                                          : null,
                                      boxShadow:
                                          overlay.shadowColor != null &&
                                              overlay.shadowBlurRadius > 0
                                          ? [
                                              BoxShadow(
                                                color: overlay.shadowColor!,
                                                blurRadius:
                                                    overlay.shadowBlurRadius,
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
                                            : [
                                                FontVariation(
                                                  'wght',
                                                  overlay.fontWeight,
                                                ),
                                              ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          zIndex: overlay.zIndex,
                          behindFrame: overlay.behindFrame,
                        ));
                      }
                      allOverlays.sort((a, b) => a.zIndex.compareTo(b.zIndex));
                      final behind = allOverlays
                          .where((o) => o.behindFrame)
                          .map((o) => o.widget)
                          .toList();
                      final inFront = allOverlays
                          .where((o) => !o.behindFrame)
                          .map((o) => o.widget)
                          .toList();

                      // Build magnifier widgets (always on top)
                      final magnifierWidgets = design.magnifierOverlays.map((
                        overlay,
                      ) {
                        final w = overlay.width;
                        final h = overlay.height;
                        final zoom = overlay.zoomLevel;
                        final srcCenterX =
                            overlay.position.dx +
                            w / 2 +
                            overlay.sourceOffset.dx;
                        final srcCenterY =
                            overlay.position.dy +
                            h / 2 +
                            overlay.sourceOffset.dy;
                        final imgW = canvasSize.width * zoom;
                        final imgH = canvasSize.height * zoom;
                        final tx = w / 2 - srcCenterX * zoom;
                        final ty = h / 2 - srcCenterY * zoom;

                        Widget lensContent;
                        if (imageFile != null && imageFile!.existsSync()) {
                          lensContent = SizedBox(
                            width: w,
                            height: h,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  left: tx,
                                  top: ty,
                                  width: imgW,
                                  height: imgH,
                                  child: Image.file(
                                    imageFile!,
                                    width: imgW,
                                    height: imgH,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          lensContent = Container(
                            color: Colors.grey.withValues(alpha: 0.3),
                          );
                        }

                        // Use shared clipper for all shapes
                        final clipper = MagnifierShapeClipper(
                          overlay.shape,
                          cornerRadius: overlay.cornerRadius,
                          starPoints: overlay.starPoints,
                        );

                        final shadowPad =
                            overlay.shadowBlurRadius + overlay.borderWidth;

                        return Positioned(
                          left: overlay.position.dx,
                          top: overlay.position.dy,
                          child: Opacity(
                            opacity: overlay.opacity.clamp(0.0, 1.0),
                            child: Padding(
                              padding: EdgeInsets.all(shadowPad),
                              child: Transform.translate(
                                offset: Offset(-shadowPad, -shadowPad),
                                child: CustomPaint(
                                  painter: MagnifierBorderPainter(
                                    clipper: clipper,
                                    borderColor: overlay.borderColor,
                                    borderWidth: overlay.borderWidth,
                                    shadowColor: overlay.shadowColor,
                                    shadowBlurRadius: overlay.shadowBlurRadius,
                                  ),
                                  child: SizedBox(
                                    width: w,
                                    height: h,
                                    child: ClipPath(
                                      clipper: clipper,
                                      child: lensContent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      return [
                        ...behind,
                        frameWidget,
                        ...inFront,
                        ...magnifierWidgets,
                      ];
                    })(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a checkerboard pattern to indicate transparency.
class _CheckerboardPainter extends CustomPainter {
  static const _cellSize = 20.0;
  static const _lightColor = Color(0xFFFFFFFF);
  static const _darkColor = Color(0xFFCCCCCC);

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = _lightColor;
    final darkPaint = Paint()..color = _darkColor;

    canvas.drawRect(Offset.zero & size, lightPaint);

    final cols = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if ((row + col).isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * _cellSize,
              row * _cellSize,
              _cellSize,
              _cellSize,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
