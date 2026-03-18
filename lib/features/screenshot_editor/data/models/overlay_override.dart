import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Per-locale layout & style override for a single text overlay.
///
/// Only non-null fields are applied on top of the base [TextOverlay].
/// This allows users to adjust position/size/styling for specific locales
/// (e.g. when German text is longer than English, or a locale needs a
/// different font) without modifying the base design.
class OverlayOverride extends Equatable {
  // ── Layout overrides ──
  /// Override position (dx, dy) on the canvas.
  final Offset? position;

  /// Override width of the text container.
  final double? width;

  /// Override scale factor.
  final double? scale;

  /// Override font size (applied to the text style).
  final double? fontSize;

  /// Override rotation angle.
  final double? rotation;

  // ── Typography overrides ──
  /// Override font weight (index 0-8 → FontWeight.w100-w900).
  final int? fontWeightIndex;

  /// Override font style (0 = normal, 1 = italic).
  final int? fontStyleIndex;

  /// Override text alignment (TextAlign.index).
  final int? textAlignIndex;

  /// Override Google Font family name.
  final String? googleFont;

  // ── Color overrides (stored as ARGB int) ──
  /// Override text color.
  final int? color;

  /// Override background color.
  final int? backgroundColor;

  /// Override border color.
  final int? borderColor;

  /// Override decoration color.
  final int? decorationColor;

  // ── Border / padding overrides ──
  /// Override border width.
  final double? borderWidth;

  /// Override border radius.
  final double? borderRadius;

  /// Override horizontal padding.
  final double? horizontalPadding;

  /// Override vertical padding.
  final double? verticalPadding;

  // ── Decoration overrides ──
  /// Override text decoration (serialized string, e.g. "TextDecoration.underline").
  final String? decoration;

  /// Override decoration style (TextDecorationStyle.index).
  final int? decorationStyleIndex;

  const OverlayOverride({
    this.position,
    this.width,
    this.scale,
    this.fontSize,
    this.rotation,
    this.fontWeightIndex,
    this.fontStyleIndex,
    this.textAlignIndex,
    this.googleFont,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.decorationColor,
    this.borderWidth,
    this.borderRadius,
    this.horizontalPadding,
    this.verticalPadding,
    this.decoration,
    this.decorationStyleIndex,
  });

  OverlayOverride copyWith({
    Offset? position,
    double? width,
    double? scale,
    double? fontSize,
    double? rotation,
    int? fontWeightIndex,
    int? fontStyleIndex,
    int? textAlignIndex,
    String? googleFont,
    int? color,
    int? backgroundColor,
    int? borderColor,
    int? decorationColor,
    double? borderWidth,
    double? borderRadius,
    double? horizontalPadding,
    double? verticalPadding,
    String? decoration,
    int? decorationStyleIndex,
    // Clear flags
    bool clearPosition = false,
    bool clearWidth = false,
    bool clearScale = false,
    bool clearFontSize = false,
    bool clearRotation = false,
    bool clearFontWeightIndex = false,
    bool clearFontStyleIndex = false,
    bool clearTextAlignIndex = false,
    bool clearGoogleFont = false,
    bool clearColor = false,
    bool clearBackgroundColor = false,
    bool clearBorderColor = false,
    bool clearDecorationColor = false,
    bool clearBorderWidth = false,
    bool clearBorderRadius = false,
    bool clearHorizontalPadding = false,
    bool clearVerticalPadding = false,
    bool clearDecoration = false,
    bool clearDecorationStyleIndex = false,
  }) {
    return OverlayOverride(
      position: clearPosition ? null : (position ?? this.position),
      width: clearWidth ? null : (width ?? this.width),
      scale: clearScale ? null : (scale ?? this.scale),
      fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
      rotation: clearRotation ? null : (rotation ?? this.rotation),
      fontWeightIndex: clearFontWeightIndex
          ? null
          : (fontWeightIndex ?? this.fontWeightIndex),
      fontStyleIndex: clearFontStyleIndex
          ? null
          : (fontStyleIndex ?? this.fontStyleIndex),
      textAlignIndex: clearTextAlignIndex
          ? null
          : (textAlignIndex ?? this.textAlignIndex),
      googleFont: clearGoogleFont ? null : (googleFont ?? this.googleFont),
      color: clearColor ? null : (color ?? this.color),
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
      borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
      decorationColor: clearDecorationColor
          ? null
          : (decorationColor ?? this.decorationColor),
      borderWidth: clearBorderWidth ? null : (borderWidth ?? this.borderWidth),
      borderRadius: clearBorderRadius
          ? null
          : (borderRadius ?? this.borderRadius),
      horizontalPadding: clearHorizontalPadding
          ? null
          : (horizontalPadding ?? this.horizontalPadding),
      verticalPadding: clearVerticalPadding
          ? null
          : (verticalPadding ?? this.verticalPadding),
      decoration: clearDecoration ? null : (decoration ?? this.decoration),
      decorationStyleIndex: clearDecorationStyleIndex
          ? null
          : (decorationStyleIndex ?? this.decorationStyleIndex),
    );
  }

  /// Merge another override on top of this one. Non-null values in [other] win.
  OverlayOverride merge(OverlayOverride other) {
    return OverlayOverride(
      position: other.position ?? position,
      width: other.width ?? width,
      scale: other.scale ?? scale,
      fontSize: other.fontSize ?? fontSize,
      rotation: other.rotation ?? rotation,
      fontWeightIndex: other.fontWeightIndex ?? fontWeightIndex,
      fontStyleIndex: other.fontStyleIndex ?? fontStyleIndex,
      textAlignIndex: other.textAlignIndex ?? textAlignIndex,
      googleFont: other.googleFont ?? googleFont,
      color: other.color ?? color,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      decorationColor: other.decorationColor ?? decorationColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      horizontalPadding: other.horizontalPadding ?? horizontalPadding,
      verticalPadding: other.verticalPadding ?? verticalPadding,
      decoration: other.decoration ?? decoration,
      decorationStyleIndex: other.decorationStyleIndex ?? decorationStyleIndex,
    );
  }

  /// Whether this override has any non-null value.
  bool get isEmpty =>
      position == null &&
      width == null &&
      scale == null &&
      fontSize == null &&
      rotation == null &&
      fontWeightIndex == null &&
      fontStyleIndex == null &&
      textAlignIndex == null &&
      googleFont == null &&
      color == null &&
      backgroundColor == null &&
      borderColor == null &&
      decorationColor == null &&
      borderWidth == null &&
      borderRadius == null &&
      horizontalPadding == null &&
      verticalPadding == null &&
      decoration == null &&
      decorationStyleIndex == null;

  Map<String, dynamic> toJson() => {
    if (position != null) 'dx': position!.dx,
    if (position != null) 'dy': position!.dy,
    if (width != null) 'width': width,
    if (scale != null) 'scale': scale,
    if (fontSize != null) 'fontSize': fontSize,
    if (rotation != null) 'rotation': rotation,
    if (fontWeightIndex != null) 'fontWeightIndex': fontWeightIndex,
    if (fontStyleIndex != null) 'fontStyleIndex': fontStyleIndex,
    if (textAlignIndex != null) 'textAlignIndex': textAlignIndex,
    if (googleFont != null) 'googleFont': googleFont,
    if (color != null) 'color': color,
    if (backgroundColor != null) 'backgroundColor': backgroundColor,
    if (borderColor != null) 'borderColor': borderColor,
    if (decorationColor != null) 'decorationColor': decorationColor,
    if (borderWidth != null) 'borderWidth': borderWidth,
    if (borderRadius != null) 'borderRadius': borderRadius,
    if (horizontalPadding != null) 'horizontalPadding': horizontalPadding,
    if (verticalPadding != null) 'verticalPadding': verticalPadding,
    if (decoration != null) 'decoration': decoration,
    if (decorationStyleIndex != null)
      'decorationStyleIndex': decorationStyleIndex,
  };

  factory OverlayOverride.fromJson(Map<String, dynamic> json) {
    return OverlayOverride(
      position: json.containsKey('dx') && json.containsKey('dy')
          ? Offset(
              (json['dx'] as num).toDouble(),
              (json['dy'] as num).toDouble(),
            )
          : null,
      width: (json['width'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      fontWeightIndex: (json['fontWeightIndex'] as num?)?.toInt(),
      fontStyleIndex: (json['fontStyleIndex'] as num?)?.toInt(),
      textAlignIndex: (json['textAlignIndex'] as num?)?.toInt(),
      googleFont: json['googleFont'] as String?,
      color: (json['color'] as num?)?.toInt(),
      backgroundColor: (json['backgroundColor'] as num?)?.toInt(),
      borderColor: (json['borderColor'] as num?)?.toInt(),
      decorationColor: (json['decorationColor'] as num?)?.toInt(),
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
      borderRadius: (json['borderRadius'] as num?)?.toDouble(),
      horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble(),
      verticalPadding: (json['verticalPadding'] as num?)?.toDouble(),
      decoration: json['decoration'] as String?,
      decorationStyleIndex: (json['decorationStyleIndex'] as num?)?.toInt(),
    );
  }

  // ── Convenience helpers to resolve effective values ──

  /// Resolve effective FontWeight from this override or the base value.
  FontWeight? get fontWeight => fontWeightIndex != null
      ? FontWeight.values[fontWeightIndex!.clamp(0, 8)]
      : null;

  /// Resolve effective FontStyle from this override or the base value.
  FontStyle? get fontStyle => fontStyleIndex != null
      ? FontStyle.values[fontStyleIndex!.clamp(0, 1)]
      : null;

  /// Resolve effective TextAlign from this override.
  TextAlign? get textAlign => textAlignIndex != null
      ? TextAlign.values[textAlignIndex!.clamp(0, TextAlign.values.length - 1)]
      : null;

  /// Resolve effective TextDecoration from this override.
  TextDecoration? get textDecoration {
    switch (decoration) {
      case 'TextDecoration.underline':
        return TextDecoration.underline;
      case 'TextDecoration.overline':
        return TextDecoration.overline;
      case 'TextDecoration.lineThrough':
        return TextDecoration.lineThrough;
      case 'TextDecoration.none':
        return TextDecoration.none;
      default:
        return null;
    }
  }

  /// Resolve effective TextDecorationStyle from this override.
  TextDecorationStyle? get textDecorationStyle => decorationStyleIndex != null
      ? TextDecorationStyle.values[decorationStyleIndex!.clamp(
          0,
          TextDecorationStyle.values.length - 1,
        )]
      : null;

  @override
  List<Object?> get props => [
    position,
    width,
    scale,
    fontSize,
    rotation,
    fontWeightIndex,
    fontStyleIndex,
    textAlignIndex,
    googleFont,
    color,
    backgroundColor,
    borderColor,
    decorationColor,
    borderWidth,
    borderRadius,
    horizontalPadding,
    verticalPadding,
    decoration,
    decorationStyleIndex,
  ];
}
