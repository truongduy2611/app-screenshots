part of 'multi_screenshot_cubit.dart';

class MultiScreenshotState extends Equatable {
  /// List of screenshot designs (up to 10), each fully independent.
  final List<ScreenshotDesign> designs;

  /// Per-design image files (one per design).
  final List<File?> imageFiles;

  /// Index of the currently active design being edited.
  final int activeIndex;

  /// Persistence identifiers.
  final String? savedDesignId;
  final String? savedDesignName;

  /// Path to the original `.appshots` file when opened directly from
  /// the file system. When set, "Save" writes back to this file.
  final String? sourceFilePath;

  /// Saved ASC app config for quick re-upload.
  final AscAppConfig? ascAppConfig;

  const MultiScreenshotState({
    this.designs = const [],
    this.imageFiles = const [],
    this.activeIndex = 0,
    this.savedDesignId,
    this.savedDesignName,
    this.sourceFilePath,
    this.ascAppConfig,
  });

  /// The currently active design.
  ScreenshotDesign? get activeDesign =>
      designs.isNotEmpty ? designs[activeIndex] : null;

  /// The currently active image file.
  File? get activeImageFile =>
      imageFiles.isNotEmpty ? imageFiles[activeIndex] : null;

  /// Number of screenshots.
  int get count => designs.length;

  /// Whether more screenshots can be added.
  bool get canAddMore => designs.length < 10;

  MultiScreenshotState copyWith({
    List<ScreenshotDesign>? designs,
    List<File?>? imageFiles,
    int? activeIndex,
    String? savedDesignId,
    String? savedDesignName,
    String? sourceFilePath,
    AscAppConfig? ascAppConfig,
    bool clearAscAppConfig = false,
  }) {
    return MultiScreenshotState(
      designs: designs ?? this.designs,
      imageFiles: imageFiles ?? this.imageFiles,
      activeIndex: activeIndex ?? this.activeIndex,
      savedDesignId: savedDesignId ?? this.savedDesignId,
      savedDesignName: savedDesignName ?? this.savedDesignName,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      ascAppConfig: clearAscAppConfig
          ? null
          : (ascAppConfig ?? this.ascAppConfig),
    );
  }

  @override
  List<Object?> get props => [
    designs,
    imageFiles.map((f) => f?.path).toList(),
    activeIndex,
    savedDesignId,
    savedDesignName,
    sourceFilePath,
    ascAppConfig,
  ];
}
