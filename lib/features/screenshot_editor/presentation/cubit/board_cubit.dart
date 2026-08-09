import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_template.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/frame_element.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'board_state.dart';

/// Owns the board's frames, crop zones, and canvas size.
///
/// Background layers and decorations are deliberately *not* owned here — they
/// live in [ScreenshotEditorCubit] as an ordinary [ScreenshotDesign] so the
/// existing background/text/image/icon control panels drive a board unchanged.
/// The page syncs that design back in via [syncBackground] before any save,
/// export, or upload, mirroring how the multi-screenshot editor syncs its
/// active slot.
class BoardCubit extends Cubit<BoardState> {
  static const _uuid = Uuid();

  /// History depth, matching [ScreenshotEditorCubit].
  static const _maxHistory = 50;

  final ScreenshotPersistenceService _persistenceService;
  final String? _folderId;

  BoardCubit({
    String? displayType,
    String? folderId,
    ScreenshotPersistenceService? persistenceService,
    SavedDesign? initialSavedDesign,
    String? sourceFilePath,
    int initialZoneCount = 3,
  }) : _folderId = folderId ?? initialSavedDesign?.folderId,
       _persistenceService =
           persistenceService ?? ScreenshotPersistenceService(),
       super(
         BoardState(
           board:
               initialSavedDesign?.board ??
               BoardDesign.starter(
                 displayType: displayType ?? 'APP_IPHONE_69',
                 zoneCount: initialZoneCount,
               ),
           savedDesignId: initialSavedDesign?.id,
           savedDesignName: initialSavedDesign?.name,
           sourceFilePath: sourceFilePath,
           ascAppConfig: initialSavedDesign?.ascAppConfig,
         ),
       );

  final List<BoardDesign> _undoStack = [];
  final List<BoardDesign> _redoStack = [];
  bool _isBatchEditing = false;

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Collapses a continuous interaction (a drag, a slider) into one undo entry.
  void beginBatchEdit() {
    if (_isBatchEditing) return;
    _isBatchEditing = true;
    _pushUndo(state.board);
  }

  void endBatchEdit() => _isBatchEditing = false;

  void _pushUndo(BoardDesign snapshot) {
    _undoStack.add(snapshot);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  /// Emits [board] as the new state, recording history unless batching.
  void _commit(
    BoardDesign board, {
    String? selectedFrameId,
    String? selectedZoneId,
    bool clearFrameSelection = false,
    bool clearZoneSelection = false,
  }) {
    if (!_isBatchEditing) _pushUndo(state.board);
    emit(
      state.copyWith(
        board: board,
        selectedFrameId: selectedFrameId,
        selectedZoneId: selectedZoneId,
        clearFrameSelection: clearFrameSelection,
        clearZoneSelection: clearZoneSelection,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
        editSeq: state.editSeq + 1,
      ),
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(state.board);
    final previous = _undoStack.removeLast();
    emit(
      _restored(previous).copyWith(
        canUndo: _undoStack.isNotEmpty,
        canRedo: true,
      ),
    );
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(state.board);
    final next = _redoStack.removeLast();
    emit(
      _restored(next).copyWith(
        canUndo: true,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
  }

  /// State for a board restored from history, dropping any selection that
  /// points at an element [board] no longer contains.
  BoardState _restored(BoardDesign board) {
    return state.copyWith(
      board: board,
      editSeq: state.editSeq + 1,
      clearFrameSelection:
          board.frameById(state.selectedFrameId ?? '') == null,
      clearZoneSelection: board.zoneById(state.selectedZoneId ?? '') == null,
    );
  }

  // ---------------------------------------------------------------------------
  // Background sync
  // ---------------------------------------------------------------------------

  /// Pulls the live background + overlays from the editor cubit into the board.
  /// Not undoable here — the editor cubit keeps its own history for them.
  void syncBackground(ScreenshotDesign background) {
    if (identical(state.board.background, background)) return;
    emit(state.copyWith(board: state.board.copyWith(background: background)));
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void selectFrame(String? id) {
    if (id == null) {
      emit(state.copyWith(clearFrameSelection: true));
      return;
    }
    emit(
      state.copyWith(selectedFrameId: id, clearZoneSelection: true),
    );
  }

  void selectZone(String? id) {
    if (id == null) {
      emit(state.copyWith(clearZoneSelection: true));
      return;
    }
    emit(
      state.copyWith(selectedZoneId: id, clearFrameSelection: true),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(clearFrameSelection: true, clearZoneSelection: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Crop zone visibility
  // ---------------------------------------------------------------------------

  /// Show/hide zone outlines. Purely an editor affordance — outlines are drawn
  /// outside the capture boundary, so this never changes exported pixels.
  void toggleCropZones() =>
      emit(state.copyWith(showCropZones: !state.showCropZones));

  void setCropZonesVisible(bool visible) =>
      emit(state.copyWith(showCropZones: visible));

  // ---------------------------------------------------------------------------
  // Frames
  // ---------------------------------------------------------------------------

  /// Adds a frame. Defaults to the centre of [nearZone] (or the board centre),
  /// sized to 70% of that zone.
  void addFrame({CropZone? nearZone, String? imagePath}) {
    final zone = nearZone ?? state.board.cropZones.firstOrNull;
    final zoneSize = zone?.size ?? state.board.size;
    final origin = zone?.position ?? Offset.zero;

    final width = zoneSize.width * 0.7;
    final height = zoneSize.height * 0.7;
    final displayType =
        zone?.displayType ?? state.board.background.displayType ?? 'APP_IPHONE_69';

    final frame = FrameElement(
      id: _uuid.v4(),
      device: ScreenshotUtils.getDefaultDeviceFrame(displayType),
      imagePath: imagePath,
      position: Offset(
        origin.dx + (zoneSize.width - width) / 2,
        origin.dy + (zoneSize.height - height) / 2,
      ),
      size: Size(width, height),
      zIndex: _nextFrameZIndex(),
    );

    _commit(
      state.board.copyWith(frames: [...state.board.frames, frame]),
      selectedFrameId: frame.id,
      clearZoneSelection: true,
    );
  }

  void addFrameElement(FrameElement frame) {
    _commit(
      state.board.copyWith(frames: [...state.board.frames, frame]),
      selectedFrameId: frame.id,
      clearZoneSelection: true,
    );
  }

  void updateFrame(FrameElement frame) {
    final clamped = frame.copyWith(position: _clampToCanvas(frame.position));
    final frames = state.board.frames
        .map((f) => f.id == clamped.id ? clamped : f)
        .toList();
    _commit(_withBoardGrownForContent(state.board.copyWith(frames: frames)));
  }

  /// Board coordinates start at the origin — anything at a negative offset is
  /// off-canvas and silently excluded from every export, so positions are
  /// pinned at zero rather than allowed to go negative.
  static Offset _clampToCanvas(Offset position) =>
      Offset(math.max(0, position.dx), math.max(0, position.dy));

  void removeFrame(String id) {
    final frames = state.board.frames.where((f) => f.id != id).toList();
    _commit(
      state.board.copyWith(frames: frames),
      clearFrameSelection: state.selectedFrameId == id,
    );
  }

  void duplicateFrame(String id) {
    final source = state.board.frameById(id);
    if (source == null) return;
    final copy = source.copyWith(
      id: _uuid.v4(),
      position: source.position + const Offset(60, 60),
      zIndex: _nextFrameZIndex(),
    );
    _commit(
      state.board.copyWith(frames: [...state.board.frames, copy]),
      selectedFrameId: copy.id,
    );
  }

  /// Moves a frame by [delta] board pixels. Call [beginBatchEdit] first when
  /// dragging so the whole gesture is a single undo step.
  void moveFrame(String id, Offset delta) {
    final frame = state.board.frameById(id);
    if (frame == null) return;
    updateFrame(frame.copyWith(position: frame.position + delta));
  }

  void bringFrameToFront(String id) {
    final frame = state.board.frameById(id);
    if (frame == null) return;
    updateFrame(frame.copyWith(zIndex: _nextFrameZIndex()));
  }

  void sendFrameToBack(String id) {
    final frame = state.board.frameById(id);
    if (frame == null) return;
    final minZ = state.board.frames
        .map((f) => f.zIndex)
        .fold<int>(0, math.min);
    updateFrame(frame.copyWith(zIndex: minZ - 1));
  }

  /// Sets a frame's screenshot, copying the file into app-managed storage so
  /// it survives cleanup of the original location.
  Future<void> setFrameImage(String id, File file) async {
    final frame = state.board.frameById(id);
    if (frame == null) return;
    final stable = await copyToStableStorage(file);
    updateFrame(frame.copyWith(imagePath: stable.path));
  }

  int _nextFrameZIndex() {
    if (state.board.frames.isEmpty) return 0;
    return state.board.frames
            .map((f) => f.zIndex)
            .reduce(math.max) +
        1;
  }

  /// Assigns [files] to frames: fills empty frames first, then creates new
  /// frames (each inside the next free crop zone when one is available).
  Future<void> importImages(List<File> files) async {
    if (files.isEmpty) return;

    final stableFiles = <File>[];
    for (final file in files) {
      stableFiles.add(await copyToStableStorage(file));
    }

    final frames = List<FrameElement>.from(state.board.frames);
    final queue = List<File>.from(stableFiles);

    // Pass 1: fill frames that have no image yet.
    for (var i = 0; i < frames.length && queue.isNotEmpty; i++) {
      if (frames[i].imagePath == null) {
        frames[i] = frames[i].copyWith(imagePath: queue.removeAt(0).path);
      }
    }

    // Pass 2: one new frame per remaining file, placed in the next zone that
    // has no frame overlapping it, else offset from the last frame.
    var nextZ = frames.isEmpty
        ? 0
        : frames.map((f) => f.zIndex).reduce(math.max) + 1;
    while (queue.isNotEmpty) {
      final file = queue.removeAt(0);
      final zone = _firstZoneWithoutFrame(frames);
      final zoneSize = zone?.size ?? state.board.size;
      final origin = zone?.position ?? Offset.zero;
      final width = zoneSize.width * 0.7;
      final height = zoneSize.height * 0.7;
      final displayType =
          zone?.displayType ??
          state.board.background.displayType ??
          'APP_IPHONE_69';

      frames.add(
        FrameElement(
          id: _uuid.v4(),
          device: ScreenshotUtils.getDefaultDeviceFrame(displayType),
          imagePath: file.path,
          position: zone != null
              ? Offset(
                  origin.dx + (zoneSize.width - width) / 2,
                  origin.dy + (zoneSize.height - height) / 2,
                )
              : Offset(80.0 * frames.length, 80.0 * frames.length),
          size: Size(width, height),
          zIndex: nextZ++,
        ),
      );
    }

    _commit(state.board.copyWith(frames: frames));
  }

  CropZone? _firstZoneWithoutFrame(List<FrameElement> frames) {
    for (final zone in state.board.cropZones) {
      final occupied = frames.any((f) => f.rect.overlaps(zone.rect));
      if (!occupied) return zone;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Crop zones
  // ---------------------------------------------------------------------------

  /// Appends a zone to the right of the existing strip, growing the board if
  /// needed so the new zone fits.
  void addZone({String? displayType, Orientation? orientation}) {
    // App Store Connect refuses more than [BoardDesign.maxZones] screenshots
    // per display type, and every zone is one screenshot.
    if (!state.board.canAddZone) return;
    final template = state.board.cropZones.lastOrNull;
    final type =
        displayType ??
        template?.displayType ??
        state.board.background.displayType ??
        'APP_IPHONE_69';
    final orient = orientation ?? template?.orientation ?? Orientation.portrait;
    final size = ScreenshotUtils.getDimensions(type, orient);

    final position = template == null
        ? const Offset(
            BoardDesign.defaultBoardMargin,
            BoardDesign.defaultBoardMargin,
          )
        : Offset(
            template.position.dx +
                template.size.width +
                state.board.zoneGap,
            template.position.dy,
          );

    final zone = CropZone(
      id: _uuid.v4(),
      position: position,
      size: size,
      displayType: type,
      orientation: orient,
    );

    _commit(
      _withBoardGrownForContent(
        state.board.copyWith(cropZones: [...state.board.cropZones, zone]),
      ),
      selectedZoneId: zone.id,
      clearFrameSelection: true,
    );
  }

  void updateZone(CropZone zone) {
    final clamped = zone.copyWith(position: _clampToCanvas(zone.position));
    final zones = state.board.cropZones
        .map((z) => z.id == clamped.id ? clamped : z)
        .toList();
    _commit(_withBoardGrownForContent(state.board.copyWith(cropZones: zones)));
  }

  void removeZone(String id) {
    if (state.board.cropZones.length <= 1) return;
    final zones = state.board.cropZones.where((z) => z.id != id).toList();
    _commit(
      state.board.copyWith(cropZones: zones),
      clearZoneSelection: state.selectedZoneId == id,
    );
  }

  void duplicateZone(String id) {
    if (!state.board.canAddZone) return;
    final source = state.board.zoneById(id);
    if (source == null) return;
    final copy = source.copyWith(
      id: _uuid.v4(),
      position: Offset(
        source.position.dx + source.size.width + state.board.zoneGap,
        source.position.dy,
      ),
    );
    _commit(
      _withBoardGrownForContent(
        state.board.copyWith(cropZones: [...state.board.cropZones, copy]),
      ),
      selectedZoneId: copy.id,
    );
  }

  void moveZone(String id, Offset delta) {
    final zone = state.board.zoneById(id);
    if (zone == null) return;
    updateZone(zone.copyWith(position: zone.position + delta));
  }

  /// Switches a zone's export format. A locked zone resizes to the new
  /// format's native pixel size.
  void setZoneDisplayType(String id, String displayType) {
    final zone = state.board.zoneById(id);
    if (zone == null) return;
    updateZone(zone.copyWith(displayType: displayType));
  }

  void setZoneOrientation(String id, Orientation orientation) {
    final zone = state.board.zoneById(id);
    if (zone == null) return;
    updateZone(zone.copyWith(orientation: orientation));
  }

  /// Locking snaps the zone back to its format's native size so export
  /// returns to a pure, resample-free crop.
  void setZoneLocked(String id, bool locked) {
    final zone = state.board.zoneById(id);
    if (zone == null) return;
    updateZone(zone.copyWith(locked: locked));
  }

  void setZoneIncluded(String id, bool included) {
    final zone = state.board.zoneById(id);
    if (zone == null) return;
    updateZone(zone.copyWith(included: included));
  }

  void renameZone(String id, String? name) {
    final zone = state.board.zoneById(id);
    if (zone == null) return;
    updateZone(
      zone.copyWith(
        name: (name == null || name.isEmpty) ? null : name,
        clearName: name == null || name.isEmpty,
      ),
    );
  }

  void reorderZones(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final zones = List<CropZone>.from(state.board.cropZones);
    if (oldIndex < 0 || oldIndex >= zones.length) return;
    final zone = zones.removeAt(oldIndex);
    zones.insert(newIndex.clamp(0, zones.length), zone);
    _commit(state.board.copyWith(cropZones: zones));
  }

  /// Applies a board template's frame layout and zone spacing.
  ///
  /// The background half of the template is applied separately by
  /// [ScreenshotEditorCubit], which owns it — the page drives both.
  ///
  /// Imported screenshots are preserved: each zone reuses the frame already
  /// sitting in it and only re-places it, so applying a layout to a board the
  /// user has filled in rearranges their work instead of erasing it. Zones
  /// with no frame get a new empty one, so a template always produces a
  /// complete layout.
  void applyTemplate(BoardTemplate template) {
    final zones = state.board.cropZones;
    if (zones.isEmpty) return;

    // Re-flow first so placements are computed against the template's spacing.
    final arranged = _arrangedBoard(state.board, template.zoneGap);

    final claimed = <String>{};
    final frames = <FrameElement>[];

    for (var i = 0; i < arranged.cropZones.length; i++) {
      final zone = arranged.cropZones[i];
      final placement = template.placementFor(i);

      final width = zone.size.width * placement.widthFactor;
      final height = width * FramePlacement.aspect;
      final position = Offset(
        zone.position.dx + zone.size.width * placement.centerX - width / 2,
        zone.position.dy + zone.size.height * placement.centerY - height / 2,
      );

      // Reuse whatever frame is already in this zone so its screenshot stays.
      final existing = arranged.frames
          .where((f) => !claimed.contains(f.id) && zone.rect.contains(f.center))
          .firstOrNull;
      if (existing != null) claimed.add(existing.id);

      frames.add(
        (existing ??
                FrameElement(
                  id: _uuid.v4(),
                  device: ScreenshotUtils.getDefaultDeviceFrame(
                    zone.displayType,
                  ),
                  position: position,
                  size: Size(width, height),
                ))
            .copyWith(
              position: position,
              size: Size(width, height),
              rotation: placement.rotation * math.pi / 180,
              zIndex: i,
            ),
      );
    }

    // Frames outside every zone are the user's own additions — leave them be.
    final unclaimed = arranged.frames.where((f) => !claimed.contains(f.id));

    _commit(
      _withBoardGrownForContent(
        arranged.copyWith(frames: [...frames, ...unclaimed]),
      ),
      clearFrameSelection: true,
      clearZoneSelection: true,
    );
  }

  /// Sets the spacing between zones and re-flows the row so the change is
  /// visible immediately.
  ///
  /// A gap of zero butts the zones together, which is what makes a background
  /// spanning the board continue unbroken across the exported screenshots.
  void setZoneGap(double gap) {
    final next = math.max(0.0, gap);
    if (next == state.board.zoneGap) return;
    autoArrangeZones(gap: next);
  }

  /// Re-lays the zones out left-to-right in a single row and resizes the
  /// board to fit them.
  ///
  /// Frames travel with the zone they sit in, so arranging rearranges whole
  /// screenshots rather than sliding the zones out from under their content.
  /// A frame is assigned to the first zone whose old rect contains its centre;
  /// frames belonging to no zone keep their position.
  ///
  /// [gap] defaults to the board's own [BoardDesign.zoneGap]; passing one both
  /// arranges with it and adopts it as the board's spacing.
  void autoArrangeZones({double? gap}) {
    if (state.board.cropZones.isEmpty) return;
    // Grow to fit the arranged strip, then to fit anything (an unassigned
    // frame) that still falls outside it — arranging must never leave content
    // off-canvas.
    _commit(
      _withBoardGrownForContent(
        _arrangedBoard(state.board, gap ?? state.board.zoneGap),
      ),
    );
  }

  /// [board] with its zones laid out left-to-right at [spacing], frames
  /// carried along with the zone they sit in, and the canvas sized to match.
  /// Pure — callers commit the result.
  static BoardDesign _arrangedBoard(BoardDesign board, double spacing) {
    if (board.cropZones.isEmpty) return board;
    const margin = BoardDesign.defaultBoardMargin;

    var x = margin;
    var tallest = 0.0;
    final zones = <CropZone>[];
    // Frame id -> the delta its owning zone moved by.
    final frameShifts = <String, Offset>{};

    for (final zone in board.cropZones) {
      final moved = zone.copyWith(position: Offset(x, margin));
      final delta = moved.position - zone.position;
      if (delta != Offset.zero) {
        for (final frame in board.frames) {
          if (frameShifts.containsKey(frame.id)) continue;
          if (zone.rect.contains(frame.center)) frameShifts[frame.id] = delta;
        }
      }
      zones.add(moved);
      x += zone.size.width + spacing;
      tallest = math.max(tallest, zone.size.height);
    }

    final frames = board.frames.map((frame) {
      final shift = frameShifts[frame.id];
      return shift == null
          ? frame
          : frame.copyWith(position: frame.position + shift);
    }).toList();

    return board.copyWith(
      cropZones: zones,
      frames: frames,
      zoneGap: spacing,
      // `x` carries a trailing gap from the last zone; drop it so the right
      // margin matches the left even at zero spacing.
      size: Size(x - spacing + margin, tallest + margin * 2),
    );
  }

  // ---------------------------------------------------------------------------
  // Board canvas
  // ---------------------------------------------------------------------------

  void setBoardSize(Size size) {
    _commit(
      state.board.copyWith(
        size: Size(math.max(size.width, 1), math.max(size.height, 1)),
      ),
    );
  }

  /// Grows the board so every zone and frame fits, with a margin.
  void fitBoardToContent({double margin = BoardDesign.defaultBoardMargin}) {
    final bounds = state.board.contentBounds;
    _commit(
      state.board.copyWith(
        size: Size(bounds.right + margin, bounds.bottom + margin),
      ),
    );
  }

  /// Returns [board] with its canvas grown so no zone or frame falls outside
  /// it. Boards never shrink automatically — that would move content
  /// unexpectedly.
  BoardDesign _withBoardGrownForContent(BoardDesign board) {
    var width = board.size.width;
    var height = board.size.height;
    for (final rect in [
      ...board.cropZones.map((z) => z.rect),
      ...board.frames.map((f) => f.rect),
    ]) {
      width = math.max(width, rect.right + BoardDesign.defaultBoardMargin);
      height = math.max(height, rect.bottom + BoardDesign.defaultBoardMargin);
    }
    if (width == board.size.width && height == board.size.height) return board;
    return board.copyWith(size: Size(width, height));
  }

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  void setAscAppConfig(AscAppConfig? config) {
    if (config == null) {
      emit(state.copyWith(clearAscAppConfig: true));
    } else {
      emit(state.copyWith(ascAppConfig: config));
    }
  }

  void setLastRenderedAscPath(String path) =>
      emit(state.copyWith(lastRenderedAscPath: path));

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Builds the [SavedDesign] envelope for this board.
  ///
  /// `design` / `multiDesigns` are filled with the board's background so older
  /// builds (and the library thumbnail path) still have something coherent to
  /// read; [SavedDesign.isBoard] is what routes it to the board editor.
  SavedDesign toSavedDesign({
    required String name,
    String? id,
    String thumbnailPath = '',
    TranslationBundle? translationBundle,
  }) {
    return SavedDesign(
      id: id ?? state.savedDesignId ?? 'unsaved',
      name: name,
      lastModified: DateTime.now(),
      thumbnailPath: thumbnailPath,
      folderId: _folderId,
      design: state.board.background,
      board: state.board,
      translationBundle: translationBundle,
      ascAppConfig: state.ascAppConfig,
    );
  }

  Future<void> saveDesign(
    String name,
    Uint8List thumbnailBytes, {
    bool override = false,
    TranslationBundle? translationBundle,
    AscAppConfig? ascAppConfig,
  }) async {
    final saved = await _persistenceService.saveDesign(
      design: state.board.background,
      thumbnailBytes: thumbnailBytes,
      name: name,
      existingId: override ? state.savedDesignId : null,
      folderId: _folderId,
      translationBundle: translationBundle,
      ascAppConfig: ascAppConfig ?? state.ascAppConfig,
      board: state.board,
    );

    emit(
      state.copyWith(
        savedDesignId: saved.id,
        savedDesignName: saved.name,
        // Adopt the persisted board so frame image paths point at the
        // design-managed copies rather than the originals.
        board: saved.board ?? state.board,
      ),
    );
  }

  /// Default name for a new board, derived from its first zone's format.
  String defaultName() => ScreenshotUtils.defaultDesignName(
    state.board.cropZones.firstOrNull?.displayType ??
        state.board.background.displayType,
  );

  /// Copies [file] into an app-managed directory so it survives cleanup of the
  /// original location (Downloads, temp, …).
  static Future<File> copyToStableStorage(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final stableDir = Directory('${appDir.path}/screenshot_images');
    if (!await stableDir.exists()) {
      await stableDir.create(recursive: true);
    }
    if (p.isWithin(stableDir.path, file.path)) return file;

    final ext = p.extension(file.path).isNotEmpty
        ? p.extension(file.path)
        : '.png';
    // A uuid rather than only a timestamp: importing several files at once
    // lands them in the same millisecond, and identical basenames from
    // different directories would otherwise overwrite each other.
    final stableFile = File(
      '${stableDir.path}/${_uuid.v4()}_'
      '${p.basenameWithoutExtension(file.path)}$ext',
    );
    return file.copy(stableFile.path);
  }
}
