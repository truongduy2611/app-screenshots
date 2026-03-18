part of '../asc_upload_sheet.dart';

// ─── Upload Progress ────────────────────────────────────────────────

class _UploadProgressView extends StatelessWidget {
  final AscUploadProgress? progress;
  final List<String> allLocales;

  const _UploadProgressView({this.progress, required this.allLocales});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress;
    final fraction = p?.fraction ?? 0;
    final percentText = '${(fraction * 100).toInt()}%';
    final localeStatuses = p?.localeStatuses ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Circular progress with percentage ──
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: p != null ? fraction : null,
                    strokeWidth: 5,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (p != null)
                  Text(
                    percentText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status text ──
          if (p != null) ...[
            Text(
              context.l10n.uploadingLocale(p.locale),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.nOfTotalScreenshots(p.current, p.total),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            // ── Linear progress bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary,
              ),
            ),
          ] else ...[
            Text(
              context.l10n.preparingUpload,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          // ── Per-locale status list ──
          if (localeStatuses.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: localeStatuses.entries.map((entry) {
                  return _LocaleStatusRow(
                    locale: entry.key,
                    status: entry.value,
                    theme: theme,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Displays a locale's upload status with an icon.
class _LocaleStatusRow extends StatelessWidget {
  final String locale;
  final LocaleUploadStatus status;
  final ThemeData theme;

  const _LocaleStatusRow({
    required this.locale,
    required this.status,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          _statusIcon(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              locale.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _statusLabel(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _statusColor(),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    switch (status) {
      case LocaleUploadStatus.pending:
        return Icon(
          Symbols.circle,
          size: 14,
          color: theme.colorScheme.outlineVariant,
        );
      case LocaleUploadStatus.uploading:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        );
      case LocaleUploadStatus.done:
        return Icon(
          Symbols.check_circle,
          size: 14,
          color: theme.colorScheme.primary,
        );
      case LocaleUploadStatus.failed:
        return Icon(Symbols.cancel, size: 14, color: theme.colorScheme.error);
    }
  }

  String _statusLabel(BuildContext context) {
    switch (status) {
      case LocaleUploadStatus.pending:
        return context.l10n.statusPending;
      case LocaleUploadStatus.uploading:
        return context.l10n.statusUploading;
      case LocaleUploadStatus.done:
        return context.l10n.statusDone;
      case LocaleUploadStatus.failed:
        return context.l10n.statusFailed;
    }
  }

  Color _statusColor() {
    switch (status) {
      case LocaleUploadStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case LocaleUploadStatus.uploading:
        return theme.colorScheme.primary;
      case LocaleUploadStatus.done:
        return theme.colorScheme.primary;
      case LocaleUploadStatus.failed:
        return theme.colorScheme.error;
    }
  }
}
