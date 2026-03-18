import 'dart:io';
import 'dart:typed_data';

import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';

/// Abstract interface for screenshot design persistence.
abstract class ScreenshotRepository {
  // Design Operations
  Future<SavedDesign> saveDesign({
    required ScreenshotDesign design,
    required Uint8List thumbnailBytes,
    String? name,
    String? existingId,
    File? originalImageFile,
    String? folderId,
    List<ScreenshotDesign>? multiDesigns,
    List<File?>? imageFiles,
  });

  Future<List<SavedDesign>> getAllDesigns();

  Future<void> deleteDesign(String id);

  // Folder Operations
  Future<DesignFolder> createFolder(String name, {String? parentId});

  Future<List<DesignFolder>> getAllFolders();

  Future<void> deleteFolder(String id);

  Future<void> moveDesignToFolder(String designId, String? folderId);

  Future<void> moveFolderToFolder(String folderId, String? targetFolderId);

  Future<void> renameFolder(String folderId, String newName);
}
