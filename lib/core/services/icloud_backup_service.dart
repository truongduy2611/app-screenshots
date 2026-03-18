import 'dart:io';

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
/// Zips the `screenshot_designs` directory and uploads it to iCloud.
/// Auto-backup runs on app launch with a 5-minute cooldown.
class ICloudBackupService {
  static const _channel = MethodChannel(
    'com.progressiostudio.appscreenshots/icloud',
  );

  static const String _designsDirName = 'screenshot_designs';
  static const String _lastBackupKey = 'last_icloud_backup_timestamp';
  static const String _autoBackupEnabledKey = 'icloud_auto_backup_enabled';
  static const int _cooldownMinutes = 5;
  static const int _maxBackups = 3;
  static const String _autoBackupFileName = 'appshots_auto_backup.zip';

  final SharedPreferences _prefs;
  final String? _storageRoot;

  ICloudBackupService(this._prefs, {String? storageRoot})
    : _storageRoot = storageRoot;

  /// Returns true if iCloud is available on the current device.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isICloudAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Whether auto-backup is enabled.
  bool get isAutoBackupEnabled => _prefs.getBool(_autoBackupEnabledKey) ?? true;

  /// Sets whether auto-backup is enabled.
  Future<void> setAutoBackupEnabled(bool enabled) =>
      _prefs.setBool(_autoBackupEnabledKey, enabled);

  /// Performs a backup if enough time has passed since the last one.
  ///
  /// Returns `true` if a backup was created, `false` if skipped or failed.
  Future<bool> performBackupIfNeeded() async {
    try {
      if (!isAutoBackupEnabled) {
        AppLogger.d('Auto-backup disabled, skipping', tag: 'iCloudBackup');
        return false;
      }

      if (!await isAvailable()) {
        AppLogger.d('iCloud not available, skipping', tag: 'iCloudBackup');
        return false;
      }

      final lastTimestamp = _prefs.getInt(_lastBackupKey);
      if (lastTimestamp != null) {
        final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
        final diff = DateTime.now().difference(lastBackup);
        if (diff.inMinutes < _cooldownMinutes) {
          AppLogger.d(
            'Cooldown active (${diff.inMinutes}m < ${_cooldownMinutes}m), skipping',
            tag: 'iCloudBackup',
          );
          return false;
        }
      }

      final result = await _createAutoBackup();
      return result != null;
    } catch (e, st) {
      AppLogger.error(
        'Auto-backup failed',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
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

      // Check if directory has any content
      final entries = designsDir.listSync();
      if (entries.isEmpty) {
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

  /// Creates an auto-backup using a fixed filename, overriding the previous one.
  Future<BackupMetadata?> _createAutoBackup() async {
    try {
      final designsDir = await _getDesignsDir();
      if (!await designsDir.exists()) {
        AppLogger.d('No designs directory, skipping', tag: 'iCloudBackup');
        return null;
      }

      final entries = designsDir.listSync();
      if (entries.isEmpty) {
        AppLogger.d(
          'Designs directory is empty, skipping',
          tag: 'iCloudBackup',
        );
        return null;
      }

      // Create zip in temp directory with fixed name using archive package
      final tempDir = await getTemporaryDirectory();
      final zipPath = p.join(tempDir.path, _autoBackupFileName);

      // Remove old temp zip if exists
      final oldZip = File(zipPath);
      if (await oldZip.exists()) {
        await oldZip.delete();
      }

      final zipBytes = await _zipDirectory(designsDir);
      if (zipBytes == null) {
        AppLogger.w('Failed to create zip', tag: 'iCloudBackup');
        return null;
      }

      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);

      // Upload to iCloud – uses fixed filename so it overrides the previous one
      final result = await _channel.invokeMethod<Map>('uploadToICloud', {
        'localPath': zipPath,
        'cloudFileName': _autoBackupFileName,
      });

      if (result == null) {
        AppLogger.w('Upload returned null', tag: 'iCloudBackup');
        return null;
      }

      final now = DateTime.now();
      final metadata = BackupMetadata(
        createdAt: now,
        sizeInBytes: await zipFile.length(),
        fileName: _autoBackupFileName,
        filePath: result['cloudPath'] as String?,
      );

      await _prefs.setInt(_lastBackupKey, now.millisecondsSinceEpoch);

      try {
        await zipFile.delete();
      } catch (_) {}

      AppLogger.i(
        'Auto-backup overridden: $_autoBackupFileName',
        tag: 'iCloudBackup',
      );
      return metadata;
    } catch (e, st) {
      AppLogger.error(
        '_createAutoBackup error',
        tag: 'iCloudBackup',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<Directory> _getDesignsDir() async {
    if (_storageRoot != null) {
      return Directory(_storageRoot);
    }
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, _designsDirName));
  }

  /// Zips a directory into bytes using the `archive` package (cross-platform).
  ///
  /// Returns `null` if the directory cannot be zipped.
  Future<Uint8List?> _zipDirectory(Directory dir) async {
    try {
      final archive = Archive();

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: dir.path);
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile.bytes(relativePath, bytes));
        }
      }

      final encoded = ZipEncoder().encode(archive);
      return Uint8List.fromList(encoded);
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
