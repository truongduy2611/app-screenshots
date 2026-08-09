part of 'board_cubit.dart';

/// What kind of element the board editor currently has selected.
enum BoardSelectionKind { none, frame, zone }

class BoardState extends Equatable {
  /// The board being edited. Its `background` is only authoritative after a
  /// sync-back from [ScreenshotEditorCubit], which owns live background and
  /// overlay editing (see [BoardCubit.syncBackground]).
  final BoardDesign board;

  /// Id of the selected frame element, if any.
  final String? selectedFrameId;

  /// Id of the selected crop zone, if any.
  final String? selectedZoneId;

  /// Whether crop zone outlines are drawn in the editor. Never affects
  /// exported pixels — the outlines render outside the capture boundary.
  final bool showCropZones;

  /// Persistence identifiers.
  final String? savedDesignId;
  final String? savedDesignName;

  /// Path to the original `.appshots` file when opened from disk.
  final String? sourceFilePath;

  /// Saved ASC app config for quick re-upload.
  final AscAppConfig? ascAppConfig;

  /// Path to the last successfully rendered upload directory this session.
  final String? lastRenderedAscPath;

  final bool canUndo;
  final bool canRedo;

  /// Increments on every board mutation. The page uses it to decide whether
  /// Undo should target the board or the background/overlay editor, since the
  /// two keep separate histories.
  final int editSeq;

  const BoardState({
    required this.board,
    this.selectedFrameId,
    this.selectedZoneId,
    this.showCropZones = true,
    this.savedDesignId,
    this.savedDesignName,
    this.sourceFilePath,
    this.ascAppConfig,
    this.lastRenderedAscPath,
    this.canUndo = false,
    this.canRedo = false,
    this.editSeq = 0,
  });

  BoardSelectionKind get selectionKind {
    if (selectedFrameId != null) return BoardSelectionKind.frame;
    if (selectedZoneId != null) return BoardSelectionKind.zone;
    return BoardSelectionKind.none;
  }

  FrameElement? get selectedFrame =>
      selectedFrameId == null ? null : board.frameById(selectedFrameId!);

  CropZone? get selectedZone =>
      selectedZoneId == null ? null : board.zoneById(selectedZoneId!);

  /// Number of images an "export all" produces.
  int get exportCount => board.exportableZones.length;

  BoardState copyWith({
    BoardDesign? board,
    String? selectedFrameId,
    String? selectedZoneId,
    bool clearFrameSelection = false,
    bool clearZoneSelection = false,
    bool? showCropZones,
    String? savedDesignId,
    String? savedDesignName,
    String? sourceFilePath,
    AscAppConfig? ascAppConfig,
    bool clearAscAppConfig = false,
    String? lastRenderedAscPath,
    bool? canUndo,
    bool? canRedo,
    int? editSeq,
  }) {
    return BoardState(
      board: board ?? this.board,
      selectedFrameId: clearFrameSelection
          ? null
          : (selectedFrameId ?? this.selectedFrameId),
      selectedZoneId: clearZoneSelection
          ? null
          : (selectedZoneId ?? this.selectedZoneId),
      showCropZones: showCropZones ?? this.showCropZones,
      savedDesignId: savedDesignId ?? this.savedDesignId,
      savedDesignName: savedDesignName ?? this.savedDesignName,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      ascAppConfig: clearAscAppConfig
          ? null
          : (ascAppConfig ?? this.ascAppConfig),
      lastRenderedAscPath: lastRenderedAscPath ?? this.lastRenderedAscPath,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      editSeq: editSeq ?? this.editSeq,
    );
  }

  @override
  List<Object?> get props => [
    board,
    selectedFrameId,
    selectedZoneId,
    showCropZones,
    savedDesignId,
    savedDesignName,
    sourceFilePath,
    ascAppConfig,
    lastRenderedAscPath,
    canUndo,
    canRedo,
    editSeq,
  ];
}
