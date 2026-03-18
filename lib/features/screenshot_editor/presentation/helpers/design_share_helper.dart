import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Utility for sharing and importing `.appshots` design files.
class DesignShareHelper {
  /// Exports and shares a [SavedDesign] as a `.appshots` file.
  ///
  /// On iOS/Android, uses the native share sheet.
  /// On macOS/desktop, opens a file save dialog.
  static Future<void> shareDesign(
    BuildContext context,
    SavedDesign design, {
    Rect? sharePositionOrigin,
  }) async {
    final designFileService = DesignFileService();
    final file = await designFileService.createExportFile(design);
    if (!context.mounted) return;

    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;

    if (isMobile) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } else {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Design File',
        fileName: file.path.split('/').last,
        allowedExtensions: ['appshots'],
        type: FileType.custom,
      );
      if (outputPath != null) {
        await file.copy(outputPath);
      }
    }
  }

  /// Saves a [SavedDesign] back to the given `.appshots` file path.
  ///
  /// Used when the design was opened directly from a file and the user
  /// wants to overwrite the original.
  static Future<void> saveToFile(SavedDesign design, String targetPath) async {
    final designFileService = DesignFileService();
    final exportFile = await designFileService.createExportFile(design);
    await exportFile.copy(targetPath);
  }

  /// Opens a file picker for importing `.appshots` files.
  ///
  /// Returns the imported [SavedDesign] or `null` if cancelled or failed.
  static Future<SavedDesign?> importDesign() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final filePath = result.files.single.path;
    if (filePath == null) return null;

    final designFileService = DesignFileService();
    return designFileService.parseExportFile(File(filePath));
  }
}
