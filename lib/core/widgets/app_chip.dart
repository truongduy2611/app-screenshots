import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A styled chip with selection state and optional icon.
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final bool compact;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = selectedColor ?? theme.colorScheme.primary;
    final hPad = compact ? 10.0 : 14.0;
    final vPad = compact ? 5.0 : 8.0;
    final radius = compact ? 12.0 : 20.0;
    final iconSize = compact ? 13.0 : 16.0;
    final textStyle = compact
        ? theme.textTheme.labelSmall
        : theme.textTheme.labelLarge;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: isSelected
                ? baseColor.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isSelected
                  ? baseColor.withValues(alpha: 0.4)
                  : theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize,
                  color: isSelected
                      ? baseColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: textStyle?.copyWith(
                  color: isSelected
                      ? baseColor
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
