part of 'screenshot_design.dart';

class ImageOverlay {
  final String id;
  final String? assetPath; // For bundled assets if we add them later
  final String? filePath; // For user uploaded images
  final Uint8List?
  bytes; // Alternative to path if needed, but path preferred for persistence
  final Offset position;
  final double scale;
  final double rotation;
  final double width;
  final double height;
  final int zIndex;
  final double opacity;
  final double cornerRadius;
  final bool flipHorizontal;
  final bool flipVertical;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final bool behindFrame;

  ImageOverlay({
    required this.id,
    this.assetPath,
    this.filePath,
    this.bytes,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.width = 100, // Default width
    this.height = 100, // Default height
    this.zIndex = 0,
    this.opacity = 1.0,
    this.cornerRadius = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.shadowColor,
    this.shadowBlurRadius = 0.0,
    this.shadowOffset = Offset.zero,
    this.behindFrame = false,
  });

  ImageOverlay copyWith({
    String? assetPath,
    String? filePath,
    Uint8List? bytes,
    Offset? position,
    double? scale,
    double? rotation,
    double? width,
    double? height,
    int? zIndex,
    double? opacity,
    double? cornerRadius,
    bool? flipHorizontal,
    bool? flipVertical,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    bool clearShadowColor = false,
    bool? behindFrame,
  }) {
    return ImageOverlay(
      id: id,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      bytes: bytes ?? this.bytes,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      shadowColor: clearShadowColor ? null : (shadowColor ?? this.shadowColor),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      behindFrame: behindFrame ?? this.behindFrame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetPath': assetPath,
      'filePath': filePath,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'rotation': rotation,
      'width': width,
      'height': height,
      'zIndex': zIndex,
      'opacity': opacity,
      'cornerRadius': cornerRadius,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'shadowColor': shadowColor?.toARGB32(),
      'shadowBlurRadius': shadowBlurRadius,
      'shadowOffset': {'dx': shadowOffset.dx, 'dy': shadowOffset.dy},
      'behindFrame': behindFrame,
    };
  }

  factory ImageOverlay.fromJson(Map<String, dynamic> json) {
    return ImageOverlay(
      id: json['id'],
      assetPath: json['assetPath'],
      filePath: json['filePath'],
      position: Offset(
        (json['position']?['dx'] as num?)?.toDouble() ?? 0,
        (json['position']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 100.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      zIndex: json['zIndex'] as int? ?? 0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
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
