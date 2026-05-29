part of 'screenshot_editor_cubit.dart';

/// Sentinel value to explicitly clear a nullable field via copyWith.
const _cleared = '_CLEARED_';

class ScreenshotEditorState extends Equatable {
  final String? selectedImageUrl;
  final File? selectedImageFile;
  final ScreenshotDesign design;
  final String? selectedOverlayId;
  final String? savedDesignId;
  final String? savedDesignName;

  /// Path to the original `.appshots` file when opened directly from
  /// the file system. When set, "Save" writes back to this file.
  final String? sourceFilePath;

  /// History state flags
  final bool canUndo;
  final bool canRedo;

  const ScreenshotEditorState({
    this.selectedImageUrl,
    this.selectedImageFile,
    this.design = const ScreenshotDesign(),
    this.selectedOverlayId,
    this.savedDesignId,
    this.savedDesignName,
    this.sourceFilePath,
    this.canUndo = false,
    this.canRedo = false,
  });

  ScreenshotEditorState copyWith({
    String? selectedImageUrl,
    File? selectedImageFile,
    ScreenshotDesign? design,
    Object? selectedOverlayId = _cleared,
    String? savedDesignId,
    String? savedDesignName,
    String? sourceFilePath,
    bool? canUndo,
    bool? canRedo,
  }) {
    return ScreenshotEditorState(
      selectedImageUrl: selectedImageUrl ?? this.selectedImageUrl,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile,
      design: design ?? this.design,
      selectedOverlayId: selectedOverlayId == _cleared
          ? this.selectedOverlayId
          : selectedOverlayId as String?,
      savedDesignId: savedDesignId ?? this.savedDesignId,
      savedDesignName: savedDesignName ?? this.savedDesignName,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  @override
  List<Object?> get props => [
    selectedImageUrl,
    selectedImageFile?.path,
    design,
    selectedOverlayId,
    savedDesignId,
    savedDesignName,
    sourceFilePath,
    canUndo,
    canRedo,
  ];
}
