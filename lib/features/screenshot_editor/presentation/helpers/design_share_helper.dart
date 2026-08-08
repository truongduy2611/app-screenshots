import 'dart:io';

import 'package:app_screenshots/core/services/icloud_collaboration_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Utility for sharing and importing `.appshots` design files.
class DesignShareHelper {
  /// Exports and shares a [SavedDesign] as a `.appshots` file.
  ///
  /// On Apple platforms, shares an open-in-place iCloud document so the system
  /// offers Collaborate and Send Copy. Android uses its native share sheet;
  /// other desktop platforms open a file save dialog.
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

    if (ICloudCollaborationService.isSupported) {
      try {
        await ICloudCollaborationService.shareDocument(
          localPath: file.path,
          fileName: _collaborationFileName(design),
        );
        return;
      } on PlatformException {
        // iCloud may be disabled or unavailable. Fall through to the existing
        // send-copy/save-file experience instead of blocking sharing.
      }
    }

    if (isMobile) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } else {
      final bytes = await file.readAsBytes();
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Design File',
        fileName: file.path.split('/').last,
        bytes: bytes,
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

    if (ICloudCollaborationService.isSupported) {
      final saved = await ICloudCollaborationService.saveOpenedDocument(
        localPath: exportFile.path,
        workingPath: targetPath,
      );
      if (saved) return;
    }

    // Native returns false for ordinary local files that have no open-in-place
    // mapping. Platform failures remain visible to the caller.
    await exportFile.copy(targetPath);
  }

  static String _collaborationFileName(SavedDesign design) {
    final safeName = design.name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final baseName = safeName.isEmpty ? 'Untitled Design' : safeName;
    return '$baseName - ${design.id}.appshots';
  }

  /// Opens a file picker for importing `.appshots` files.
  ///
  /// Returns the imported [SavedDesign] or `null` if cancelled or failed.
  static Future<SavedDesign?> importDesign() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return null;
    final filePath = result.files.single.path;
    if (filePath == null) return null;

    final designFileService = DesignFileService();
    return designFileService.parseExportFile(File(filePath));
  }
}
