import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium styled icon button with bounce animation and tinted background.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isSelected;
  final bool showBackground;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconColor,
    this.backgroundColor,
    this.isSelected = false,
    this.showBackground = true,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
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
      end: 0.85,
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
    final isEnabled = widget.onPressed != null;

    final effectiveIconColor =
        widget.iconColor ??
        (widget.isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant);

    final effectiveBgColor =
        widget.backgroundColor ??
        (widget.isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5));

    final button = MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed?.call();
              }
            : null,
        child: Listener(
          onPointerDown: isEnabled ? (_) => _controller.forward() : null,
          onPointerUp: isEnabled ? (_) => _bounceBack() : null,
          onPointerCancel: isEnabled ? (_) => _bounceBack() : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) =>
                Transform.scale(scale: _scaleAnimation.value, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.size,
              height: widget.size,
              decoration: widget.showBackground
                  ? BoxDecoration(
                      color: effectiveBgColor,
                      shape: BoxShape.circle,
                      border: widget.isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            )
                          : Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                            ),
                    )
                  : null,
              child: Icon(
                widget.icon,
                color: isEnabled ? effectiveIconColor : theme.disabledColor,
                size: widget.size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }

  void _bounceBack() {
    _controller.reverse().then((_) {
      if (mounted) {
        _controller
            .animateTo(
              -0.35,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            )
            .then((_) {
              if (mounted) {
                _controller.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeInOut,
                );
              }
            });
      }
    });
  }
}
