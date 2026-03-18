import 'package:flutter/material.dart';

/// A premium styled card with consistent design system tokens.
class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isSelected;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.isSelected = false,
    this.backgroundColor,
    this.border,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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
    final isTappable = widget.onTap != null || widget.onLongPress != null;

    final effectiveBgColor =
        widget.backgroundColor ??
        (widget.isSelected
            ? theme.colorScheme.primaryContainer
            : theme.cardTheme.color ?? theme.colorScheme.surfaceContainer);

    final effectiveBorder =
        widget.border ??
        (widget.isSelected
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              )
            : Border.all(color: theme.dividerColor.withValues(alpha: 0.1)));

    return Listener(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: effectiveBorder,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
