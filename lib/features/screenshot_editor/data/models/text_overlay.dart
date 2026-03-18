part of 'screenshot_design.dart';

class TextOverlay {
  final String id;
  final String text;
  final TextStyle style;
  final Offset position;
  final String? googleFont;
  final double rotation;
  final TextAlign textAlign;
  final TextDecoration decoration;
  final TextDecorationStyle decorationStyle;
  final Color? decorationColor;
  // Container properties
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final double scale;
  final double? width;
  final int zIndex;
  final bool behindFrame;

  TextOverlay({
    required this.id,
    required this.text,
    required this.style,
    required this.position,
    this.googleFont,
    this.rotation = 0.0,
    this.textAlign = TextAlign.center,
    this.decoration = TextDecoration.none,
    this.decorationStyle = TextDecorationStyle.solid,
    this.decorationColor,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius = 0.0,
    this.horizontalPadding = 8.0,
    this.verticalPadding = 8.0,
    this.scale = 1.0,
    this.width,
    this.zIndex = 0,
    this.behindFrame = false,
  });

  TextOverlay copyWith({
    String? text,
    TextStyle? style,
    Offset? position,
    String? googleFont,
    double? rotation,
    TextAlign? textAlign,
    TextDecoration? decoration,
    TextDecorationStyle? decorationStyle,
    Color? decorationColor,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    double? horizontalPadding,
    double? verticalPadding,
    double? scale,
    double? width,
    int? zIndex,
    bool? behindFrame,
    bool clearWidth = false,
  }) {
    return TextOverlay(
      id: id,
      text: text ?? this.text,
      style: style ?? this.style,
      position: position ?? this.position,
      googleFont: googleFont ?? this.googleFont,
      rotation: rotation ?? this.rotation,
      textAlign: textAlign ?? this.textAlign,
      decoration: decoration ?? this.decoration,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      decorationColor: decorationColor ?? this.decorationColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      scale: scale ?? this.scale,
      width: clearWidth ? null : (width ?? this.width),
      zIndex: zIndex ?? this.zIndex,
      behindFrame: behindFrame ?? this.behindFrame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'style': {
        'fontSize': style.fontSize,
        'color': style.color?.toARGB32(),
        'fontWeight': style.fontWeight?.value,
        'fontStyle': style.fontStyle?.index,
      },
      'position': {'dx': position.dx, 'dy': position.dy},
      'googleFont': googleFont,
      'rotation': rotation,
      'textAlign': textAlign.index,
      'decoration': decoration.toString(),
      'decorationStyle': decorationStyle.index,
      'decorationColor': decorationColor?.toARGB32(),
      'backgroundColor': backgroundColor?.toARGB32(),
      'borderColor': borderColor?.toARGB32(),
      'borderWidth': borderWidth,
      'borderRadius': borderRadius,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
      'scale': scale,
      'width': width,
      'zIndex': zIndex,
      'behindFrame': behindFrame,
    };
  }

  factory TextOverlay.fromJson(Map<String, dynamic> json) {
    return TextOverlay(
      id: json['id'],
      text: json['text'],
      style: TextStyle(
        fontSize: (json['style']['fontSize'] as num?)?.toDouble(),
        color: json['style']['color'] != null
            ? Color(json['style']['color'])
            : null,
        fontWeight: json['style']['fontWeight'] != null
            ? FontWeight.values[json['style']['fontWeight']]
            : null,
        fontStyle: json['style']['fontStyle'] != null
            ? FontStyle.values[json['style']['fontStyle']]
            : null,
      ),
      position: Offset(
        (json['position']?['dx'] as num?)?.toDouble() ?? 0,
        (json['position']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      googleFont: json['googleFont'],
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      textAlign: TextAlign.values[json['textAlign'] ?? TextAlign.center.index],
      decoration: _parseDecoration(json['decoration']),
      decorationStyle: TextDecorationStyle
          .values[json['decorationStyle'] ?? TextDecorationStyle.solid.index],
      decorationColor: json['decorationColor'] != null
          ? Color(json['decorationColor'])
          : null,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'])
          : null,
      borderColor: json['borderColor'] != null
          ? Color(json['borderColor'])
          : null,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.0,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0.0,
      horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble() ?? 8.0,
      verticalPadding: (json['verticalPadding'] as num?)?.toDouble() ?? 8.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      width: (json['width'] as num?)?.toDouble(),
      zIndex: json['zIndex'] as int? ?? 1, // Default zIndex for text is 1
      behindFrame: json['behindFrame'] as bool? ?? false,
    );
  }

  static TextDecoration _parseDecoration(String? value) {
    switch (value) {
      case 'TextDecoration.underline':
        return TextDecoration.underline;
      case 'TextDecoration.overline':
        return TextDecoration.overline;
      case 'TextDecoration.lineThrough':
        return TextDecoration.lineThrough;
      default:
        return TextDecoration.none;
    }
  }
}
