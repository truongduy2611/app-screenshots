import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';

class SavedDesign {
  final String id;
  final String name;
  final DateTime lastModified;
  final String thumbnailPath;
  final String? imagePath;
  final String? folderId;
  final ScreenshotDesign design;

  /// For multi-canvas saves: the full list of designs.
  /// When null, this is a single-canvas save (use [design]).
  final List<ScreenshotDesign>? multiDesigns;

  /// For multi-canvas saves: per-design image paths.
  final List<String?>? imagePaths;

  /// Translation data for multi-language screenshots.
  final TranslationBundle? translationBundle;

  /// Persisted ASC app selection for this design.
  final AscAppConfig? ascAppConfig;

  SavedDesign({
    required this.id,
    required this.name,
    required this.lastModified,
    required this.thumbnailPath,
    this.imagePath,
    this.folderId,
    required this.design,
    this.multiDesigns,
    this.imagePaths,
    this.translationBundle,
    this.ascAppConfig,
  });

  /// Whether this saved design is a multi-canvas project.
  bool get isMulti => multiDesigns != null && multiDesigns!.isNotEmpty;

  SavedDesign copyWith({
    String? id,
    String? name,
    DateTime? lastModified,
    String? thumbnailPath,
    String? imagePath,
    String? folderId,
    ScreenshotDesign? design,
    List<ScreenshotDesign>? multiDesigns,
    List<String?>? imagePaths,
    TranslationBundle? translationBundle,
    AscAppConfig? ascAppConfig,
    bool clearAscAppConfig = false,
  }) {
    return SavedDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      imagePath: imagePath ?? this.imagePath,
      folderId: folderId ?? this.folderId,
      design: design ?? this.design,
      multiDesigns: multiDesigns ?? this.multiDesigns,
      imagePaths: imagePaths ?? this.imagePaths,
      translationBundle: translationBundle ?? this.translationBundle,
      ascAppConfig: clearAscAppConfig
          ? null
          : (ascAppConfig ?? this.ascAppConfig),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastModified': lastModified.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'imagePath': imagePath,
      'folderId': folderId,
      'design': design.toJson(),
      if (multiDesigns != null)
        'multiDesigns': multiDesigns!.map((d) => d.toJson()).toList(),
      if (imagePaths != null) 'imagePaths': imagePaths,
      if (translationBundle != null)
        'translationBundle': translationBundle!.toJson(),
      if (ascAppConfig != null) 'ascAppConfig': ascAppConfig!.toJson(),
    };
  }

  factory SavedDesign.fromJson(Map<String, dynamic> json) {
    return SavedDesign(
      id: json['id'],
      name: json['name'],
      lastModified: DateTime.parse(json['lastModified']),
      thumbnailPath: json['thumbnailPath'],
      imagePath: json['imagePath'],
      folderId: json['folderId'],
      design: ScreenshotDesign.fromJson(json['design']),
      multiDesigns: json['multiDesigns'] != null
          ? (json['multiDesigns'] as List)
                .map((d) => ScreenshotDesign.fromJson(d))
                .toList()
          : null,
      imagePaths: json['imagePaths'] != null
          ? (json['imagePaths'] as List).cast<String?>()
          : null,
      translationBundle: json['translationBundle'] != null
          ? TranslationBundle.fromJson(
              json['translationBundle'] as Map<String, dynamic>,
            )
          : null,
      ascAppConfig: json['ascAppConfig'] != null
          ? AscAppConfig.fromJson(json['ascAppConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}
