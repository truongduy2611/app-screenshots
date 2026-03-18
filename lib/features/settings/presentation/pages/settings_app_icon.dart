part of 'settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App Icon Card
// ─────────────────────────────────────────────────────────────────────────────

class _AppIconCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Widget iconWidget;
  final ThemeData theme;
  final VoidCallback onTap;

  const _AppIconCard({
    required this.label,
    required this.isSelected,
    required this.iconWidget,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  )
                : isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  )
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.15 : 0.2,
                    ),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              iconWidget,
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
