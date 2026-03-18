part of 'screenshot_design.dart';

class GridSettings {
  final bool showGrid;
  final bool showDotGrid;
  final bool snapToGrid;
  final double gridSize;
  final Color gridColor;
  final bool showCenterLines;

  const GridSettings({
    this.showGrid = false,
    this.showDotGrid = true,
    this.snapToGrid = true,
    this.gridSize = 50.0,
    this.gridColor = const Color(0x80FFFFFF),
    this.showCenterLines = false,
  });

  GridSettings copyWith({
    bool? showGrid,
    bool? showDotGrid,
    bool? snapToGrid,
    double? gridSize,
    Color? gridColor,
    bool? showCenterLines,
  }) {
    return GridSettings(
      showGrid: showGrid ?? this.showGrid,
      showDotGrid: showDotGrid ?? this.showDotGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
      gridColor: gridColor ?? this.gridColor,
      showCenterLines: showCenterLines ?? this.showCenterLines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showGrid': showGrid,
      'showDotGrid': showDotGrid,
      'snapToGrid': snapToGrid,
      'gridSize': gridSize,
      'gridColor': gridColor.toARGB32(),
      'showCenterLines': showCenterLines,
    };
  }

  factory GridSettings.fromJson(Map<String, dynamic> json) {
    return GridSettings(
      showGrid: json['showGrid'] ?? false,
      showDotGrid: json['showDotGrid'] ?? true,
      snapToGrid: json['snapToGrid'] ?? true,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 50.0,
      gridColor: Color(json['gridColor'] ?? 0x80FFFFFF),
      showCenterLines: json['showCenterLines'] ?? false,
    );
  }
}
