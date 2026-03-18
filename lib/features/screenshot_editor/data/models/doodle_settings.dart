part of 'screenshot_design.dart';

enum DoodleIconSource { sfSymbols, materialSymbols, emoji }

class DoodleSettings {
  final bool enabled;
  final DoodleIconSource iconSource;
  final List<int> iconCodePoints;
  final List<String> emojiCharacters;
  final Color iconColor;
  final Gradient? iconGradient;
  final double iconOpacity;
  final double iconSize;
  final double spacing;
  final double rotation;
  final bool randomizeRotation;

  const DoodleSettings({
    this.enabled = false,
    this.iconSource = DoodleIconSource.sfSymbols,
    this.iconCodePoints = const [],
    this.emojiCharacters = const [],
    this.iconColor = Colors.white,
    this.iconGradient,
    this.iconOpacity = 0.08,
    this.iconSize = 40.0,
    this.spacing = 60.0,
    this.rotation = 0.0,
    this.randomizeRotation = false,
  });

  DoodleSettings copyWith({
    bool? enabled,
    DoodleIconSource? iconSource,
    List<int>? iconCodePoints,
    List<String>? emojiCharacters,
    Color? iconColor,
    Gradient? iconGradient,
    double? iconOpacity,
    double? iconSize,
    double? spacing,
    double? rotation,
    bool? randomizeRotation,
    bool clearGradient = false,
  }) {
    return DoodleSettings(
      enabled: enabled ?? this.enabled,
      iconSource: iconSource ?? this.iconSource,
      iconCodePoints: iconCodePoints ?? this.iconCodePoints,
      emojiCharacters: emojiCharacters ?? this.emojiCharacters,
      iconColor: iconColor ?? this.iconColor,
      iconGradient: clearGradient ? null : (iconGradient ?? this.iconGradient),
      iconOpacity: iconOpacity ?? this.iconOpacity,
      iconSize: iconSize ?? this.iconSize,
      spacing: spacing ?? this.spacing,
      rotation: rotation ?? this.rotation,
      randomizeRotation: randomizeRotation ?? this.randomizeRotation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'iconSource': iconSource.index,
      'iconCodePoints': iconCodePoints,
      'emojiCharacters': emojiCharacters,
      'iconColor': iconColor.toARGB32(),
      'iconGradient': iconGradient != null
          ? ScreenshotDesign._gradientToJson(iconGradient!)
          : null,
      'iconOpacity': iconOpacity,
      'iconSize': iconSize,
      'spacing': spacing,
      'rotation': rotation,
      'randomizeRotation': randomizeRotation,
    };
  }

  factory DoodleSettings.fromJson(Map<String, dynamic> json) {
    return DoodleSettings(
      enabled: json['enabled'] ?? false,
      iconSource: DoodleIconSource.values[json['iconSource'] ?? 0],
      iconCodePoints:
          (json['iconCodePoints'] as List?)?.map((e) => e as int).toList() ??
          [],
      emojiCharacters:
          (json['emojiCharacters'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      iconColor: Color(json['iconColor'] ?? Colors.white.toARGB32()),
      iconGradient: json['iconGradient'] != null
          ? ScreenshotDesign._gradientFromJson(json['iconGradient'])
          : null,
      iconOpacity: (json['iconOpacity'] as num?)?.toDouble() ?? 0.08,
      iconSize: (json['iconSize'] as num?)?.toDouble() ?? 40.0,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 60.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      randomizeRotation: json['randomizeRotation'] ?? false,
    );
  }
}
