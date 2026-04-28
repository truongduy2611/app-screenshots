part of 'settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// iCloud Backup Section
// ─────────────────────────────────────────────────────────────────────────────

class _ICloudBackupSection extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _ICloudBackupSection({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupCubit, BackupState>(
      builder: (context, state) {
        return _SettingsTileGroup(
          isDark: isDark,
          theme: theme,
          children: [
            // Master iCloud sync toggle
            AppListTile(
              leading: Icon(
                Symbols.cloud_rounded,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                context.l10n.icloudSync,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                context.l10n.icloudSyncSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              trailing: AppSwitch(
                value: state.isSyncEnabled,
                onChanged: state.isAvailable
                    ? (v) => _toggleSync(context, v)
                    : null,
              ),
              onTap: state.isAvailable
                  ? () => _toggleSync(context, !state.isSyncEnabled)
                  : null,
            ),
            
            if (state.isSyncEnabled) ...[
              // Auto-backup toggle
              AppListTile(
                leading: Icon(
                  Symbols.cloud_sync_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  context.l10n.backupsAutomatic,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: AppSwitch(
                  value: state.isEnabled,
                  onChanged: state.isAvailable
                      ? (v) => context.read<BackupCubit>().toggleAutoBackup(v)
                      : null,
                ),
                onTap: state.isAvailable
                    ? () => context.read<BackupCubit>().toggleAutoBackup(
                        !state.isEnabled,
                      )
                    : null,
              ),
              // Last backup info
              _SettingsTile(
                icon: Symbols.cloud_done_rounded,
                title: context.l10n.lastBackup,
                subtitle: state.lastBackupDate != null
                    ? DateFormat.yMMMd().add_jm().format(state.lastBackupDate!)
                    : context.l10n.noBackupsAvailable,
                theme: theme,
              ),
              // Backup now
              _SettingsTile(
                icon: state.isBackingUp
                    ? Symbols.sync_rounded
                    : Symbols.backup_rounded,
                title: context.l10n.backupNow,
                subtitle: !state.isAvailable
                    ? context.l10n.icloudNotAvailable
                    : null,
                theme: theme,
                onTap: state.isAvailable && !state.isBackingUp
                    ? () => _backupNow(context)
                    : null,
              ),
              // Restore from backup
              _SettingsTile(
                icon: Symbols.restore_rounded,
                title: context.l10n.restoreFromBackup,
                theme: theme,
                onTap: state.isAvailable ? () => _showRestoreDialog(context) : null,
              ),
            ],
          ],
        );
      },
    );
  }

  void _toggleSync(BuildContext context, bool enabled) {
    context.read<BackupCubit>().toggleICloudSync(enabled);
    if (!enabled) {
      // Show restart notice
      context.showAppSnackbar(
        context.l10n.restartRequired,
        type: AppSnackbarType.info,
      );
    }
  }

  Future<void> _backupNow(BuildContext context) async {
    await context.read<BackupCubit>().manualBackup();
    if (!context.mounted) return;
    final state = context.read<BackupCubit>().state;
    context.showAppSnackbar(
      state.error ?? context.l10n.backupCreatedSuccessfully,
      type: state.error != null
          ? AppSnackbarType.error
          : AppSnackbarType.success,
    );
  }

  void _showRestoreDialog(BuildContext context) async {
    await context.read<BackupCubit>().refreshBackups();
    if (!context.mounted) return;

    final backups = context.read<BackupCubit>().state.backups;
    if (backups.isEmpty) {
      context.showAppSnackbar(
        context.l10n.noBackupsAvailable,
        type: AppSnackbarType.info,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<BackupCubit>(),
        child: _RestoreBackupDialog(backups: backups),
      ),
    );
  }
}

class _RestoreBackupDialog extends StatelessWidget {
  final List<BackupMetadata> backups;

  const _RestoreBackupDialog({required this.backups});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<BackupCubit, BackupState>(
      builder: (context, state) {
        final displayBackups = state.backups.isNotEmpty
            ? state.backups
            : backups;

        return AlertDialog(
          title: Text(context.l10n.restoreFromBackup),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.restoreWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                ...displayBackups.map(
                  (backup) => AppListTile(
                    leading: const Icon(Symbols.cloud_download_rounded),
                    title: Text(
                      DateFormat.yMMMd().add_jm().format(backup.createdAt),
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      backup.formattedSize,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Symbols.delete_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      style: IconButton.styleFrom(
                        fixedSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _deleteBackup(context, backup),
                      tooltip: context.l10n.delete,
                    ),
                    onTap: () => _restore(context, backup),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _restore(BuildContext context, BackupMetadata backup) async {
    Navigator.pop(context);
    final cubit = context.read<BackupCubit>();
    final success = await cubit.restoreFromBackup(backup);
    if (!context.mounted) return;
    context.showAppSnackbar(
      success
          ? context.l10n.backupRestoredSuccessfully
          : context.l10n.backupFailed,
      type: success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }

  Future<void> _deleteBackup(
    BuildContext context,
    BackupMetadata backup,
  ) async {
    await context.read<BackupCubit>().deleteBackup(backup);
    if (!context.mounted) return;
    // If no more backups, close the dialog
    if (context.read<BackupCubit>().state.backups.isEmpty) {
      Navigator.pop(context);
    }
  }
}
