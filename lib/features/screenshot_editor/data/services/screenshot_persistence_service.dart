import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';

import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ScreenshotPersistenceService {
  static const String _designsDirName = 'screenshot_designs';

  /// The root storage directory path for designs.
  ///
  /// When provided via constructor, uses that path directly (e.g. from
  /// [ICloudSyncService]). Otherwise falls back to local app documents.
  final String? _storageRootOverride;

  ScreenshotPersistenceService({String? storageRoot})
    : _storageRootOverride = storageRoot;

  Future<Directory> get _designsDir async {
    if (_storageRootOverride != null) {
      final dir = Directory(_storageRootOverride);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_designsDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Extracts the basename from a path. Handles both absolute and relative.
  static String? _toRelative(String? path) {
    if (path == null) return null;
    return p.basename(path);
  }

  /// Resolves a relative filename to an absolute path within the designs dir.
  static String _toAbsolute(String dirPath, String relativePath) {
    if (p.isAbsolute(relativePath)) {
      // Legacy absolute path — extract basename and resolve.
      return '$dirPath/${p.basename(relativePath)}';
    }
    return '$dirPath/$relativePath';
  }

  static String? _toAbsoluteNullable(String dirPath, String? relativePath) {
    if (relativePath == null) return null;
    return _toAbsolute(dirPath, relativePath);
  }

  Future<SavedDesign> saveDesign({
    required ScreenshotDesign design,
    required Uint8List thumbnailBytes,
    String? name,
    String? existingId,
    File? originalImageFile,
    String? folderId,
    List<ScreenshotDesign>? multiDesigns,
    List<File?>? imageFiles,
    TranslationBundle? translationBundle,
    AscAppConfig? ascAppConfig,
  }) async {
    final dir = await _designsDir;
    final id = existingId ?? const Uuid().v4();
    final timestamp = DateTime.now();
    final designName =
        name ?? ScreenshotUtils.defaultDesignName(design.displayType);

    // Save Thumbnail
    final thumbnailFile = File('${dir.path}/$id.png');
    await thumbnailFile.writeAsBytes(thumbnailBytes);
    // Evict stale cached version so UI shows the updated thumbnail
    FileImage(thumbnailFile).evict();

    // Save Original Image if provided
    String? imagePath;
    if (originalImageFile != null && await originalImageFile.exists()) {
      final extension = originalImageFile.path.split('.').last;
      final savedImageFile = File('${dir.path}/${id}_source.$extension');
      await originalImageFile.copy(savedImageFile.path);
      imagePath = savedImageFile.path;
    }

    // Preserve fields from existing save (read once, reuse).
    if (existingId != null) {
      try {
        final existingJsonFile = File('${dir.path}/$existingId.json');
        if (await existingJsonFile.exists()) {
          final content = await existingJsonFile.readAsString();
          final json = jsonDecode(content);
          final existing = SavedDesign.fromJson(json);
          imagePath ??= existing.imagePath;
          folderId ??= existing.folderId;
          translationBundle ??= existing.translationBundle;
          ascAppConfig ??= existing.ascAppConfig;
        }
      } catch (e) {
        AppLogger.w(
          'Error preserving existing design data',
          tag: 'Persistence',
        );
      }
    }

    // Save multi-canvas image files
    List<String?>? savedImagePaths;
    if (imageFiles != null) {
      savedImagePaths = <String?>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        if (file != null && await file.exists()) {
          final ext = file.path.split('.').last;
          final dest = File('${dir.path}/${id}_slot${i}_source.$ext');
          await file.copy(dest.path);
          savedImagePaths.add(dest.path);
        } else {
          // Try to preserve from existing save
          if (existingId != null) {
            try {
              final existingJsonFile = File('${dir.path}/$existingId.json');
              if (await existingJsonFile.exists()) {
                final content = await existingJsonFile.readAsString();
                final json = jsonDecode(content);
                final existing = SavedDesign.fromJson(json);
                if (existing.imagePaths != null &&
                    i < existing.imagePaths!.length) {
                  savedImagePaths.add(existing.imagePaths![i]);
                } else {
                  savedImagePaths.add(null);
                }
              } else {
                savedImagePaths.add(null);
              }
            } catch (e) {
              savedImagePaths.add(null);
            }
          } else {
            savedImagePaths.add(null);
          }
        }
      }
    }

    // Store relative filenames in JSON for portability.
    final savedDesign = SavedDesign(
      id: id,
      name: designName,
      lastModified: timestamp,
      thumbnailPath: _toRelative(thumbnailFile.path)!,
      imagePath: _toRelative(imagePath),
      folderId: folderId,
      design: design,
      multiDesigns: multiDesigns,
      imagePaths: savedImagePaths?.map(_toRelative).toList(),
      translationBundle: translationBundle,
      ascAppConfig: ascAppConfig,
    );

    final jsonFile = File('${dir.path}/$id.json');
    await jsonFile.writeAsString(jsonEncode(savedDesign.toJson()));

    // Return a copy with absolute paths for immediate runtime use.
    return SavedDesign(
      id: id,
      name: designName,
      lastModified: timestamp,
      thumbnailPath: thumbnailFile.path,
      imagePath: imagePath,
      folderId: folderId,
      design: design,
      multiDesigns: multiDesigns,
      imagePaths: savedImagePaths,
      translationBundle: translationBundle,
      ascAppConfig: ascAppConfig,
    );
  }

  /// Loads a single design by its ID. Returns `null` if not found.
  Future<SavedDesign?> getDesignById(String id) async {
    final dir = await _designsDir;
    final dirPath = dir.path;
    final jsonFile = File('$dirPath/$id.json');

    if (!await jsonFile.exists()) return null;

    try {
      final content = await jsonFile.readAsString();
      final json = jsonDecode(content);
      if (json.containsKey('createdAt')) return null; // folder file
      final design = SavedDesign.fromJson(json);
      return design.copyWith(
        thumbnailPath: _toAbsolute(dirPath, design.thumbnailPath),
        imagePath: _toAbsoluteNullable(dirPath, design.imagePath),
        imagePaths: design.imagePaths
            ?.map((p) => _toAbsoluteNullable(dirPath, p))
            .toList(),
      );
    } catch (e, st) {
      AppLogger.error(
        'Error loading design $id',
        tag: 'Persistence',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<List<SavedDesign>> getAllDesigns() async {
    final dir = await _designsDir;
    final dirPath = dir.path;
    final entities = dir.listSync();

    // Collect design JSON file paths (exclude folder files).
    final designFiles = entities
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.json') && !p.basename(f.path).startsWith('folder_'),
        )
        .toList();

    if (designFiles.isEmpty) return [];

    // Read all files in parallel.
    final contents = await Future.wait(
      designFiles.map((f) => f.readAsString()),
    );

    // Offload heavy JSON decode + model construction to a background isolate.
    final designs = await Isolate.run(() {
      return _parseDesignJsons(contents, dirPath);
    });

    designs.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return designs;
  }

  /// Pure function for background isolate — parses raw JSON strings into
  /// [SavedDesign] objects with resolved absolute paths.
  static List<SavedDesign> _parseDesignJsons(
    List<String> jsonStrings,
    String dirPath,
  ) {
    final List<SavedDesign> results = [];
    for (final content in jsonStrings) {
      try {
        final json = jsonDecode(content);
        if (json.containsKey('createdAt')) continue; // skip folder files
        final design = SavedDesign.fromJson(json);
        results.add(
          design.copyWith(
            thumbnailPath: _toAbsolute(dirPath, design.thumbnailPath),
            imagePath: _toAbsoluteNullable(dirPath, design.imagePath),
            imagePaths: design.imagePaths
                ?.map((path) => _toAbsoluteNullable(dirPath, path))
                .toList(),
          ),
        );
      } catch (_) {
        // Skip corrupt files — error is not observable from isolate.
      }
    }
    return results;
  }

  Future<void> deleteDesign(String id) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/$id.json');
    final thumbFile = File('${dir.path}/$id.png');

    if (await jsonFile.exists()) {
      try {
        final content = await jsonFile.readAsString();
        final json = jsonDecode(content);
        final imagePath = json['imagePath'];
        if (imagePath != null) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
      } catch (e) {
        AppLogger.w('Error cleaning up source image', tag: 'Persistence');
      }
      await jsonFile.delete();
    }
    if (await thumbFile.exists()) await thumbFile.delete();
  }

  // Folder Operations

  Future<DesignFolder> createFolder(String name, {String? parentId}) async {
    final dir = await _designsDir;
    final id = const Uuid().v4();
    final folder = DesignFolder(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      parentId: parentId,
    );

    final jsonFile = File('${dir.path}/folder_$id.json');
    await jsonFile.writeAsString(jsonEncode(folder.toJson()));
    return folder;
  }

  Future<List<DesignFolder>> getAllFolders() async {
    final dir = await _designsDir;
    final entities = dir.listSync();

    // Collect folder JSON file paths.
    final folderFiles = entities
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.json') &&
              p.basename(f.path).startsWith('folder_'),
        )
        .toList();

    if (folderFiles.isEmpty) return [];

    // Read all files in parallel.
    final contents = await Future.wait(
      folderFiles.map((f) => f.readAsString()),
    );

    final List<DesignFolder> folders = [];
    for (final content in contents) {
      try {
        final json = jsonDecode(content);
        folders.add(DesignFolder.fromJson(json));
      } catch (e, st) {
        AppLogger.error(
          'Error loading folder',
          tag: 'Persistence',
          error: e,
          stackTrace: st,
        );
      }
    }

    folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return folders;
  }

  Future<void> deleteFolder(String id) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/folder_$id.json');
    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }

    final allDesigns = await getAllDesigns();
    for (var design in allDesigns) {
      if (design.folderId == id) {
        await moveDesignToFolder(design.id, null);
      }
    }

    final allFolders = await getAllFolders();
    for (var folder in allFolders) {
      if (folder.parentId == id) {
        await moveFolderToFolder(folder.id, null);
      }
    }
  }

  /// Deletes a folder AND all designs inside it (instead of moving them to root).
  Future<void> deleteFolderWithDesigns(String id) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/folder_$id.json');
    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }

    // Delete all designs in this folder
    final allDesigns = await getAllDesigns();
    for (var design in allDesigns) {
      if (design.folderId == id) {
        await deleteDesign(design.id);
      }
    }

    // Move sub-folders to root
    final allFolders = await getAllFolders();
    for (var folder in allFolders) {
      if (folder.parentId == id) {
        await moveFolderToFolder(folder.id, null);
      }
    }
  }

  Future<void> moveDesignToFolder(String designId, String? folderId) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/$designId.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final json = jsonDecode(content);
      final design = SavedDesign.fromJson(json);

      // Paths in the JSON are already relative — keep them as-is.
      final newDesign = design.copyWith(
        folderId: folderId,
        lastModified: DateTime.now(),
      );
      await jsonFile.writeAsString(jsonEncode(newDesign.toJson()));
    }
  }

  Future<void> moveFolderToFolder(
    String folderId,
    String? targetFolderId,
  ) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/folder_$folderId.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final json = jsonDecode(content);
      var folder = DesignFolder.fromJson(json);

      folder = DesignFolder(
        id: folder.id,
        name: folder.name,
        createdAt: folder.createdAt,
        parentId: targetFolderId,
      );

      await jsonFile.writeAsString(jsonEncode(folder.toJson()));
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/folder_$folderId.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final json = jsonDecode(content);
      final folder = DesignFolder.fromJson(json);

      final updatedFolder = DesignFolder(
        id: folder.id,
        name: newName,
        createdAt: folder.createdAt,
        parentId: folder.parentId,
      );

      await jsonFile.writeAsString(jsonEncode(updatedFolder.toJson()));
    }
  }

  Future<void> renameDesign(String designId, String newName) async {
    final dir = await _designsDir;
    final jsonFile = File('${dir.path}/$designId.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final json = jsonDecode(content);
      final design = SavedDesign.fromJson(json);

      final updated = design.copyWith(name: newName);
      await jsonFile.writeAsString(jsonEncode(updated.toJson()));
    }
  }
}
