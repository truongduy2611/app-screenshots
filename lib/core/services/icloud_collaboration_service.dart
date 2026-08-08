import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges AppShots documents to the native iCloud Drive collaboration UI.
///
/// Collaboration is available on Apple platforms. The native implementation
/// copies a portable `.appshots` document into the app's public iCloud Drive
/// container and shares it as an open-in-place file, which lets the system
/// offer both Collaborate and Send Copy modes.
class ICloudCollaborationService {
  static const _channel = MethodChannel(
    'com.progressiostudio.appscreenshots/icloud',
  );

  static bool get isSupported => Platform.isIOS || Platform.isMacOS;

  /// Presents the native collaboration share sheet.
  ///
  /// Returns the iCloud path backing the collaboration, or `null` when iCloud
  /// collaboration is unavailable. A [PlatformException] is allowed to bubble
  /// up so callers can fall back to their normal copy-sharing experience.
  static Future<String?> shareDocument({
    required String localPath,
    required String fileName,
  }) async {
    if (!isSupported) return null;

    final response = await _channel.invokeMapMethod<String, Object?>(
      'shareICloudDocument',
      <String, Object?>{'localPath': localPath, 'fileName': fileName},
    );
    return response?['cloudPath'] as String?;
  }

  /// Writes an edited working copy back to the original shared file.
  ///
  /// Returns `false` when [workingPath] was not opened through the native
  /// open-in-place bridge, allowing the caller to use a regular file copy.
  static Future<bool> saveOpenedDocument({
    required String localPath,
    required String workingPath,
  }) async {
    if (!isSupported) return false;

    return await _channel.invokeMethod<bool>('saveOpenedDocument', {
          'localPath': localPath,
          'workingPath': workingPath,
        }) ??
        false;
  }
}
