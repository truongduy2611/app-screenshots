import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';

import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:device_frame/device_frame.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'multi_screenshot_state.dart';

class MultiScreenshotCubit extends Cubit<MultiScreenshotState> {
  final String? displayType;
  final String? _folderId;
  final ScreenshotPersistenceService _persistenceService;

  MultiScreenshotCubit({
    this.displayType,
    String? folderId,
    ScreenshotPersistenceService? persistenceService,
    SavedDesign? initialSavedDesign,
    String? sourceFilePath,
  }) : _folderId = folderId,
       _persistenceService =
           persistenceService ?? ScreenshotPersistenceService(),
       super(MultiScreenshotState(sourceFilePath: sourceFilePath)) {
    if (initialSavedDesign != null && initialSavedDesign.isMulti) {
      _loadFromSavedDesign(initialSavedDesign);
    } else {
      addDesign();
    }
  }

  void _loadFromSavedDesign(SavedDesign saved) {
    final designs = saved.multiDesigns;
    if (designs == null || designs.isEmpty) return;
    final imageFiles = <File?>[];
    if (saved.imagePaths != null) {
      for (final path in saved.imagePaths!) {
        if (path != null && File(path).existsSync()) {
          imageFiles.add(File(path));
        } else {
          imageFiles.add(null);
        }
      }
    } else {
      imageFiles.addAll(List.filled(designs.length, null));
    }

    emit(
      state.copyWith(
        designs: designs,
        imageFiles: imageFiles,
        activeIndex: 0,
        savedDesignId: saved.id,
        savedDesignName: saved.name,
        ascAppConfig: saved.ascAppConfig,
      ),
    );
  }

  /// Update the saved ASC app config. Pass `null` to clear it.
  void setAscAppConfig(AscAppConfig? config) {
    if (config == null) {
      emit(state.copyWith(clearAscAppConfig: true));
    } else {
      emit(state.copyWith(ascAppConfig: config));
    }
  }

  // ---------------------------------------------------------------------------
  // Slot management
  // ---------------------------------------------------------------------------

  /// Add a new design at the end, copying the previous one's styling. Max 10.
  void addDesign() {
    if (!state.canAddMore) return;

    final ScreenshotDesign newDesign;
    if (state.designs.isNotEmpty) {
      newDesign = state.designs.last.copyWith(
        deviceFrame: _getDefaultDeviceFrame(displayType),
        displayType: displayType,
      );
    } else {
      newDesign = ScreenshotDesign(
        deviceFrame: _getDefaultDeviceFrame(displayType),
        displayType: displayType,
      );
    }

    emit(
      state.copyWith(
        designs: [...state.designs, newDesign],
        imageFiles: [...state.imageFiles, null],
        activeIndex: state.designs.length, // new last item
      ),
    );
  }

  /// Remove a design at the given index.
  void removeDesign(int index) {
    if (state.designs.length <= 1) return;
    if (index < 0 || index >= state.designs.length) return;

    final designs = List<ScreenshotDesign>.from(state.designs)..removeAt(index);
    final files = List<File?>.from(state.imageFiles)..removeAt(index);

    int newActive = state.activeIndex;
    if (index < state.activeIndex) {
      newActive--;
    } else if (newActive >= designs.length) {
      newActive = designs.length - 1;
    }

    emit(
      state.copyWith(
        designs: designs,
        imageFiles: files,
        activeIndex: newActive,
      ),
    );
  }

  /// Duplicate a design at the given index.
  void duplicateDesign(int index) {
    if (!state.canAddMore) return;
    if (index < 0 || index >= state.designs.length) return;

    final designs = List<ScreenshotDesign>.from(state.designs)
      ..insert(index + 1, state.designs[index]);
    final files = List<File?>.from(state.imageFiles)
      ..insert(index + 1, state.imageFiles[index]);

    emit(
      state.copyWith(
        designs: designs,
        imageFiles: files,
        activeIndex: index + 1,
      ),
    );
  }

  /// Switch the active design being edited.
  void setActiveIndex(int index) {
    if (index < 0 || index >= state.designs.length) return;
    if (index == state.activeIndex) return;
    emit(state.copyWith(activeIndex: index));
  }

  /// Reorder designs.
  void reorderDesigns(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final designs = List<ScreenshotDesign>.from(state.designs);
    final files = List<File?>.from(state.imageFiles);

    final design = designs.removeAt(oldIndex);
    final file = files.removeAt(oldIndex);

    if (newIndex > oldIndex) newIndex--;
    designs.insert(newIndex, design);
    files.insert(newIndex, file);

    int newActive = state.activeIndex;
    if (state.activeIndex == oldIndex) {
      newActive = newIndex;
    } else if (oldIndex < state.activeIndex && newIndex >= state.activeIndex) {
      newActive--;
    } else if (oldIndex > state.activeIndex && newIndex <= state.activeIndex) {
      newActive++;
    }

    emit(
      state.copyWith(
        designs: designs,
        imageFiles: files,
        activeIndex: newActive,
      ),
    );
  }

  void moveDesignLeft(int index) {
    if (index <= 0 || index >= state.designs.length) return;
    reorderDesigns(index, index - 1);
  }

  void moveDesignRight(int index) {
    if (index < 0 || index >= state.designs.length - 1) return;
    reorderDesigns(index, index + 2);
  }

  // ---------------------------------------------------------------------------
  // Active design editing
  // ---------------------------------------------------------------------------

  void updateActiveDesign(ScreenshotDesign design) {
    final designs = List<ScreenshotDesign>.from(state.designs);
    designs[state.activeIndex] = design;
    emit(state.copyWith(designs: designs));
  }

  Future<void> updateActiveImage(File file) async {
    final stable = await _copyToStableStorage(file);
    final files = List<File?>.from(state.imageFiles);
    files[state.activeIndex] = stable;
    emit(state.copyWith(imageFiles: files));
  }

  /// Synchronous image setter for the sync-back path where the file
  /// is already in stable storage (e.g. previously copied via drag-drop
  /// or paste).
  void syncActiveImage(File file) {
    final files = List<File?>.from(state.imageFiles);
    files[state.activeIndex] = file;
    emit(state.copyWith(imageFiles: files));
  }

  Future<void> updateImageForSlot(int index, File file) async {
    if (index < 0 || index >= state.designs.length) return;
    final stable = await _copyToStableStorage(file);
    final files = List<File?>.from(state.imageFiles);
    files[index] = stable;
    emit(state.copyWith(imageFiles: files));
  }

  /// Replace the active slot's image with the first file, then distribute
  /// the remaining files (if any) to other empty slots or new slots.
  Future<void> replaceActiveImageAndImport(List<File> files) async {
    if (files.isEmpty) return;

    // Copy all files to stable storage first to prevent loss.
    final stableFiles = <File>[];
    for (final f in files) {
      stableFiles.add(await _copyToStableStorage(f));
    }

    // Force the first file into the active slot.
    final firstFile = stableFiles.first;
    final remainingFiles = stableFiles.skip(1).toList();

    final designs = List<ScreenshotDesign>.from(state.designs);
    final images = List<File?>.from(state.imageFiles);

    images[state.activeIndex] = firstFile;

    if (remainingFiles.isEmpty) {
      emit(state.copyWith(imageFiles: images));
      return;
    }

    // We have more files to distribute. Let's find empty slots or make new ones.
    int firstAssigned = state.activeIndex;
    final remaining = List<File>.from(remainingFiles);

    void assign(int index, File file) {
      images[index] = file;
      remaining.remove(file);
    }

    // Pass 1: fill empty slots starting from activeIndex (wrap around)
    for (
      int offset = 1;
      offset < designs.length && remaining.isNotEmpty;
      offset++
    ) {
      final i = (state.activeIndex + offset) % designs.length;
      if (images[i] == null) {
        assign(i, remaining.first);
      }
    }

    // Pass 2: auto-add new designs for remaining files (up to max 10)
    while (remaining.isNotEmpty && designs.length < 10) {
      final newDesign = designs.last.copyWith(
        deviceFrame: _getDefaultDeviceFrame(displayType),
        displayType: displayType,
      );
      designs.add(newDesign);
      images.add(null);
      assign(designs.length - 1, remaining.first);
    }

    // Pass 3: if still remaining, overwrite from activeIndex forward (skipping activeIndex itself)
    for (
      int offset = 1;
      offset < designs.length && remaining.isNotEmpty;
      offset++
    ) {
      final i = (state.activeIndex + offset) % designs.length;
      assign(i, remaining.first);
    }

    emit(
      state.copyWith(
        designs: designs,
        imageFiles: images,
        activeIndex: firstAssigned,
      ),
    );
  }

  void updateDesignForSlot(int index, ScreenshotDesign design) {
    if (index < 0 || index >= state.designs.length) return;
    final designs = List<ScreenshotDesign>.from(state.designs);
    designs[index] = design;
    emit(state.copyWith(designs: designs));
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Save all designs to the library with a thumbnail.
  Future<void> saveDesign(
    String name,
    Uint8List thumbnailBytes, {
    bool override = false,
    TranslationBundle? translationBundle,
    AscAppConfig? ascAppConfig,
  }) async {
    final savedDesign = await _persistenceService.saveDesign(
      design: state.designs.first,
      thumbnailBytes: thumbnailBytes,
      name: name,
      existingId: override ? state.savedDesignId : null,
      folderId: _folderId,
      multiDesigns: state.designs,
      imageFiles: state.imageFiles,
      translationBundle: translationBundle,
      ascAppConfig: ascAppConfig,
    );
    emit(
      state.copyWith(
        savedDesignId: savedDesign.id,
        savedDesignName: savedDesign.name,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preset application
  // ---------------------------------------------------------------------------

  /// Apply a preset's styling to the existing designs (or create new ones
  /// if none exist yet). Preset templates are cycled round-robin so that
  /// all current slots receive styling, and existing image files are kept.
  ///
  /// When the preset has MORE designs than the current count, additional
  /// screenshot slots are created automatically so all templates are used.
  void applyPreset(ScreenshotPreset preset) {
    final frame = _getDefaultDeviceFrame(displayType);
    final templateCount = preset.designs.length;
    final targetCount = state.designs.isEmpty
        ? templateCount
        : math.max(state.designs.length, templateCount);

    final designs = List.generate(targetCount, (i) {
      final template = preset.designs[i % templateCount];
      return template.copyWith(deviceFrame: frame, displayType: displayType);
    });

    // Preserve existing image files; pad with null if expanding.
    final imageFiles = List<File?>.generate(
      targetCount,
      (i) => i < state.imageFiles.length ? state.imageFiles[i] : null,
    );

    emit(
      state.copyWith(designs: designs, imageFiles: imageFiles, activeIndex: 0),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DeviceInfo _getDefaultDeviceFrame(String? displayType) {
    return ScreenshotUtils.getDefaultDeviceFrame(displayType);
  }

  /// Copies [file] to a stable app-managed directory so it won't be lost
  /// if the original source (e.g. Downloads, temp) is cleaned up.
  static Future<File> _copyToStableStorage(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final stableDir = Directory('${appDir.path}/screenshot_images');
    if (!await stableDir.exists()) {
      await stableDir.create(recursive: true);
    }

    // Skip copy if the file is already in our managed directory.
    if (p.isWithin(stableDir.path, file.path)) return file;

    final ext = p.extension(file.path).isNotEmpty
        ? p.extension(file.path)
        : '.png';
    final stableFile = File(
      '${stableDir.path}/${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(file.path)}$ext',
    );
    return file.copy(stableFile.path);
  }
}
