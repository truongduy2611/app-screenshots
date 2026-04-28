import 'dart:async';
import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Service that resolves the active designs storage root (iCloud or local),
/// handles one-time migration, and exposes a stream for remote changes.
class ICloudSyncService {
  static const _channel = MethodChannel(
    'com.progressiostudio.appscreenshots/icloud',
  );

  static const String _migrationKey = 'icloud_sync_migration_complete';
  static const String _iCloudEnabledKey = 'icloud_sync_enabled';

  final SharedPreferences _prefs;

  /// The resolved storage directory path (iCloud or local fallback).
  late final String designsPath;

  /// Whether iCloud sync is active on this device.
  bool get isSyncEnabled => _iCloudActive;

  bool _iCloudAvailable = false;
  bool _iCloudActive = false;

  final _remoteChangeController = StreamController<void>.broadcast();

  /// Emits when another device pushes changes via iCloud.
  Stream<void> get onRemoteChange => _remoteChangeController.stream;

  /// Whether the user has iCloud sync enabled in settings.
  /// Defaults to true (opt-out model).
  bool get isUserEnabled => _prefs.getBool(_iCloudEnabledKey) ?? true;

  /// Persists the user's iCloud sync preference.
  Future<void> setUserEnabled(bool enabled) =>
      _prefs.setBool(_iCloudEnabledKey, enabled);

  ICloudSyncService(this._prefs);

  /// Initializes the service: resolves storage path, migrates if needed,
  /// and starts monitoring iCloud changes.
  ///
  /// Must be called before accessing [designsPath].
  Future<void> init() async {
    // 1. Check iCloud availability and user preference
    _iCloudAvailable = await _isICloudAvailable();
    final userEnabled = isUserEnabled;

    if (_iCloudAvailable && userEnabled) {
      // 2a. Get the iCloud designs path
      final iCloudPath = await _getICloudDesignsPath();
      if (iCloudPath != null) {
        designsPath = iCloudPath;

        // 3. Migrate local data if this is the first time
        await _migrateIfNeeded();

        // 4. Start monitoring for remote changes
        _setupChangeListener();
        await _startMonitoring();

        AppLogger.i('Using iCloud path: $designsPath', tag: 'iCloudSync');
        _iCloudActive = true;
        return;
      }
    }

    // 2b. Fallback to local storage
    final localPath = await _getLocalDesignsPath();
    designsPath = localPath!;
    AppLogger.i('Using local path: $designsPath', tag: 'iCloudSync');
  }

  /// Stops monitoring and cleans up resources.
  Future<void> dispose() async {
    await _stopMonitoring();
    await _remoteChangeController.close();
  }

  /// Disables iCloud sync at runtime — stops monitoring.
  /// The storage path switch takes effect on next app launch.
  Future<void> disableSync() async {
    await setUserEnabled(false);
    _iCloudActive = false;
    await _stopMonitoring();
    AppLogger.i('iCloud sync disabled by user', tag: 'iCloudSync');
  }

  /// Enables iCloud sync at runtime — takes effect on next app launch.
  Future<void> enableSync() async {
    await setUserEnabled(true);
    AppLogger.i('iCloud sync enabled — restart required', tag: 'iCloudSync');
  }

  // ---------------------------------------------------------------------------
  // Private — Method Channel
  // ---------------------------------------------------------------------------

  Future<bool> _isICloudAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isICloudAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<String?> _getICloudDesignsPath() async {
    try {
      return await _channel.invokeMethod<String>('getICloudDesignsPath');
    } on PlatformException catch (e) {
      AppLogger.w('getICloudDesignsPath error: $e', tag: 'iCloudSync');
      return null;
    }
  }

  Future<String?> _getLocalDesignsPath() async {
    try {
      return await _channel.invokeMethod<String>('getLocalDesignsPath');
    } on PlatformException catch (e) {
      AppLogger.w('getLocalDesignsPath error: $e', tag: 'iCloudSync');
      return null;
    }
  }

  Future<void> _startMonitoring() async {
    try {
      await _channel.invokeMethod<void>('startMonitoringChanges');
    } on PlatformException catch (e) {
      AppLogger.w('startMonitoringChanges error: $e', tag: 'iCloudSync');
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      await _channel.invokeMethod<void>('stopMonitoringChanges');
    } on PlatformException catch (e) {
      AppLogger.w('stopMonitoringChanges error: $e', tag: 'iCloudSync');
    }
  }

  void _setupChangeListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onICloudFilesChanged') {
        final args = call.arguments as Map<Object?, Object?>?;
        final added = _castStringList(args?['added']);
        final removed = _castStringList(args?['removed']);
        final changed = _castStringList(args?['changed']);

        // Only trigger refresh for design files, not backup zips etc.
        final allFiles = [...added, ...removed, ...changed];
        final hasDesignChanges = allFiles.any(
          (f) => f.endsWith('.json') || f.endsWith('.png'),
        );

        if (hasDesignChanges) {
          _remoteChangeController.add(null);
        }
      }
    });
  }

  static List<String> _castStringList(Object? obj) {
    if (obj is List) return obj.cast<String>();
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Private — Migration
  // ---------------------------------------------------------------------------

  /// Copies files from local `screenshot_designs/` → iCloud container.
  ///
  /// Only runs once (tracked via SharedPreferences). Files that already exist
  /// in iCloud are skipped (UUIDs make conflicts near impossible).
  Future<void> _migrateIfNeeded() async {
    if (_prefs.getBool(_migrationKey) == true) return;

    AppLogger.i('Starting migration to iCloud...', tag: 'iCloudSync');

    try {
      final localPath = await _getLocalDesignsPath();
      if (localPath == null) return;

      final localDir = Directory(localPath);
      if (!await localDir.exists()) {
        await _prefs.setBool(_migrationKey, true);
        return;
      }

      final entries = localDir.listSync();
      if (entries.isEmpty) {
        await _prefs.setBool(_migrationKey, true);
        return;
      }

      int migrated = 0;
      for (final entity in entries) {
        final fileName = p.basename(entity.path);
        final destPath = p.join(designsPath, fileName);

        if (entity is File && !File(destPath).existsSync()) {
          await entity.copy(destPath);
          migrated++;
        }
      }

      await _prefs.setBool(_migrationKey, true);
      AppLogger.i('Migration complete ($migrated files)', tag: 'iCloudSync');
    } catch (e, st) {
      AppLogger.error(
        'Migration error',
        tag: 'iCloudSync',
        error: e,
        stackTrace: st,
      );
      // Don't mark as complete so it retries next launch.
    }
  }
}
