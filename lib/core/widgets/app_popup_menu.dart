import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium styled popup menu with smooth animations and modern design.
class AppPopupMenu<T> extends StatelessWidget {
  final Widget child;
  final List<AppPopupMenuItem<T>> items;
  final void Function(T)? onSelected;
  final Offset offset;
  final bool enabled;
  final String? tooltip;

  const AppPopupMenu({
    super.key,
    required this.child,
    required this.items,
    this.onSelected,
    this.offset = Offset.zero,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<T>(
      enabled: enabled,
      tooltip: tooltip ?? '',
      enableFeedback: true,
      offset: offset,
      elevation: 8,
      position: PopupMenuPosition.over,
      borderRadius: BorderRadius.circular(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor.withValues(alpha: 0.2),
      constraints: const BoxConstraints(minWidth: 180),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      onSelected: (value) {
        HapticFeedback.lightImpact();
        onSelected?.call(value);
      },
      itemBuilder: (context) =>
          items.map((item) => _buildMenuItem(context, theme, item)).toList(),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
    );
  }

  PopupMenuEntry<T> _buildMenuItem(
    BuildContext context,
    ThemeData theme,
    AppPopupMenuItem<T> item,
  ) {
    if (item.isDivider) {
      return const PopupMenuDivider(height: 16);
    }

    final isDestructive = item.isDestructive;
    final iconColor = isDestructive
        ? theme.colorScheme.error
        : item.iconColor ?? theme.colorScheme.primary;
    final textColor = isDestructive
        ? theme.colorScheme.error
        : item.textColor ?? theme.colorScheme.onSurface;

    return PopupMenuItem<T>(
      mouseCursor: SystemMouseCursors.click,
      value: item.value,
      enabled: item.enabled,
      height: 52,
      padding: EdgeInsets.zero,
      child: _PremiumMenuItem(
        icon: item.icon,
        iconColor: iconColor,
        title: item.title,
        subtitle: item.subtitle,
        textColor: textColor,
        trailing: item.trailing,
        enabled: item.enabled,
      ),
    );
  }
}

/// Internal widget for menu item with tap effect.
class _PremiumMenuItem extends StatefulWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color textColor;
  final Widget? trailing;
  final bool enabled;

  const _PremiumMenuItem({
    this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.textColor,
    this.trailing,
    required this.enabled,
  });

  @override
  State<_PremiumMenuItem> createState() => _PremiumMenuItemState();
}

class _PremiumMenuItemState extends State<_PremiumMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: widget.enabled
          ? (_) {
              _controller.forward();
              setState(() => _isPressed = true);
            }
          : null,
      onPointerUp: widget.enabled
          ? (_) {
              _controller.reverse();
              setState(() => _isPressed = false);
            }
          : null,
      onPointerCancel: widget.enabled
          ? (_) {
              _controller.reverse();
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isPressed
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? widget.iconColor.withValues(alpha: 0.2)
                        : widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.enabled
                        ? widget.iconColor
                        : theme.disabledColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: widget.enabled
                            ? widget.textColor
                            : theme.disabledColor,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single item in the popup menu.
class AppPopupMenuItem<T> {
  final T? value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final bool enabled;
  final bool isDestructive;
  final bool isDivider;

  const AppPopupMenuItem({
    this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.textColor,
    this.trailing,
    this.enabled = true,
    this.isDestructive = false,
    this.isDivider = false,
  });

  /// Creates a divider item.
  const AppPopupMenuItem.divider()
    : value = null,
      title = '',
      subtitle = null,
      icon = null,
      iconColor = null,
      textColor = null,
      trailing = null,
      enabled = true,
      isDestructive = false,
      isDivider = true;
}

/// A premium styled trigger button for popup menus with bounce effect.
class AppPopupMenuButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppPopupMenuButton({
    super.key,
    required this.icon,
    this.size = 36,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<AppPopupMenuButton> createState() => _AppPopupMenuButtonState();
}

class _AppPopupMenuButtonState extends State<AppPopupMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) => _controller.forward(),
        onPointerUp: (_) => _controller.reverse(),
        onPointerCancel: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ??
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              widget.icon,
              color: widget.iconColor ?? theme.colorScheme.onSurfaceVariant,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to easily show popup menus at a position.
extension AppPopupMenuExtension on BuildContext {
  Future<T?> showAppPopupMenu<T>({
    required RelativeRect position,
    required List<AppPopupMenuItem<T>> items,
  }) {
    final theme = Theme.of(this);

    return showMenu<T>(
      context: this,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor.withValues(alpha: 0.2),
      constraints: const BoxConstraints(minWidth: 180),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      items: items.map((item) {
        if (item.isDivider) {
          return const PopupMenuDivider(height: 16) as PopupMenuEntry<T>;
        }

        final isDestructive = item.isDestructive;
        final iconColor = isDestructive
            ? theme.colorScheme.error
            : item.iconColor ?? theme.colorScheme.primary;
        final textColor = isDestructive
            ? theme.colorScheme.error
            : item.textColor ?? theme.colorScheme.onSurface;

        return PopupMenuItem<T>(
          mouseCursor: SystemMouseCursors.click,
          value: item.value,
          enabled: item.enabled,
          height: 52,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.enabled ? iconColor : theme.disabledColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: item.enabled ? textColor : theme.disabledColor,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.trailing != null) ...[
                  const SizedBox(width: 8),
                  item.trailing!,
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
