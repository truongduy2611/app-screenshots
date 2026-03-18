import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:device_frame/device_frame.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'screenshot_editor_state.dart';

class ScreenshotEditorCubit extends Cubit<ScreenshotEditorState> {
  final ScreenshotPersistenceService _persistenceService;
  final SharedPreferences _prefs;
  final String? folderId;
  static const _gridSettingsKey = 'screenshot_editor_grid_settings';

  ScreenshotEditorCubit({
    String? imageUrl,
    File? imageFile,
    String? displayType,
    SavedDesign? initialDesign,
    ScreenshotPersistenceService? persistenceService,
    required SharedPreferences prefs,
    this.folderId,
    String? sourceFilePath,
  }) : _persistenceService =
           persistenceService ?? ScreenshotPersistenceService(),
       _prefs = prefs,
       super(
         ScreenshotEditorState(
           selectedImageUrl: imageUrl,
           selectedImageFile:
               imageFile ??
               (initialDesign?.imagePath != null
                   ? File(initialDesign!.imagePath!)
                   : null),
           design:
               initialDesign?.design ??
               ScreenshotDesign(
                 deviceFrame: _getDefaultDeviceFrame(displayType),
                 displayType: displayType,
               ),
           savedDesignId: initialDesign?.id,
           savedDesignName: initialDesign?.name,
           sourceFilePath: sourceFilePath,
         ),
       ) {
    _loadStoredGridSettings(initialDesign?.design.gridSettings);

    if (initialDesign == null && imageUrl != null) {
      _downloadImage(imageUrl);
    }
  }

  final List<ScreenshotDesign> _undoStack = [];
  final List<ScreenshotDesign> _redoStack = [];
  bool _isBatchEditing = false;

  /// Call before a continuous interaction (e.g. dragging a color picker or
  /// slider) to collapse all intermediate changes into a single undo entry.
  void beginBatchEdit() {
    if (!_isBatchEditing) {
      _isBatchEditing = true;
      // Save the current state once so undo returns here.
      _undoStack.add(state.design);
      if (_undoStack.length > 50) _undoStack.removeAt(0);
      _redoStack.clear();
    }
  }

  /// Call when the continuous interaction finishes.
  void endBatchEdit() {
    _isBatchEditing = false;
  }

  void _updateDesign(
    ScreenshotDesign newDesign, {
    Object? selectedOverlayId = _cleared,
  }) {
    if (state.design != newDesign) {
      if (!_isBatchEditing) {
        _undoStack.add(state.design);
        if (_undoStack.length > 50) {
          _undoStack.removeAt(0);
        }
        _redoStack.clear();
      }

      emit(
        state.copyWith(
          design: newDesign,
          selectedOverlayId: selectedOverlayId,
          canUndo: _undoStack.isNotEmpty,
          canRedo: false,
        ),
      );
    } else if (selectedOverlayId != _cleared) {
      emit(state.copyWith(selectedOverlayId: selectedOverlayId));
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(state.design);
      final prev = _undoStack.removeLast();
      emit(
        state.copyWith(
          design: prev,
          canUndo: _undoStack.isNotEmpty,
          canRedo: true,
        ),
      );
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(state.design);
      final next = _redoStack.removeLast();
      emit(
        state.copyWith(
          design: next,
          canUndo: true,
          canRedo: _redoStack.isNotEmpty,
        ),
      );
    }
  }

  Future<void> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/temp_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(response.bodyBytes);
        updateImageFile(file);
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to download image',
        tag: 'EditorCubit',
        error: e,
        stackTrace: st,
      );
    }
  }

  void updateImageFile(File file) {
    emit(state.copyWith(selectedImageFile: file, selectedImageUrl: null));
  }

  static DeviceInfo _getDefaultDeviceFrame(String? displayType) {
    return ScreenshotUtils.getDefaultDeviceFrame(displayType);
  }

  void toggleOrientation() {
    final currentOrientation = state.design.orientation;
    final newOrientation = currentOrientation == Orientation.portrait
        ? Orientation.landscape
        : Orientation.portrait;
    _updateDesign(state.design.copyWith(orientation: newOrientation));
  }

  void updateBackgroundColor(Color color) {
    _updateDesign(state.design.copyWith(backgroundColor: color));
  }

  void updateTransparentBackground(bool value) {
    _updateDesign(state.design.copyWith(transparentBackground: value));
  }

  void updateDeviceFrame(DeviceInfo? deviceFrame) {
    _updateDesign(
      state.design.copyWith(
        deviceFrame: deviceFrame,
        clearDeviceFrame: deviceFrame == null,
        cornerRadius: deviceFrame == null ? 80 : null,
      ),
    );
  }

  void updatePadding(double padding) {
    _updateDesign(state.design.copyWith(padding: padding));
  }

  void updateBackgroundGradient(Gradient? gradient) {
    _updateDesign(
      state.design.copyWith(
        backgroundGradient: gradient,
        clearGradient: gradient == null,
        // Clear mesh gradient when switching to a standard gradient
        clearMeshGradient: gradient != null,
      ),
    );
  }

  void updateMeshGradient(MeshGradientSettings? mesh) {
    _updateDesign(
      state.design.copyWith(
        meshGradient: mesh,
        clearMeshGradient: mesh == null,
        // Clear standard gradient when switching to mesh
        clearGradient: mesh != null,
      ),
    );
  }

  void updateImagePosition(Offset position) {
    _updateDesign(state.design.copyWith(imagePosition: position));
  }

  void updateFrameRotation(double rotation) {
    _updateDesign(state.design.copyWith(frameRotation: rotation));
  }

  void updateFrameRotationX(double rotation) {
    _updateDesign(state.design.copyWith(frameRotationX: rotation));
  }

  void updateFrameRotationY(double rotation) {
    _updateDesign(state.design.copyWith(frameRotationY: rotation));
  }

  void updateCornerRadius(double radius) {
    _updateDesign(state.design.copyWith(cornerRadius: radius));
  }

  void updateGridSettings(GridSettings gridSettings) {
    _updateDesign(state.design.copyWith(gridSettings: gridSettings));
    _saveGridSettings(gridSettings);
  }

  void updateDoodleSettings(DoodleSettings? doodleSettings) {
    if (doodleSettings == null) {
      _updateDesign(state.design.copyWith(clearDoodle: true));
    } else {
      _updateDesign(state.design.copyWith(doodleSettings: doodleSettings));
    }
  }

  void _loadStoredGridSettings(GridSettings? designGridSettings) {
    final storedJson = _prefs.getString(_gridSettingsKey);
    if (storedJson != null) {
      try {
        final settings = GridSettings.fromJson(jsonDecode(storedJson));
        emit(
          state.copyWith(design: state.design.copyWith(gridSettings: settings)),
        );
      } catch (e) {
        AppLogger.w('Failed to load stored grid settings', tag: 'EditorCubit');
      }
    }
  }

  Future<void> _saveGridSettings(GridSettings settings) async {
    await _prefs.setString(_gridSettingsKey, jsonEncode(settings.toJson()));
  }

  /// Snaps [rawPosition] (the true cursor-driven position) to nearby grid
  /// lines / center lines. Returns the display (top-left) position.
  ///
  /// When [elementSize] is provided, snapping is based on the **center** of
  /// the element rather than its top-left corner — matching Figma behavior.
  Offset snapOffset(Offset rawPosition, Size canvasSize, {Size? elementSize}) {
    final settings = state.design.gridSettings;
    if (!settings.snapToGrid && !settings.showCenterLines) {
      _emitSnapLines(null, null);
      return rawPosition;
    }

    // Convert to center coordinates when element size is known.
    final halfW = (elementSize?.width ?? 0) / 2;
    final halfH = (elementSize?.height ?? 0) / 2;
    final centerX = rawPosition.dx + halfW;
    final centerY = rawPosition.dy + halfH;

    double x = centerX;
    double y = centerY;
    double? snapLineX;
    double? snapLineY;

    const snapThreshold = 10.0;

    if (settings.snapToGrid) {
      final nearestX =
          (centerX / settings.gridSize).roundToDouble() * settings.gridSize;
      final nearestY =
          (centerY / settings.gridSize).roundToDouble() * settings.gridSize;

      if ((centerX - nearestX).abs() < snapThreshold) {
        x = nearestX;
        snapLineX = nearestX;
      }
      if ((centerY - nearestY).abs() < snapThreshold) {
        y = nearestY;
        snapLineY = nearestY;
      }
    }

    if (settings.showCenterLines) {
      final canvasCenterX = canvasSize.width / 2;
      final canvasCenterY = canvasSize.height / 2;

      if ((centerX - canvasCenterX).abs() < snapThreshold) {
        x = canvasCenterX;
        snapLineX = canvasCenterX;
      }
      if ((centerY - canvasCenterY).abs() < snapThreshold) {
        y = canvasCenterY;
        snapLineY = canvasCenterY;
      }
    }

    _emitSnapLines(snapLineX, snapLineY);

    // Convert back from center to top-left.
    return Offset(x - halfW, y - halfH);
  }

  /// Updates the visible snap guide lines without touching the design.
  void _emitSnapLines(double? x, double? y) {
    if (x != state.activeSnapX || y != state.activeSnapY) {
      emit(state.copyWith(activeSnapX: x, activeSnapY: y));
    }
  }

  /// Call on drag end to hide snap guide lines.
  void clearSnapLines() {
    if (state.activeSnapX != null || state.activeSnapY != null) {
      emit(state.copyWith(activeSnapX: null, activeSnapY: null));
    }
  }

  /// Adds a text overlay.
  bool addTextOverlay() {

    final overlay = TextOverlay(
      id: const Uuid().v4(),
      text: 'New Text',
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      position: const Offset(100, 100),
    );

    final overlays = List<TextOverlay>.from(state.design.overlays)
      ..add(overlay);
    emit(
      state.copyWith(
        design: state.design.copyWith(overlays: overlays),
        selectedOverlayId: overlay.id,
      ),
    );
    return true;
  }

  /// Adds an image overlay.
  bool addImageOverlay(File file) {
    if (state.design.imageOverlays.length >= 10) return false;

    final overlay = ImageOverlay(
      id: const Uuid().v4(),
      filePath: file.path,
      position: const Offset(100, 100),
      width: 150,
      height: 150,
    );

    final imageOverlays = List<ImageOverlay>.from(state.design.imageOverlays)
      ..add(overlay);
    _updateDesign(
      state.design.copyWith(imageOverlays: imageOverlays),
      selectedOverlayId: overlay.id,
    );
    return true;
  }

  void updateTextOverlay(String id, TextOverlay newOverlay) {
    final overlays = state.design.overlays.map((e) {
      return e.id == id ? newOverlay : e;
    }).toList();

    _updateDesign(
      state.design.copyWith(overlays: overlays),
      selectedOverlayId: id,
    );
  }

  void updateImageOverlay(String id, ImageOverlay newOverlay) {
    final overlays = state.design.imageOverlays.map((e) {
      return e.id == id ? newOverlay : e;
    }).toList();

    _updateDesign(
      state.design.copyWith(imageOverlays: overlays),
      selectedOverlayId: id,
    );
  }

  void selectOverlay(String? id) {
    emit(state.copyWith(selectedOverlayId: id));
  }

  void deleteTextOverlay(String id) {
    final overlays = state.design.overlays.where((e) => e.id != id).toList();
    _updateDesign(
      state.design.copyWith(overlays: overlays),
      selectedOverlayId: null,
    );
  }

  void deleteImageOverlay(String id) {
    final overlays = state.design.imageOverlays
        .where((e) => e.id != id)
        .toList();
    _updateDesign(
      state.design.copyWith(imageOverlays: overlays),
      selectedOverlayId: null,
    );
  }

  void addIconOverlay(
    int codePoint,
    String fontFamily,
    String fontPackage, {
    Color color = Colors.white,
    double fontWeight = 400,
  }) {
    final overlay = IconOverlay(
      id: const Uuid().v4(),
      codePoint: codePoint,
      fontFamily: fontFamily,
      fontPackage: fontPackage,
      position: const Offset(200, 200),
      size: 120,
      color: color,
      fontWeight: fontWeight,
    );

    final iconOverlays = List<IconOverlay>.from(state.design.iconOverlays)
      ..add(overlay);
    _updateDesign(
      state.design.copyWith(iconOverlays: iconOverlays),
      selectedOverlayId: overlay.id,
    );
  }

  void updateIconOverlay(String id, IconOverlay newOverlay) {
    final overlays = state.design.iconOverlays.map((e) {
      return e.id == id ? newOverlay : e;
    }).toList();

    _updateDesign(
      state.design.copyWith(iconOverlays: overlays),
      selectedOverlayId: id,
    );
  }

  void deleteIconOverlay(String id) {
    final overlays = state.design.iconOverlays
        .where((e) => e.id != id)
        .toList();
    _updateDesign(
      state.design.copyWith(iconOverlays: overlays),
      selectedOverlayId: null,
    );
  }

  void addMagnifierOverlay() {
    final overlay = MagnifierOverlay(
      id: const Uuid().v4(),
      position: const Offset(200, 200),
    );
    final magnifiers = List<MagnifierOverlay>.from(
      state.design.magnifierOverlays,
    )..add(overlay);
    _updateDesign(
      state.design.copyWith(magnifierOverlays: magnifiers),
      selectedOverlayId: overlay.id,
    );
  }

  void updateMagnifierOverlay(String id, MagnifierOverlay newOverlay) {
    final overlays = state.design.magnifierOverlays.map((e) {
      return e.id == id ? newOverlay : e;
    }).toList();
    _updateDesign(
      state.design.copyWith(magnifierOverlays: overlays),
      selectedOverlayId: id,
    );
  }

  void deleteMagnifierOverlay(String id) {
    final overlays = state.design.magnifierOverlays
        .where((e) => e.id != id)
        .toList();
    _updateDesign(
      state.design.copyWith(magnifierOverlays: overlays),
      selectedOverlayId: null,
    );
  }

  void deleteSelectedOverlay() {
    final id = state.selectedOverlayId;
    if (id == null) return;

    if (state.design.overlays.any((e) => e.id == id)) {
      deleteTextOverlay(id);
    } else if (state.design.imageOverlays.any((e) => e.id == id)) {
      deleteImageOverlay(id);
    } else if (state.design.iconOverlays.any((e) => e.id == id)) {
      deleteIconOverlay(id);
    } else if (state.design.magnifierOverlays.any((e) => e.id == id)) {
      deleteMagnifierOverlay(id);
    }
  }

  // ---------------------------------------------------------------------------
  // Overlay clipboard (copy / paste)
  // ---------------------------------------------------------------------------

  /// Clipboard for copied overlays — stored as the original overlay object.
  /// Kept as `Object?` since it can be any of the four overlay types.
  Object? _overlayClipboard;

  /// Returns true if an overlay was copied successfully.
  bool get hasOverlayClipboard => _overlayClipboard != null;

  /// Copies the currently selected overlay to the internal clipboard.
  /// Returns `true` when an overlay was actually copied.
  bool copySelectedOverlay() {
    final id = state.selectedOverlayId;
    if (id == null) return false;

    final text = state.design.overlays.cast<TextOverlay?>().firstWhere(
      (e) => e!.id == id,
      orElse: () => null,
    );
    if (text != null) { _overlayClipboard = text; return true; }

    final image = state.design.imageOverlays.cast<ImageOverlay?>().firstWhere(
      (e) => e!.id == id,
      orElse: () => null,
    );
    if (image != null) { _overlayClipboard = image; return true; }

    final icon = state.design.iconOverlays.cast<IconOverlay?>().firstWhere(
      (e) => e!.id == id,
      orElse: () => null,
    );
    if (icon != null) { _overlayClipboard = icon; return true; }

    final mag = state.design.magnifierOverlays.cast<MagnifierOverlay?>().firstWhere(
      (e) => e!.id == id,
      orElse: () => null,
    );
    if (mag != null) { _overlayClipboard = mag; return true; }

    return false;
  }

  /// Pastes the overlay from the internal clipboard into the current design
  /// with a new UUID and a slight position offset. Returns `true` on success.
  bool pasteOverlay() {
    final source = _overlayClipboard;
    if (source == null) return false;
    const offset = Offset(20, 20);
    final newId = const Uuid().v4();

    if (source is TextOverlay) {
      final copy = TextOverlay(
        id: newId,
        text: source.text,
        style: source.style,
        position: source.position + offset,
        googleFont: source.googleFont,
        rotation: source.rotation,
        textAlign: source.textAlign,
        decoration: source.decoration,
        decorationStyle: source.decorationStyle,
        decorationColor: source.decorationColor,
        backgroundColor: source.backgroundColor,
        borderColor: source.borderColor,
        borderWidth: source.borderWidth,
        borderRadius: source.borderRadius,
        horizontalPadding: source.horizontalPadding,
        verticalPadding: source.verticalPadding,
        scale: source.scale,
        width: source.width,
        zIndex: source.zIndex,
        behindFrame: source.behindFrame,
      );
      final overlays = List<TextOverlay>.from(state.design.overlays)..add(copy);
      _updateDesign(
        state.design.copyWith(overlays: overlays),
        selectedOverlayId: newId,
      );
      return true;
    }

    if (source is ImageOverlay) {
      final copy = ImageOverlay(
        id: newId,
        assetPath: source.assetPath,
        filePath: source.filePath,
        bytes: source.bytes,
        position: source.position + offset,
        scale: source.scale,
        rotation: source.rotation,
        width: source.width,
        height: source.height,
        zIndex: source.zIndex,
        opacity: source.opacity,
        cornerRadius: source.cornerRadius,
        flipHorizontal: source.flipHorizontal,
        flipVertical: source.flipVertical,
        shadowColor: source.shadowColor,
        shadowBlurRadius: source.shadowBlurRadius,
        shadowOffset: source.shadowOffset,
        behindFrame: source.behindFrame,
      );
      final overlays = List<ImageOverlay>.from(state.design.imageOverlays)..add(copy);
      _updateDesign(
        state.design.copyWith(imageOverlays: overlays),
        selectedOverlayId: newId,
      );
      return true;
    }

    if (source is IconOverlay) {
      final copy = IconOverlay(
        id: newId,
        codePoint: source.codePoint,
        fontFamily: source.fontFamily,
        fontPackage: source.fontPackage,
        color: source.color,
        fontWeight: source.fontWeight,
        size: source.size,
        position: source.position + offset,
        rotation: source.rotation,
        scale: source.scale,
        backgroundColor: source.backgroundColor,
        borderRadius: source.borderRadius,
        padding: source.padding,
        zIndex: source.zIndex,
        opacity: source.opacity,
        shadowColor: source.shadowColor,
        shadowBlurRadius: source.shadowBlurRadius,
        shadowOffset: source.shadowOffset,
        behindFrame: source.behindFrame,
      );
      final overlays = List<IconOverlay>.from(state.design.iconOverlays)..add(copy);
      _updateDesign(
        state.design.copyWith(iconOverlays: overlays),
        selectedOverlayId: newId,
      );
      return true;
    }

    if (source is MagnifierOverlay) {
      final copy = MagnifierOverlay(
        id: newId,
        position: source.position + offset,
        width: source.width,
        height: source.height,
        zoomLevel: source.zoomLevel,
        sourceOffset: source.sourceOffset,
        borderWidth: source.borderWidth,
        borderColor: source.borderColor,
        opacity: source.opacity,
        zIndex: source.zIndex,
        behindFrame: source.behindFrame,
        shadowColor: source.shadowColor,
        shadowBlurRadius: source.shadowBlurRadius,
        shape: source.shape,
        cornerRadius: source.cornerRadius,
        starPoints: source.starPoints,
      );
      final overlays = List<MagnifierOverlay>.from(state.design.magnifierOverlays)..add(copy);
      _updateDesign(
        state.design.copyWith(magnifierOverlays: overlays),
        selectedOverlayId: newId,
      );
      return true;
    }

    return false;
  }

  /// Moves the currently selected overlay by [delta] pixels.
  /// When no overlay is selected, moves the main image/device frame instead.
  void moveSelectedOverlay(Offset delta) {
    final id = state.selectedOverlayId;
    AppLogger.d(
      'moveSelectedOverlay: id=$id, delta=$delta, imagePos=${state.design.imagePosition}',
      tag: 'EditorCubit',
    );

    // No overlay selected — move the main image position
    if (id == null) {
      final newPos = state.design.imagePosition + delta;
      AppLogger.d(
        'moveSelectedOverlay: Moving image to $newPos',
        tag: 'EditorCubit',
      );
      updateImagePosition(newPos);
      return;
    }

    // Text overlay
    final textMatch = state.design.overlays
        .where((e) => e.id == id)
        .firstOrNull;
    if (textMatch != null) {
      updateTextOverlay(
        id,
        textMatch.copyWith(position: textMatch.position + delta),
      );
      return;
    }

    // Image overlay
    final imageMatch = state.design.imageOverlays
        .where((e) => e.id == id)
        .firstOrNull;
    if (imageMatch != null) {
      updateImageOverlay(
        id,
        imageMatch.copyWith(position: imageMatch.position + delta),
      );
      return;
    }

    // Icon overlay
    final iconMatch = state.design.iconOverlays
        .where((e) => e.id == id)
        .firstOrNull;
    if (iconMatch != null) {
      updateIconOverlay(
        id,
        iconMatch.copyWith(position: iconMatch.position + delta),
      );
      return;
    }

    // Magnifier overlay
    final magMatch = state.design.magnifierOverlays
        .where((e) => e.id == id)
        .firstOrNull;
    if (magMatch != null) {
      updateMagnifierOverlay(
        id,
        magMatch.copyWith(position: magMatch.position + delta),
      );
    }
  }

  void bringSelectedOverlayForward() {
    final id = state.selectedOverlayId;
    if (id == null) return;
    _updateZIndex(id, 1);
  }

  void sendSelectedOverlayBackward() {
    final id = state.selectedOverlayId;
    if (id == null) return;
    _updateZIndex(id, -1);
  }

  void _updateZIndex(String id, int delta) {
    // Gather all overlay ids + zIndexes in one flat list.
    final entries = <({String id, String type, int zIndex})>[
      ...state.design.overlays.map(
        (e) => (id: e.id, type: 'text', zIndex: e.zIndex),
      ),
      ...state.design.imageOverlays.map(
        (e) => (id: e.id, type: 'image', zIndex: e.zIndex),
      ),
      ...state.design.iconOverlays.map(
        (e) => (id: e.id, type: 'icon', zIndex: e.zIndex),
      ),
      ...state.design.magnifierOverlays.map(
        (e) => (id: e.id, type: 'magnifier', zIndex: e.zIndex),
      ),
    ];

    if (entries.length < 2) return;

    // Sort ascending by zIndex. Dart sort is stable for ties.
    entries.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // Find the target entry.
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    // Determine swap partner.
    final swapIdx = idx + delta; // delta is +1 (forward) or -1 (backward)
    if (swapIdx < 0 || swapIdx >= entries.length) return;

    final target = entries[idx];
    final neighbor = entries[swapIdx];

    // Swap their zIndex values. If they're equal, nudge them apart.
    int newTargetZ = neighbor.zIndex;
    int newNeighborZ = target.zIndex;
    if (newTargetZ == newNeighborZ) {
      if (delta > 0) {
        newTargetZ = newNeighborZ + 1;
      } else {
        newTargetZ = newNeighborZ - 1;
      }
    }

    // Build a map of id -> new zIndex.
    final zMap = {target.id: newTargetZ, neighbor.id: newNeighborZ};

    // Apply both z-index changes atomically to a single new design.
    final newTexts = state.design.overlays.map((e) {
      final z = zMap[e.id];
      return z != null ? e.copyWith(zIndex: z) : e;
    }).toList();

    final newImages = state.design.imageOverlays.map((e) {
      final z = zMap[e.id];
      return z != null ? e.copyWith(zIndex: z) : e;
    }).toList();

    final newIcons = state.design.iconOverlays.map((e) {
      final z = zMap[e.id];
      return z != null ? e.copyWith(zIndex: z) : e;
    }).toList();

    final newMagnifiers = state.design.magnifierOverlays.map((e) {
      final z = zMap[e.id];
      return z != null ? e.copyWith(zIndex: z) : e;
    }).toList();

    _updateDesign(
      state.design.copyWith(
        overlays: newTexts,
        imageOverlays: newImages,
        iconOverlays: newIcons,
        magnifierOverlays: newMagnifiers,
      ),
      selectedOverlayId: id,
    );
  }

  // Persistence Logic

  Future<void> saveDesign(
    String name,
    Uint8List thumbnailBytes, {
    bool override = false,
  }) async {
    final savedDesign = await _persistenceService.saveDesign(
      design: state.design,
      thumbnailBytes: thumbnailBytes,
      name: name,
      existingId: override ? state.savedDesignId : null,
      originalImageFile: state.selectedImageFile,
      folderId: folderId,
    );
    emit(
      state.copyWith(
        savedDesignId: savedDesign.id,
        savedDesignName: savedDesign.name,
      ),
    );
  }

  void loadDesignIntoEditor(SavedDesign savedDesign) {
    _undoStack.clear();
    _redoStack.clear();
    emit(
      state.copyWith(
        design: savedDesign.design,
        selectedOverlayId: null,
        savedDesignId: savedDesign.id,
        savedDesignName: savedDesign.name,
        canUndo: false,
        canRedo: false,
      ),
    );
  }

  /// Loads a design + optional image into the editor.
  /// Used by the multi-screenshot page to sync the active slot.
  void loadDesignForMultiMode(ScreenshotDesign design, {File? imageFile}) {
    _undoStack.clear();
    _redoStack.clear();
    emit(
      state.copyWith(
        design: design,
        selectedImageFile: imageFile,
        selectedOverlayId: null,
        canUndo: false,
        canRedo: false,
      ),
    );
  }

  /// Applies a preset template to the single-screenshot editor.
  /// Uses only the first design from the preset, injecting the current
  /// device frame and display type.
  void applyPreset(ScreenshotPreset preset) {
    final firstDesign = preset.designs.first;
    final currentDesign = state.design;
    _updateDesign(
      firstDesign.copyWith(
        deviceFrame: currentDesign.deviceFrame,
        displayType: currentDesign.displayType,
        orientation: currentDesign.orientation,
      ),
      selectedOverlayId: null,
    );
  }

  /// Replaces the current design wholesale (used by the AI assistant).
  /// Preserves device frame, display type, and orientation from the current
  /// design so only visual properties change.
  void replaceDesign(ScreenshotDesign newDesign) {
    final current = state.design;
    _updateDesign(
      newDesign.copyWith(
        deviceFrame: current.deviceFrame,
        displayType: current.displayType,
        orientation: current.orientation,
      ),
      selectedOverlayId: null,
    );
  }

  void deselectOverlay() {
    emit(state.copyWith(selectedOverlayId: null));
  }

  // ---------------------------------------------------------------------------
  // Grid hide/restore for export
  // ---------------------------------------------------------------------------

  GridSettings? _gridSettingsBeforeCapture;

  /// Temporarily hides grid and center lines for image capture/export.
  /// Also deselects any overlay to hide the selection border.
  /// Call [restoreGridAfterCapture] after the capture completes.
  void hideGridForCapture() {
    // Deselect overlay so selection border is not captured
    deselectOverlay();

    final current = state.design.gridSettings;
    if (current.showGrid || current.showCenterLines) {
      _gridSettingsBeforeCapture = current;
      emit(
        state.copyWith(
          design: state.design.copyWith(
            gridSettings: current.copyWith(
              showGrid: false,
              showCenterLines: false,
            ),
          ),
        ),
      );
    }
  }

  /// Restores grid settings that were hidden by [hideGridForCapture].
  void restoreGridAfterCapture() {
    if (_gridSettingsBeforeCapture != null) {
      emit(
        state.copyWith(
          design: state.design.copyWith(
            gridSettings: _gridSettingsBeforeCapture!,
          ),
        ),
      );
      _gridSettingsBeforeCapture = null;
    }
  }
}
