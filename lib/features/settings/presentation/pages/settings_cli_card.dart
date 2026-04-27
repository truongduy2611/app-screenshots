part of 'settings_page.dart';

class _SettingsCliCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _SettingsCliCard({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CliCubit, bool>(
      builder: (context, isEnabled) {
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          color: isDark
              ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2)
              : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Symbols.terminal_rounded,
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                title: Text(
                  context.l10n.enableCliServer,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    context.l10n.enableCliServerDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                value: isEnabled,
                onChanged: (value) => context.read<CliCubit>().toggle(value),
              ),
              if (isEnabled) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.cliCompanionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.cliCompanionDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(
                            Symbols.open_in_new_rounded,
                            size: 18,
                          ),
                          label: Text(context.l10n.cliLearnMoreButton),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            launchUrl(
                              Uri.parse(
                                'https://appscreenshots.progressiostudio.com/cli',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
