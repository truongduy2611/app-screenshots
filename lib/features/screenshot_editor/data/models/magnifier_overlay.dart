part of 'screenshot_design.dart';

/// Shape options for the magnifier lens.
enum MagnifierShape { circle, roundedRectangle, star, hexagon, diamond, heart }

class MagnifierOverlay {
  final String id;
  final Offset position;
  final double width;
  final double height;
  final double zoomLevel;
  final Offset sourceOffset; // offset from magnifier center to source area
  final double borderWidth;
  final Color borderColor;
  final double opacity;
  final int zIndex;
  final bool behindFrame;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final MagnifierShape shape;
  final double cornerRadius; // for roundedRectangle
  final int starPoints; // number of star points

  const MagnifierOverlay({
    required this.id,
    required this.position,
    this.width = 150,
    this.height = 150,
    this.zoomLevel = 2.0,
    this.sourceOffset = Offset.zero,
    this.borderWidth = 3.0,
    this.borderColor = Colors.white,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.behindFrame = false,
    this.shadowColor,
    this.shadowBlurRadius = 8.0,
    this.shape = MagnifierShape.circle,
    this.cornerRadius = 20.0,
    this.starPoints = 5,
  });

  MagnifierOverlay copyWith({
    Offset? position,
    double? width,
    double? height,
    double? zoomLevel,
    Offset? sourceOffset,
    double? borderWidth,
    Color? borderColor,
    double? opacity,
    int? zIndex,
    bool? behindFrame,
    Color? shadowColor,
    double? shadowBlurRadius,
    bool clearShadowColor = false,
    MagnifierShape? shape,
    double? cornerRadius,
    int? starPoints,
  }) {
    return MagnifierOverlay(
      id: id,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      sourceOffset: sourceOffset ?? this.sourceOffset,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      behindFrame: behindFrame ?? this.behindFrame,
      shadowColor: clearShadowColor ? null : (shadowColor ?? this.shadowColor),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shape: shape ?? this.shape,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      starPoints: starPoints ?? this.starPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': {'dx': position.dx, 'dy': position.dy},
      'width': width,
      'height': height,
      'zoomLevel': zoomLevel,
      'sourceOffset': {'dx': sourceOffset.dx, 'dy': sourceOffset.dy},
      'borderWidth': borderWidth,
      'borderColor': borderColor.toARGB32(),
      'opacity': opacity,
      'zIndex': zIndex,
      'behindFrame': behindFrame,
      'shadowColor': shadowColor?.toARGB32(),
      'shadowBlurRadius': shadowBlurRadius,
      'shape': shape.name,
      'cornerRadius': cornerRadius,
      'starPoints': starPoints,
    };
  }

  factory MagnifierOverlay.fromJson(Map<String, dynamic> json) {
    // Support legacy 'size' field for backwards compatibility
    final legacySize = (json['size'] as num?)?.toDouble();
    final aspectRatio = (json['aspectRatio'] as num?)?.toDouble() ?? 1.0;

    return MagnifierOverlay(
      id: json['id'],
      position: Offset(
        (json['position']?['dx'] as num?)?.toDouble() ?? 0,
        (json['position']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      width: (json['width'] as num?)?.toDouble() ?? legacySize ?? 150,
      height:
          (json['height'] as num?)?.toDouble() ??
          (legacySize != null ? legacySize / aspectRatio : 150),
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 2.0,
      sourceOffset: Offset(
        (json['sourceOffset']?['dx'] as num?)?.toDouble() ?? 0,
        (json['sourceOffset']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 3.0,
      borderColor: Color(json['borderColor'] ?? Colors.white.toARGB32()),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['zIndex'] as int? ?? 0,
      behindFrame: json['behindFrame'] as bool? ?? false,
      shadowColor: json['shadowColor'] != null
          ? Color(json['shadowColor'])
          : null,
      shadowBlurRadius: (json['shadowBlurRadius'] as num?)?.toDouble() ?? 8.0,
      shape: MagnifierShape.values.firstWhere(
        (e) => e.name == json['shape'],
        orElse: () => MagnifierShape.circle,
      ),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 20.0,
      starPoints: json['starPoints'] as int? ?? 5,
    );
  }
}
