import 'package:flutter/material.dart';

/// A premium styled list tile matching the app's design system.
///
/// Features hover highlight, press-scale animation, rounded corners,
/// and consistent theme treatment for both light and dark modes.
class AppListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onSecondaryTapDown;
  final EdgeInsetsGeometry contentPadding;
  final double borderRadius;
  final bool isHighlighted;

  const AppListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    this.borderRadius = 12,
    this.isHighlighted = false,
  });

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final isTappable = widget.onTap != null || widget.onLongPress != null;

    final bgColor = widget.isHighlighted
        ? primary.withValues(alpha: isDark ? 0.15 : 0.1)
        : _isHovering
        ? primary.withValues(alpha: isDark ? 0.06 : 0.03)
        : Colors.transparent;

    final borderColor = widget.isHighlighted
        ? primary.withValues(alpha: 0.4)
        : _isHovering
        ? primary.withValues(alpha: isDark ? 0.12 : 0.06)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: isTappable ? (_) => _controller.forward() : null,
        onPointerUp: isTappable ? (_) => _controller.reverse() : null,
        onPointerCancel: isTappable ? (_) => _controller.reverse() : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onSecondaryTapDown: widget.onSecondaryTapDown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: widget.contentPadding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null) widget.title!,
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          widget.subtitle!,
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 12),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
