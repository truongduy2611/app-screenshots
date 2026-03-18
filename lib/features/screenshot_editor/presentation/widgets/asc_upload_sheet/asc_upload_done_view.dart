part of '../asc_upload_sheet.dart';

// ─── Upload Done ────────────────────────────────────────────────────

class _UploadDoneView extends StatelessWidget {
  final AscUploadResult result;
  final VoidCallback onClose;

  const _UploadDoneView({required this.result, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors = result.failureCount > 0;
    final allFailed = result.successCount == 0 && result.failureCount > 0;

    final iconData = allFailed
        ? Symbols.error
        : hasErrors
        ? Symbols.warning
        : Symbols.check_circle;
    final iconColor = allFailed
        ? theme.colorScheme.error
        : hasErrors
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    final bgColor = allFailed
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
        : hasErrors
        ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(iconData, size: 28, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            allFailed
                ? context.l10n.uploadFailed
                : hasErrors
                ? context.l10n.completedWithIssues
                : context.l10n.uploadComplete,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // ── Stats ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                icon: Symbols.check_circle,
                label: context.l10n.nSucceeded(result.successCount),
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              if (result.failureCount > 0) ...[
                const SizedBox(width: 12),
                _StatChip(
                  icon: Symbols.cancel,
                  label: context.l10n.nFailed(result.failureCount),
                  color: theme.colorScheme.error,
                  theme: theme,
                ),
              ],
            ],
          ),

          // ── Per-locale results ──
          if (result.localeResults.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: result.localeResults.values.map((lr) {
                  return _LocaleResultRow(localeResult: lr, theme: theme);
                }).toList(),
              ),
            ),
          ],

          // ── Error details ──
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Text(
                  result.errors.join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton.primary(
            onPressed: onClose,
            label: context.l10n.statusDone,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}

/// Displays a locale's result with success/failure counts.
class _LocaleResultRow extends StatelessWidget {
  final LocaleResult localeResult;
  final ThemeData theme;

  const _LocaleResultRow({required this.localeResult, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isSuccess = localeResult.isSuccess;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isSuccess ? Symbols.check_circle : Symbols.cancel,
            size: 14,
            color: isSuccess
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              localeResult.locale.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          if (localeResult.successCount > 0)
            Text(
              '${localeResult.successCount} ✓',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (localeResult.failureCount > 0) ...[
            if (localeResult.successCount > 0) const SizedBox(width: 8),
            Text(
              '${localeResult.failureCount} ✗',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeData theme;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
