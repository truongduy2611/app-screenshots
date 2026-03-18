part of '../asc_upload_sheet.dart';

// ─── No Credentials Prompt ──────────────────────────────────────────

class _NoCredentialsPrompt extends StatelessWidget {
  final VoidCallback onConfigure;

  const _NoCredentialsPrompt({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.key_off,
              size: 28,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noApiKeyConfigured,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.ascApiKeySetupHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            onPressed: onConfigure,
            icon: Symbols.key,
            label: context.l10n.configureApiKey,
          ),
        ],
      ),
    );
  }
}
