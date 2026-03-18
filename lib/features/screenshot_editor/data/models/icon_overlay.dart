part of 'screenshot_design.dart';

class IconOverlay {
  final String id;
  final int codePoint;
  final String fontFamily; // 'sficons', 'MaterialSymbolsRounded/Sharp/Outlined'
  final String fontPackage; // 'flutter_sficon' or 'material_symbols_icons'
  final Color color;
  final double fontWeight; // 100-700, for Material Symbols variable font
  final double size;
  final Offset position;
  final double rotation;
  final double scale;
  final Color? backgroundColor;
  final double borderRadius;
  final double padding;
  final int zIndex;
  final double opacity;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final bool behindFrame;

  IconOverlay({
    required this.id,
    required this.codePoint,
    this.fontFamily = 'MaterialSymbolsRounded',
    this.fontPackage = 'material_symbols_icons',
    this.color = Colors.white,
    this.fontWeight = 400,
    this.size = 120,
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.backgroundColor,
    this.borderRadius = 0.0,
    this.padding = 0.0,
    this.zIndex = 2,
    this.opacity = 1.0,
    this.shadowColor,
    this.shadowBlurRadius = 0.0,
    this.shadowOffset = Offset.zero,
    this.behindFrame = false,
  });

  bool get isSFSymbol => fontFamily == 'sficons';

  IconOverlay copyWith({
    int? codePoint,
    String? fontFamily,
    String? fontPackage,
    Color? color,
    double? fontWeight,
    double? size,
    Offset? position,
    double? rotation,
    double? scale,
    Color? backgroundColor,
    double? borderRadius,
    double? padding,
    int? zIndex,
    bool clearBackground = false,
    double? opacity,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    bool clearShadowColor = false,
    bool? behindFrame,
  }) {
    return IconOverlay(
      id: id,
      codePoint: codePoint ?? this.codePoint,
      fontFamily: fontFamily ?? this.fontFamily,
      fontPackage: fontPackage ?? this.fontPackage,
      color: color ?? this.color,
      fontWeight: fontWeight ?? this.fontWeight,
      size: size ?? this.size,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      backgroundColor: clearBackground
          ? null
          : (backgroundColor ?? this.backgroundColor),
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      zIndex: zIndex ?? this.zIndex,
      opacity: opacity ?? this.opacity,
      shadowColor: clearShadowColor ? null : (shadowColor ?? this.shadowColor),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      behindFrame: behindFrame ?? this.behindFrame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codePoint': codePoint,
      'fontFamily': fontFamily,
      'fontPackage': fontPackage,
      'color': color.toARGB32(),
      'fontWeight': fontWeight,
      'size': size,
      'position': {'dx': position.dx, 'dy': position.dy},
      'rotation': rotation,
      'scale': scale,
      'backgroundColor': backgroundColor?.toARGB32(),
      'borderRadius': borderRadius,
      'padding': padding,
      'zIndex': zIndex,
      'opacity': opacity,
      'shadowColor': shadowColor?.toARGB32(),
      'shadowBlurRadius': shadowBlurRadius,
      'shadowOffset': {'dx': shadowOffset.dx, 'dy': shadowOffset.dy},
      'behindFrame': behindFrame,
    };
  }

  factory IconOverlay.fromJson(Map<String, dynamic> json) {
    return IconOverlay(
      id: json['id'],
      codePoint: json['codePoint'],
      fontFamily: json['fontFamily'] ?? 'MaterialSymbolsRounded',
      fontPackage: json['fontPackage'] ?? 'material_symbols_icons',
      color: json['color'] != null ? Color(json['color']) : Colors.white,
      fontWeight: (json['fontWeight'] as num?)?.toDouble() ?? 400,
      size: (json['size'] as num?)?.toDouble() ?? 120,
      position: Offset(
        (json['position']?['dx'] as num?)?.toDouble() ?? 0,
        (json['position']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'])
          : null,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0.0,
      padding: (json['padding'] as num?)?.toDouble() ?? 0.0,
      zIndex: json['zIndex'] as int? ?? 2,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      shadowColor: json['shadowColor'] != null
          ? Color(json['shadowColor'])
          : null,
      shadowBlurRadius: (json['shadowBlurRadius'] as num?)?.toDouble() ?? 0.0,
      shadowOffset: Offset(
        (json['shadowOffset']?['dx'] as num?)?.toDouble() ?? 0,
        (json['shadowOffset']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      behindFrame: json['behindFrame'] as bool? ?? false,
    );
  }
}
