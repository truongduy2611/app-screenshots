import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backup metadata for an iCloud backup.
class BackupMetadata {
  /// The timestamp when the backup was created.
  final DateTime createdAt;

  /// The size of the backup file in bytes.
  final int sizeInBytes;

  /// The file name of the backup.
  final String fileName;

  /// The file path (cloud) of the backup.
  final String? filePath;

  const BackupMetadata({
    required this.createdAt,
    required this.sizeInBytes,
    required this.fileName,
    this.filePath,
  });

  /// Creates a BackupMetadata from the native method channel response.
  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      createdAt: DateTime.parse(map['createdAt'] as String).toLocal(),
      sizeInBytes: map['sizeInBytes'] as int,
      fileName: map['fileName'] as String,
      filePath: map['filePath'] as String?,
    );
  }

  /// Returns a human-readable file size string.
  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// iCloud backup service for App Screenshots.
///
/// Creates user-requested ZIP snapshots of the `screenshot_designs` directory
/// and uploads them to iCloud.
class ICloudBackupService {
  static const _channel = MethodChannel(
    'com.progressiostudio.appscreenshots/icloud',
  );

  static const String _designsDirName = 'screenshot_designs';
  static const String _lastBackupKey = 'last_icloud_backup_timestamp';
  static const int _maxBackups = 3;

  final SharedPreferences _prefs;
  final Future<String>? _storageRootFuture;

  ICloudBackupService(this._prefs, {Future<String>? storageRootFuture})
    : _storageRootFuture = storageRootFuture;

  /// Returns true if iCloud is available on the current device.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isICloudAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Creates a backup of the screenshot_designs directory.
  ///
  /// Returns [BackupMetadata] on success, `null` on failure.
  Future<BackupMetadata?> createBackup() async {
    try {
      final designsDir = await _getDesignsDir();
      if (!await designsDir.exists()) {
        AppLogger.d('No designs directory, skipping', tag: 'iCloudBackup');
        return null;
      }

      // Check if directory has any content — stop at the first entry rather
      // than consuming the entire directory stream via Stream.isEmpty.
      final hasContent = await designsDir.list().any((_) => true);
      if (!hasContent) {
        AppLogger.d(
          'Designs directory is empty, skipping',
          tag: 'iCloudBackup',
        );
        return null;
      }

      // Generate zip filename
      final now = DateTime.now();
      final timestamp =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final zipFileName = 'appshots_backup_$timestamp.zip';

      // Create zip in temp directory using archive package (cross-platform)
      final tempDir = await getTemporaryDirectory();
      final zipPath = p.join(tempDir.path, zipFileName);

      final zipBytes = await _zipDirectory(designsDir);
      if (zipBytes == null) {
        AppLogger.w('Failed to create zip', tag: 'iCloudBackup');
        return null;
      }

      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);

      // Upload to iCloud
      final result = await _channel.invokeMethod<Map>('uploadToICloud', {
        'localPath': zipPath,
        'cloudFileName': zipFileName,
      });

      if (result == null) {
        AppLogger.w('Upload returned null', tag: 'iCloudBackup');
        return null;
      }

      final metadata = BackupMetadata(
        createdAt: now,
        sizeInBytes: await zipFile.length(),
        fileName: zipFileName,
        filePath: result['cloudPath'] as String?,
      );

      // Save last backup timestamp
      await _prefs.setInt(_lastBackupKey, now.millisecondsSinceEpoch);

      // Clean up temp file
      try {
        await zipFile.delete();
      } catch (_) {}

      AppLogger.i('Backup created: $zipFileName', tag: 'iCloudBackup');
      await _cleanupOldBackups();
      return metadata;
    } catch (e, st) {
      AppLogger.error(
        'createBackup error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Lists all available backups in iCloud.
  Future<List<BackupMetadata>> listBackups() async {
    try {
      final result = await _channel.invokeMethod<List>('listICloudBackups');
      if (result == null) return [];

      return result
          .cast<Map>()
          .map((m) => BackupMetadata.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'listBackups error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Restores from a specific backup with auto-conflict resolution.
  ///
  /// Downloads the backup zip from iCloud and merges it with the current
  /// `screenshot_designs` directory. For conflicts, the newer file wins
  /// (based on modification time).
  ///
  /// Returns `true` if successful.
  Future<bool> restoreFromBackup(BackupMetadata backup) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final localZipPath = p.join(tempDir.path, backup.fileName);

      // Download from iCloud
      final downloadResult = await _channel.invokeMethod<bool>(
        'downloadFromICloud',
        {'cloudFileName': backup.fileName, 'localPath': localZipPath},
      );

      if (downloadResult != true) {
        AppLogger.w('Download failed', tag: 'iCloudBackup');
        return false;
      }

      final designsDir = await _getDesignsDir();

      // Extract to a temp directory first for merging
      final extractDir = Directory(
        p.join(
          tempDir.path,
          'appshots_restore_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await extractDir.create(recursive: true);

      try {
        // Unzip backup using archive package (cross-platform)
        final zipBytes = await File(localZipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);

        for (final file in archive.files) {
          if (file.isFile) {
            final outPath = p.join(extractDir.path, file.name);
            final outFile = File(outPath);
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content);
          }
        }

        // Ensure designs directory exists
        if (!await designsDir.exists()) {
          await designsDir.create(recursive: true);
        }

        // Merge: copy files from backup, auto-resolve conflicts
        await _mergeDirectories(extractDir, designsDir);

        AppLogger.i(
          'Restored (merged) from ${backup.fileName}',
          tag: 'iCloudBackup',
        );
        return true;
      } finally {
        // Clean up temp files
        try {
          await extractDir.delete(recursive: true);
        } catch (_) {}
        try {
          await File(localZipPath).delete();
        } catch (_) {}
      }
    } catch (e, st) {
      AppLogger.error(
        'restoreFromBackup error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Merges [source] directory into [target] with auto-conflict resolution.
  ///
  /// - Files only in source → copied to target
  /// - Files only in target → kept
  /// - Files in both → newer file wins (by modification time)
  Future<void> _mergeDirectories(Directory source, Directory target) async {
    await for (final entity in source.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: source.path);
      final targetPath = p.join(target.path, relativePath);

      if (entity is Directory) {
        final targetDir = Directory(targetPath);
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else if (entity is File) {
        final targetFile = File(targetPath);
        if (await targetFile.exists()) {
          // Conflict: newer file wins
          final sourceMod = await entity.lastModified();
          final targetMod = await targetFile.lastModified();
          if (sourceMod.isAfter(targetMod)) {
            await entity.copy(targetPath);
          }
          // else: keep the local (newer) version
        } else {
          // No conflict: copy from backup
          final parentDir = Directory(p.dirname(targetPath));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          await entity.copy(targetPath);
        }
      }
    }
  }

  /// Deletes a specific backup from iCloud.
  Future<bool> deleteBackup(BackupMetadata backup) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteICloudBackup', {
        'fileName': backup.fileName,
      });
      return result ?? false;
    } catch (e, st) {
      AppLogger.error(
        'deleteBackup error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Gets the last backup timestamp.
  DateTime? get lastBackupDate {
    final timestamp = _prefs.getInt(_lastBackupKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<Directory> _getDesignsDir() async {
    if (_storageRootFuture != null) {
      final root = await _storageRootFuture;
      return Directory(root);
    }
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, _designsDirName));
  }

  /// Zips a directory into bytes using the `archive` package (cross-platform).
  ///
  /// Returns `null` if the directory cannot be zipped.
  Future<Uint8List?> _zipDirectory(Directory dir) async {
    try {
      final path = dir.path;
      return await Isolate.run(() => _encodeDirectory(path));
    } catch (e, st) {
      AppLogger.error(
        '_zipDirectory error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static Future<Uint8List> _encodeDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    final archive = Archive();

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: dirPath);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile.bytes(relativePath, bytes));
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Keeps only the most recent [_maxBackups] backups.
  Future<void> _cleanupOldBackups() async {
    try {
      final backups = await listBackups();
      if (backups.length <= _maxBackups) return;

      final toDelete = backups.sublist(_maxBackups);
      for (final backup in toDelete) {
        await deleteBackup(backup);
        AppLogger.d(
          'Cleaned up old backup: ${backup.fileName}',
          tag: 'iCloudBackup',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'Cleanup error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
    }
  }
}
