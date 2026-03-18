import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/canvas_painters.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas/grab_cursor_region.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/font_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Positioned text overlay with drag gesture, snap support, and
/// optional translation overrides.
///
/// When [previewLocale] is non‑null the overlay uses per-locale
/// overrides for position, scale, width, text, fontSize, and styling from
/// [tCubit]. Otherwise it renders the base overlay directly.
class TextOverlayWidget extends StatefulWidget {
  const TextOverlayWidget({
    super.key,
    required this.overlay,
    required this.canvasSize,
    required this.state,
    required this.previewLocale,
    required this.localeOverride,
    required this.tCubit,
    required this.onSnapHaptics,
    this.designIndex,
  });

  final TextOverlay overlay;
  final Size canvasSize;
  final ScreenshotEditorState state;
  final String? previewLocale;
  final OverlayOverride? localeOverride;
  final TranslationCubit? tCubit;
  final void Function(Offset original, Offset snapped) onSnapHaptics;

  /// Design slot index in multi-screenshot mode.
  /// When non-null, translation keys are scoped as `"$designIndex:$overlayId"`.
  final int? designIndex;

  @override
  State<TextOverlayWidget> createState() => _TextOverlayWidgetState();
}

class _TextOverlayWidgetState extends State<TextOverlayWidget> {
  final Map<String, Offset> _rawPositions = {};
  final Map<String, GlobalKey> _overlayKeys = {};

  // ── Inline editing state ──
  bool _isEditing = false;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();

  GlobalKey _keyFor(String id) =>
      _overlayKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    _editFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _editFocusNode.removeListener(_onFocusChanged);
    _editFocusNode.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TextOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the overlay gets deselected externally, commit any pending edit.
    final wasSelected =
        oldWidget.state.selectedOverlayId == oldWidget.overlay.id;
    final isSelected = widget.state.selectedOverlayId == widget.overlay.id;
    if (wasSelected && !isSelected && _isEditing) {
      _commitEdit();
    }
  }

  void _onFocusChanged() {
    if (!_editFocusNode.hasFocus && _isEditing) {
      _commitEdit();
    }
  }

  void _enterEditMode(String displayText) {
    _editController.text = displayText;
    setState(() => _isEditing = true);
    // Request focus after the frame so the TextField is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
      // Select all text for convenience.
      _editController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editController.text.length,
      );
    });
  }

  void _commitEdit() {
    if (!_isEditing) return;
    final newText = _editController.text;
    final overlay = widget.overlay;
    final previewLocale = widget.previewLocale;
    final tCubit = widget.tCubit;
    final translationKey = widget.designIndex != null
        ? '${widget.designIndex}:${overlay.id}'
        : overlay.id;

    if (previewLocale != null && tCubit != null) {
      // Update the translation for the previewed locale.
      tCubit.updateTranslation(previewLocale, translationKey, newText);
    } else {
      // Update the base overlay text.
      context.read<ScreenshotEditorCubit>().updateTextOverlay(
        overlay.id,
        overlay.copyWith(text: newText),
      );
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final previewLocale = widget.previewLocale;
    final localeOverride = widget.localeOverride;
    final tCubit = widget.tCubit;
    final isLocalePreview = previewLocale != null;
    final isSelected = widget.state.selectedOverlayId == overlay.id;

    // ── Layout overrides ──
    final effectivePos = localeOverride?.position ?? overlay.position;
    final effectiveScale = localeOverride?.scale ?? overlay.scale;
    final effectiveWidth = localeOverride?.width ?? overlay.width;
    final effectiveRotation =
        (isLocalePreview ? localeOverride?.rotation : null) ?? overlay.rotation;

    // ── Resolve displayed text ──
    // Use design-scoped key when in multi-screenshot mode.
    final translationKey = widget.designIndex != null
        ? '${widget.designIndex}:${overlay.id}'
        : overlay.id;

    String displayText = overlay.text;
    if (previewLocale != null && tCubit?.state.bundle != null) {
      displayText =
          tCubit!.state.bundle!.getTranslation(previewLocale, translationKey) ??
          overlay.text;
    }

    // ── Resolve styling overrides ──
    final effectiveFontWeight =
        (isLocalePreview ? localeOverride?.fontWeight : null) ??
        overlay.style.fontWeight;
    final effectiveFontStyle =
        (isLocalePreview ? localeOverride?.fontStyle : null) ??
        overlay.style.fontStyle;
    final effectiveColor =
        (isLocalePreview && localeOverride?.color != null
            ? Color(localeOverride!.color!)
            : null) ??
        overlay.style.color;
    final effectiveTextAlign =
        (isLocalePreview ? localeOverride?.textAlign : null) ??
        overlay.textAlign;
    final effectiveDecoration =
        (isLocalePreview ? localeOverride?.textDecoration : null) ??
        overlay.decoration;
    final effectiveDecorationStyle =
        (isLocalePreview ? localeOverride?.textDecorationStyle : null) ??
        overlay.decorationStyle;
    final effectiveDecorationColor =
        (isLocalePreview && localeOverride?.decorationColor != null
            ? Color(localeOverride!.decorationColor!)
            : null) ??
        overlay.decorationColor;
    final effectiveGoogleFont =
        (isLocalePreview ? localeOverride?.googleFont : null) ??
        overlay.googleFont;
    final effectiveBackgroundColor =
        (isLocalePreview && localeOverride?.backgroundColor != null
            ? Color(localeOverride!.backgroundColor!)
            : null) ??
        overlay.backgroundColor;
    final effectiveBorderColor =
        (isLocalePreview && localeOverride?.borderColor != null
            ? Color(localeOverride!.borderColor!)
            : null) ??
        overlay.borderColor;
    final effectiveBorderWidth =
        (isLocalePreview ? localeOverride?.borderWidth : null) ??
        overlay.borderWidth;
    final effectiveBorderRadius =
        (isLocalePreview ? localeOverride?.borderRadius : null) ??
        overlay.borderRadius;
    final effectiveHPad =
        (isLocalePreview ? localeOverride?.horizontalPadding : null) ??
        overlay.horizontalPadding;
    final effectiveVPad =
        (isLocalePreview ? localeOverride?.verticalPadding : null) ??
        overlay.verticalPadding;

    // ── Resolve fontSize override ──
    final effectiveFontSize =
        (isLocalePreview ? localeOverride?.fontSize : null) ??
        overlay.style.fontSize;

    // ── Resolve font (with non‑Latin fallback) ──
    var textStyle = overlay.style.copyWith(
      fontSize: effectiveFontSize,
      fontWeight: effectiveFontWeight,
      fontStyle: effectiveFontStyle,
      color: effectiveColor,
      decoration: effectiveDecoration,
      decorationStyle: effectiveDecorationStyle,
      decorationColor: effectiveDecorationColor,
    );
    final baseStyle = GoogleFonts.getFont(
      effectiveGoogleFont ?? 'Roboto',
      textStyle: textStyle,
    );
    final resolvedStyle = previewLocale != null
        ? FontFallback.resolve(baseStyle, previewLocale)
        : baseStyle;

    // ── Build the text content (Text vs TextField) ──
    final editColor = resolvedStyle.color ?? Colors.white;
    final textContent = _isEditing
        ? IntrinsicWidth(
            child: TextField(
              controller: _editController,
              focusNode: _editFocusNode,
              style: resolvedStyle.copyWith(color: editColor),
              cursorColor: editColor,
              textAlign: effectiveTextAlign,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              enableInteractiveSelection: true,
              cursorWidth: 4,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: editColor.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: editColor.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: editColor, width: 2),
                ),
              ),
            ),
          )
        : Text(
            displayText,
            textAlign: effectiveTextAlign,
            style: resolvedStyle,
          );

    return Positioned(
      left: effectivePos.dx,
      top: effectivePos.dy,
      child: GrabCursorRegion(
        child: GestureDetector(
          onPanStart: (_) {
            // If editing, commit first before starting drag.
            if (_isEditing) _commitEdit();
            _rawPositions[overlay.id] = effectivePos;
          },
          onPanUpdate: (details) {
            final rawPos =
                (_rawPositions[overlay.id] ?? effectivePos) + details.delta;
            _rawPositions[overlay.id] = rawPos;
            final cubit = context.read<ScreenshotEditorCubit>();

            // Measure actual rendered size via GlobalKey.
            Size? elSize;
            final key = _overlayKeys[overlay.id];
            if (key?.currentContext != null) {
              final box = key!.currentContext!.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                elSize = box.size * effectiveScale;
              }
            }

            final snappedPosition = cubit.snapOffset(
              rawPos,
              widget.canvasSize,
              elementSize: elSize,
            );
            widget.onSnapHaptics(rawPos, snappedPosition);

            // Route to override or base depending on whether a preview
            // locale is active.
            if (previewLocale != null && tCubit != null) {
              tCubit.updateOverlayOverride(
                previewLocale,
                translationKey,
                (localeOverride ?? const OverlayOverride()).copyWith(
                  position: snappedPosition,
                ),
              );
            } else {
              cubit.updateTextOverlay(
                overlay.id,
                overlay.copyWith(position: snappedPosition),
              );
            }
          },
          onPanEnd: (_) {
            _rawPositions.remove(overlay.id);
            context.read<ScreenshotEditorCubit>().clearSnapLines();
          },
          onPanCancel: () {
            _rawPositions.remove(overlay.id);
            context.read<ScreenshotEditorCubit>().clearSnapLines();
          },
          onTap: () {
            if (!isSelected) {
              context.read<ScreenshotEditorCubit>().selectOverlay(overlay.id);
            }
          },
          onDoubleTap: () {
            // Select if not already, then enter edit mode.
            if (!isSelected) {
              context.read<ScreenshotEditorCubit>().selectOverlay(overlay.id);
            }
            _enterEditMode(displayText);
          },
          child: OverlaySelectionBorder(
            key: _keyFor(overlay.id),
            isSelected: isSelected,
            child: Transform.rotate(
              angle: effectiveRotation,
              child: Transform.scale(
                scale: effectiveScale,
                child: SizedBox(
                  width: effectiveWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveBackgroundColor,
                      border:
                          effectiveBorderColor != null &&
                              effectiveBorderWidth > 0
                          ? Border.all(
                              color: effectiveBorderColor,
                              width: effectiveBorderWidth,
                            )
                          : null,
                      borderRadius: effectiveBorderRadius > 0
                          ? BorderRadius.circular(effectiveBorderRadius)
                          : null,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: effectiveHPad,
                      vertical: effectiveVPad,
                    ),
                    child: textContent,
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
