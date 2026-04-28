part of 'settings_page.dart';

class _SettingsCliCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _SettingsCliCard({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    return BlocBuilder<CliCubit, bool>(
      builder: (context, isEnabled) {
        return Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.tertiary.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  theme.colorScheme.secondary.withValues(
                    alpha: isDark ? 0.1 : 0.06,
                  ),
                ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: theme.colorScheme.tertiary.withValues(
                  alpha: isDark ? 0.2 : 0.12,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppListTile(
                  leading: Icon(
                    Symbols.terminal_rounded,
                    size: 20,
                    color: theme.colorScheme.tertiary,
                  ),
                  title: Text(
                    context.l10n.enableCliServer,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.enableCliServerDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  trailing: AppSwitch(
                    value: isEnabled,
                    onChanged: (value) => context.read<CliCubit>().toggle(value),
                  ),
                  onTap: () => context.read<CliCubit>().toggle(!isEnabled),
                ),
                if (isEnabled) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.tertiary.withValues(
                      alpha: isDark ? 0.2 : 0.15,
                    ),
                  ),
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
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              FilledButton.tonalIcon(
                                icon: const Icon(Symbols.api_rounded, size: 18),
                                label: const Text('Open API Explorer'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse('http://localhost:19222/api/docs'),
                                  );
                                },
                              ),
                              FilledButton.tonalIcon(
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
