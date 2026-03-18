import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'screenshot_design.dart';

/// A preset template for multi-screenshot designs.
///
/// Each preset provides 5 pre-configured [ScreenshotDesign] instances
/// with consistent styling (background, fonts, text overlays) that
/// users can customize by editing texts and importing screenshots.
class ScreenshotPreset extends Equatable {
  final String id;
  final String name;
  final String description;

  /// Colors used for the thumbnail preview in the picker UI.
  final List<Color> thumbnailColors;

  /// The Google Font used for the title (for preview rendering).
  final String titleFont;

  /// Template designs (without deviceFrame/displayType — those are
  /// applied by the cubit based on the user's chosen device).
  final List<ScreenshotDesign> designs;

  const ScreenshotPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailColors,
    required this.titleFont,
    required this.designs,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    thumbnailColors,
    titleFont,
    designs,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailColors': thumbnailColors.map((c) => c.toARGB32()).toList(),
      'titleFont': titleFont,
      'designs': designs.map((d) => d.toJson()).toList(),
    };
  }

  factory ScreenshotPreset.fromJson(Map<String, dynamic> json) {
    return ScreenshotPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      thumbnailColors:
          (json['thumbnailColors'] as List<dynamic>?)
              ?.map((e) => Color(e as int))
              .toList() ??
          const [],
      titleFont: json['titleFont'] as String? ?? 'Inter',
      designs:
          (json['designs'] as List<dynamic>?)
              ?.map((e) => ScreenshotDesign.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
