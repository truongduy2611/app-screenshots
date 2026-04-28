part of 'backup_cubit.dart';

/// State for the BackupCubit.
@immutable
class BackupState {
  /// Whether iCloud is available on this device.
  final bool isAvailable;

  /// Whether master iCloud sync is enabled by the user.
  final bool isSyncEnabled;

  /// Whether auto-backup is enabled by the user.
  final bool isEnabled;

  /// Whether a backup is currently in progress.
  final bool isBackingUp;

  /// Whether a restore is currently in progress.
  final bool isRestoring;

  /// The date of the last successful backup.
  final DateTime? lastBackupDate;

  /// The list of available backups in iCloud.
  final List<BackupMetadata> backups;

  /// Error message, if any.
  final String? error;

  const BackupState({
    this.isAvailable = false,
    this.isSyncEnabled = true,
    this.isEnabled = true,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.lastBackupDate,
    this.backups = const [],
    this.error,
  });

  BackupState copyWith({
    bool? isAvailable,
    bool? isSyncEnabled,
    bool? isEnabled,
    bool? isBackingUp,
    bool? isRestoring,
    DateTime? lastBackupDate,
    List<BackupMetadata>? backups,
    String? error,
    bool clearError = false,
  }) {
    return BackupState(
      isAvailable: isAvailable ?? this.isAvailable,
      isSyncEnabled: isSyncEnabled ?? this.isSyncEnabled,
      isEnabled: isEnabled ?? this.isEnabled,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      backups: backups ?? this.backups,
      error: clearError ? null : error ?? this.error,
    );
  }
}
