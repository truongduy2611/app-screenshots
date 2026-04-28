import 'package:app_screenshots/core/services/icloud_backup_service.dart';
import 'package:app_screenshots/core/services/icloud_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'backup_state.dart';

/// Cubit for managing iCloud backup and restore operations.
class BackupCubit extends Cubit<BackupState> {
  final ICloudBackupService _backupService;
  final ICloudSyncService _syncService;

  BackupCubit(this._backupService, this._syncService)
      : super(const BackupState());

  /// Initializes the cubit: checks availability and triggers auto-backup.
  Future<void> init() async {
    final isAvailable = await _backupService.isAvailable();
    final lastBackup = _backupService.lastBackupDate;
    final isEnabled = _backupService.isAutoBackupEnabled;
    final isSyncEnabled = _syncService.isUserEnabled;

    emit(
      state.copyWith(
        isAvailable: isAvailable,
        lastBackupDate: lastBackup,
        isEnabled: isEnabled,
        isSyncEnabled: isSyncEnabled,
      ),
    );

    if (isAvailable && isEnabled) {
      // Run auto-backup in background — don't block UI
      _backupService.performBackupIfNeeded().then((didBackup) async {
        if (didBackup) {
          final backups = await _backupService.listBackups();
          emit(
            state.copyWith(lastBackupDate: DateTime.now(), backups: backups),
          );
        }
      });
    }
  }

  /// Toggles auto-backup on/off.
  Future<void> toggleAutoBackup(bool enabled) async {
    await _backupService.setAutoBackupEnabled(enabled);
    emit(state.copyWith(isEnabled: enabled));

    if (enabled) {
      // Trigger an immediate backup when re-enabled
      _backupService.performBackupIfNeeded().then((didBackup) async {
        if (didBackup) {
          final backups = await _backupService.listBackups();
          emit(
            state.copyWith(lastBackupDate: DateTime.now(), backups: backups),
          );
        }
      });
    }
  }

  /// Toggles master iCloud sync on/off.
  Future<void> toggleICloudSync(bool enabled) async {
    if (enabled) {
      await _syncService.enableSync();
    } else {
      await _syncService.disableSync();
      // Also disable auto-backup when sync is off
      await _backupService.setAutoBackupEnabled(false);
    }
    emit(state.copyWith(
      isSyncEnabled: enabled,
      isEnabled: enabled ? state.isEnabled : false,
    ));
  }

  /// Creates a manual backup immediately.
  Future<void> manualBackup() async {
    emit(state.copyWith(isBackingUp: true, clearError: true));

    final result = await _backupService.createBackup();

    if (result != null) {
      final backups = await _backupService.listBackups();
      emit(
        state.copyWith(
          isBackingUp: false,
          lastBackupDate: result.createdAt,
          backups: backups,
        ),
      );
    } else {
      emit(state.copyWith(isBackingUp: false, error: 'Backup failed'));
    }
  }

  /// Refreshes the list of available backups from iCloud.
  Future<void> refreshBackups() async {
    final backups = await _backupService.listBackups();
    emit(state.copyWith(backups: backups));
  }

  /// Restores from a specific backup (auto-merges conflicts).
  Future<bool> restoreFromBackup(BackupMetadata backup) async {
    emit(state.copyWith(isRestoring: true, clearError: true));

    final success = await _backupService.restoreFromBackup(backup);

    emit(
      state.copyWith(
        isRestoring: false,
        error: success ? null : 'Restore failed',
      ),
    );

    return success;
  }

  /// Deletes a specific backup.
  Future<void> deleteBackup(BackupMetadata backup) async {
    final success = await _backupService.deleteBackup(backup);
    if (success) {
      await refreshBackups();
    }
  }

  /// Clears any error message.
  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
