import 'dart:async';
import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/core/services/icloud_sync_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'screenshot_library_state.dart';

class ScreenshotLibraryCubit extends Cubit<ScreenshotLibraryState> {
  final ScreenshotPersistenceService _persistenceService;
  final DesignFileService _designFileService;
  final ICloudSyncService? _syncService;
  String? _currentFolderId;
  StreamSubscription<void>? _remoteChangeSub;

  static const _tag = 'LibraryCubit';

  ScreenshotLibraryCubit({
    ScreenshotPersistenceService? persistenceService,
    DesignFileService? designFileService,
    ICloudSyncService? syncService,
  }) : _persistenceService =
           persistenceService ?? ScreenshotPersistenceService(),
       _designFileService = designFileService ?? DesignFileService(),
       _syncService = syncService,
       super(ScreenshotLibraryInitial()) {
    // Listen for remote iCloud changes and auto-refresh (without flash).
    _remoteChangeSub = _syncService?.onRemoteChange.listen((_) {
      _silentRefresh();
    });
  }

  String? get currentFolderId => _currentFolderId;

  /// Total number of saved designs across all folders.
  int get totalDesignCount {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded) {
      return currentState.allDesigns.length;
    }
    return 0;
  }

  /// Whether the user can save a new design (unlimited).
  bool get canSaveNewDesign => true;

  /// How many save slots remain (unlimited = -1).
  int get remainingSaveSlots => -1;

  /// Number of saved multi-screenshot designs.
  int get multiDesignCount {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded) {
      return currentState.allDesigns.where((d) => d.isMulti).length;
    }
    return 0;
  }

  /// Whether the user can create a new multi-screenshot set (unlimited).
  bool get canCreateMultiScreenshot => true;

  Future<void> loadDesigns() async {
    emit(ScreenshotLibraryLoading());
    try {
      final designs = await _persistenceService.getAllDesigns();
      final folders = await _persistenceService.getAllFolders();

      final filteredDesigns = designs
          .where((d) => d.folderId == _currentFolderId)
          .toList();
      final filteredFolders = folders
          .where((f) => f.parentId == _currentFolderId)
          .toList();

      emit(
        ScreenshotLibraryLoaded(
          designs: filteredDesigns,
          folders: filteredFolders,
          allDesigns: designs,
          allFolders: folders,
          currentFolderId: _currentFolderId,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to load designs',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      emit(ScreenshotLibraryError(message: e.toString()));
    }
  }

  /// Silent refresh: reloads data without emitting Loading state.
  /// Only emits if data actually changed, preventing UI flash.
  Future<void> _silentRefresh() async {
    try {
      final designs = await _persistenceService.getAllDesigns();
      final folders = await _persistenceService.getAllFolders();

      // Compare with current state — skip emit if nothing changed.
      final currentState = state;
      if (currentState is ScreenshotLibraryLoaded) {
        final sameDesigns = _designListEquals(currentState.allDesigns, designs);
        final sameFolders = _folderListEquals(currentState.allFolders, folders);
        if (sameDesigns && sameFolders) {
          return;
        }
      }

      final filteredDesigns = designs
          .where((d) => d.folderId == _currentFolderId)
          .toList();
      final filteredFolders = folders
          .where((f) => f.parentId == _currentFolderId)
          .toList();

      // Clear image cache only when we actually have new data
      PaintingBinding.instance.imageCache.clear();

      AppLogger.d(
        'Silent refresh — data changed, updating UI '
        '(${designs.length} designs, ${folders.length} folders)',
        tag: _tag,
      );
      emit(
        ScreenshotLibraryLoaded(
          designs: filteredDesigns,
          folders: filteredFolders,
          allDesigns: designs,
          allFolders: folders,
          currentFolderId: _currentFolderId,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Silent refresh failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  bool _designListEquals(List<SavedDesign> a, List<SavedDesign> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].name != b[i].name ||
          a[i].folderId != b[i].folderId ||
          a[i].lastModified != b[i].lastModified) {
        return false;
      }
    }
    return true;
  }

  bool _folderListEquals(List<DesignFolder> a, List<DesignFolder> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name) return false;
    }
    return true;
  }

  Future<void> createFolder(String name) async {
    try {
      await _persistenceService.createFolder(name, parentId: _currentFolderId);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to create folder',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _persistenceService.deleteFolder(id);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete folder',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> deleteFolderWithDesigns(String id) async {
    try {
      await _persistenceService.deleteFolderWithDesigns(id);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete folder with designs',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    try {
      await _persistenceService.renameFolder(id, newName);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to rename folder',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> deleteDesign(String id) async {
    try {
      await _persistenceService.deleteDesign(id);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> renameDesign(String id, String newName) async {
    try {
      await _persistenceService.renameDesign(id, newName);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to rename design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> moveDesignToFolder(String designId, String? folderId) async {
    try {
      await _persistenceService.moveDesignToFolder(designId, folderId);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to move design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> cloneDesignWithFormat(
    SavedDesign originalSavedDesign,
    String newDisplayType,
  ) async {
    // Check limit
    if (!canSaveNewDesign) {
      AppLogger.w('Clone blocked — free design limit reached', tag: _tag);
      return;
    }

    // Strip the "multi:" prefix if present — it's only a UI routing signal,
    // not a valid display type key.
    final cleanDisplayType = newDisplayType.startsWith('multi:')
        ? newDisplayType.substring(6)
        : newDisplayType;

    try {
      final originalDesign = originalSavedDesign.design;
      final clonedDesign = ScreenshotUtils.cloneDesignToFormat(
        originalDesign,
        cleanDisplayType,
      );

      List<ScreenshotDesign>? clonedMultiDesigns;
      if (originalSavedDesign.isMulti) {
        clonedMultiDesigns = originalSavedDesign.multiDesigns!
            .map(
              (d) => ScreenshotUtils.cloneDesignToFormat(d, cleanDisplayType),
            )
            .toList();
      }

      final newName = '${originalSavedDesign.name} (Cloned)';

      // Get thumbnail bytes from original
      Uint8List thumbnailBytes = Uint8List(0);
      if (originalSavedDesign.thumbnailPath.isNotEmpty) {
        final thumbFile = File(originalSavedDesign.thumbnailPath);
        if (await thumbFile.exists()) {
          thumbnailBytes = await thumbFile.readAsBytes();
        }
      }

      File? originalImageFile;
      if (originalSavedDesign.imagePath != null) {
        originalImageFile = File(originalSavedDesign.imagePath!);
      }

      List<File?>? imageFiles;
      if (originalSavedDesign.imagePaths != null) {
        imageFiles = originalSavedDesign.imagePaths!
            .map((p) => p != null ? File(p) : null)
            .toList();
      }

      await _persistenceService.saveDesign(
        design: clonedDesign,
        thumbnailBytes: thumbnailBytes,
        name: newName,
        folderId: originalSavedDesign.folderId,
        originalImageFile: originalImageFile,
        multiDesigns: clonedMultiDesigns,
        imageFiles: imageFiles,
        translationBundle: originalSavedDesign.translationBundle,
        ascAppConfig: originalSavedDesign.ascAppConfig,
      );

      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to clone design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> openFolder(String folderId) async {
    _currentFolderId = folderId;
    _refilterCurrentData();
  }

  Future<void> navigateBack() async {
    // Navigate to the parent folder instead of always going to root.
    if (_currentFolderId != null) {
      final currentState = state;
      if (currentState is ScreenshotLibraryLoaded) {
        final currentFolder = currentState.allFolders
            .where((f) => f.id == _currentFolderId)
            .firstOrNull;
        _currentFolderId = currentFolder?.parentId;
      } else {
        _currentFolderId = null;
      }
    }
    _refilterCurrentData();
  }

  /// Re-filter already-loaded data for the current folder without emitting
  /// a loading state. Falls back to a full reload if data isn't loaded yet.
  void _refilterCurrentData() {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded) {
      final filteredDesigns = currentState.allDesigns
          .where((d) => d.folderId == _currentFolderId)
          .toList();
      final filteredFolders = currentState.allFolders
          .where((f) => f.parentId == _currentFolderId)
          .toList();
      emit(
        ScreenshotLibraryLoaded(
          designs: filteredDesigns,
          folders: filteredFolders,
          allDesigns: currentState.allDesigns,
          allFolders: currentState.allFolders,
          currentFolderId: _currentFolderId,
        ),
      );
    } else {
      loadDesigns();
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded) {
      emit(
        ScreenshotLibraryLoaded(
          designs: currentState.designs,
          folders: currentState.folders,
          allDesigns: currentState.allDesigns,
          allFolders: currentState.allFolders,
          currentFolderId: currentState.currentFolderId,
          searchQuery: query,
        ),
      );
    }
  }

  Future<void> moveFolderToFolder(String folderId, String? parentId) async {
    try {
      await _persistenceService.moveFolderToFolder(folderId, parentId);
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to move folder',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Export / Import
  // ---------------------------------------------------------------------------

  /// Exports a single design to a `.appshots` file.
  /// Returns the exported [File], or `null` on error.
  Future<File?> exportDesign(SavedDesign design) async {
    try {
      return await _designFileService.createExportFile(design);
    } catch (e, st) {
      AppLogger.error(
        'Failed to export design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Imports a `.appshots` file and returns the parsed [SavedDesign].
  /// Does **not** persist it — the caller should save it to the library.
  Future<SavedDesign?> importDesignFromFile(File file) async {
    try {
      AppLogger.d('importDesignFromFile: ${file.path}', tag: _tag);
      final result = await _designFileService.parseExportFile(file);
      AppLogger.d(
        'parseExportFile result: ${result?.name ?? "null"}',
        tag: _tag,
      );
      return result;
    } catch (e, st) {
      AppLogger.error(
        'Failed to import design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Imports a `.appshots` file and immediately saves it to the library.
  ///
  /// Used when a file is opened from Finder/Files (auto-import flow).
  Future<SavedDesign?> importAndSaveDesign(File file) async {
    AppLogger.d('importAndSaveDesign called: ${file.path}', tag: _tag);

    // Enforce design limit for free users.
    if (!canSaveNewDesign) {
      AppLogger.w('Import blocked — free design limit reached', tag: _tag);
      return null;
    }

    final imported = await importDesignFromFile(file);
    if (imported == null) {
      AppLogger.w('Import returned null — aborting save', tag: _tag);
      return null;
    }

    try {
      AppLogger.d('Saving imported design: ${imported.name}', tag: _tag);

      // Read thumbnail bytes from the extracted file
      Uint8List thumbnailBytes;
      if (imported.thumbnailPath.isNotEmpty) {
        final thumbFile = File(imported.thumbnailPath);
        if (await thumbFile.exists()) {
          thumbnailBytes = await thumbFile.readAsBytes();
        } else {
          thumbnailBytes = Uint8List(0);
        }
      } else {
        thumbnailBytes = Uint8List(0);
      }

      // Convert extracted image overlay files to File objects
      File? originalImageFile;
      if (imported.imagePath != null) {
        final imgFile = File(imported.imagePath!);
        if (await imgFile.exists()) {
          originalImageFile = imgFile;
        }
      }

      // Convert multi-canvas image paths to File objects
      List<File?>? imageFiles;
      if (imported.imagePaths != null) {
        imageFiles = [];
        for (final path in imported.imagePaths!) {
          if (path != null) {
            final f = File(path);
            imageFiles.add(await f.exists() ? f : null);
          } else {
            imageFiles.add(null);
          }
        }
      }

      final saved = await _persistenceService.saveDesign(
        design: imported.design,
        thumbnailBytes: thumbnailBytes,
        name: imported.name,
        folderId: _currentFolderId,
        originalImageFile: originalImageFile,
        multiDesigns: imported.multiDesigns,
        imageFiles: imageFiles,
      );
      AppLogger.i('Design saved: ${saved.id}', tag: _tag);
      await loadDesigns();
      return saved;
    } catch (e, st) {
      AppLogger.error(
        'Failed to save imported design',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Exports all designs in a folder to a single `.appshots` file.
  Future<File?> exportFolder(String folderId, String folderName) async {
    try {
      final currentState = state;
      if (currentState is! ScreenshotLibraryLoaded) return null;

      final designs = currentState.allDesigns
          .where((d) => d.folderId == folderId)
          .toList();

      if (designs.isEmpty) return null;

      return await _designFileService.createExportFileForMultiple(
        designs,
        folderName: folderName,
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to export folder',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // --- Selection & Batch Operations ---

  void toggleSelectionMode() {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded) {
      if (currentState.isSelectionMode) {
        emit(
          currentState.copyWith(
            isSelectionMode: false,
            selectedDesignIds: const {},
            selectedFolderIds: const {},
          ),
        );
      } else {
        emit(currentState.copyWith(isSelectionMode: true));
      }
    }
  }

  void toggleDesignSelection(String id) {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded &&
        currentState.isSelectionMode) {
      final newSelection = Set<String>.from(currentState.selectedDesignIds);
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
      emit(currentState.copyWith(selectedDesignIds: newSelection));
    }
  }

  void toggleFolderSelection(String id) {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded &&
        currentState.isSelectionMode) {
      final newSelection = Set<String>.from(currentState.selectedFolderIds);
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
      emit(currentState.copyWith(selectedFolderIds: newSelection));
    }
  }

  void selectAll() {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded &&
        currentState.isSelectionMode) {
      emit(
        currentState.copyWith(
          selectedDesignIds: currentState.filteredDesigns
              .map((d) => d.id)
              .toSet(),
          selectedFolderIds: currentState.filteredFolders
              .map((f) => f.id)
              .toSet(),
        ),
      );
    }
  }

  void clearSelection() {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded) {
      emit(
        currentState.copyWith(
          selectedDesignIds: const {},
          selectedFolderIds: const {},
          isSelectionMode: false,
        ),
      );
    }
  }

  Future<void> deleteSelected() async {
    final currentState = state;
    if (currentState is ScreenshotLibraryLoaded &&
        currentState.isSelectionMode) {
      final selectedDesigns = currentState.selectedDesignIds.toList();
      final selectedFolders = currentState.selectedFolderIds.toList();

      if (selectedDesigns.isEmpty && selectedFolders.isEmpty) {
        toggleSelectionMode();
        return;
      }

      emit(ScreenshotLibraryLoading());

      try {
        for (final id in selectedDesigns) {
          await _persistenceService.deleteDesign(id);
        }
        for (final id in selectedFolders) {
          await _persistenceService.deleteFolderWithDesigns(id);
        }
        await loadDesigns(); // Reloads and resets selection because loadDesigns emits a fresh Loaded state
      } catch (e, st) {
        AppLogger.error(
          'Failed to delete selected items',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
        emit(ScreenshotLibraryError(message: e.toString()));
      }
    }
  }

  Future<void> moveSelectedToFolder(String? targetFolderId) async {
    final currentState = state;
    if (currentState is! ScreenshotLibraryLoaded ||
        !currentState.isSelectionMode) {
      return;
    }

    final selectedDesigns = currentState.selectedDesignIds.toList();
    final selectedFolders = currentState.selectedFolderIds.toList();

    if (selectedDesigns.isEmpty && selectedFolders.isEmpty) {
      toggleSelectionMode();
      return;
    }

    emit(ScreenshotLibraryLoading());

    try {
      for (final id in selectedDesigns) {
        await _persistenceService.moveDesignToFolder(id, targetFolderId);
      }
      for (final id in selectedFolders) {
        // Prevent moving a folder into itself
        if (id != targetFolderId) {
          await _persistenceService.moveFolderToFolder(id, targetFolderId);
        }
      }
      await loadDesigns();
    } catch (e, st) {
      AppLogger.error(
        'Failed to move selected items',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      emit(ScreenshotLibraryError(message: e.toString()));
    }
  }

  Future<File?> exportSelected() async {
    final currentState = state;
    if (currentState is! ScreenshotLibraryLoaded ||
        !currentState.isSelectionMode) {
      return null;
    }

    final selectedDesignsIds = currentState.selectedDesignIds.toList();
    // Exclude folders for now, or just export the selected designs.
    if (selectedDesignsIds.isEmpty) return null;

    try {
      final designsToExport = currentState.allDesigns
          .where((d) => selectedDesignsIds.contains(d.id))
          .toList();

      if (designsToExport.isEmpty) return null;

      final exportName = designsToExport.length == 1
          ? designsToExport.first.name
          : 'Export_${designsToExport.length}_Designs';

      return await _designFileService.createExportFileForMultiple(
        designsToExport,
        folderName: exportName,
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to export selected items',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<void> close() {
    _remoteChangeSub?.cancel();
    return super.close();
  }
}
