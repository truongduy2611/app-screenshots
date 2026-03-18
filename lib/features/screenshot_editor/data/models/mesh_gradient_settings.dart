import 'package:flutter/material.dart';

/// Persisted configuration for a mesh gradient background.
///
/// Stores a list of mesh gradient points (position + color) that are rendered
/// by the `mesh_gradient` package widget.
class MeshGradientSettings {
  final List<MeshPoint> points;

  /// Controls how strongly neighboring colors blend (higher = less blending).
  final double blend;

  /// Intensity of the acrylic noise texture applied over the gradient.
  final double noiseIntensity;

  const MeshGradientSettings({
    required this.points,
    this.blend = 3.0,
    this.noiseIntensity = 0.0,
  });

  MeshGradientSettings copyWith({
    List<MeshPoint>? points,
    double? blend,
    double? noiseIntensity,
  }) {
    return MeshGradientSettings(
      points: points ?? this.points,
      blend: blend ?? this.blend,
      noiseIntensity: noiseIntensity ?? this.noiseIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'blend': blend,
      'noiseIntensity': noiseIntensity,
    };
  }

  factory MeshGradientSettings.fromJson(Map<String, dynamic> json) {
    return MeshGradientSettings(
      points: (json['points'] as List)
          .map((e) => MeshPoint.fromJson(e))
          .toList(),
      blend: (json['blend'] as num?)?.toDouble() ?? 3.0,
      noiseIntensity: (json['noiseIntensity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A single point in the mesh gradient grid.
class MeshPoint {
  /// Position in normalized coordinates (0..1 for both x and y).
  final Offset position;
  final Color color;

  const MeshPoint({required this.position, required this.color});

  MeshPoint copyWith({Offset? position, Color? color}) {
    return MeshPoint(
      position: position ?? this.position,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': position.dx,
    'y': position.dy,
    'color': color.toARGB32(),
  };

  factory MeshPoint.fromJson(Map<String, dynamic> json) {
    return MeshPoint(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
    );
  }
}
