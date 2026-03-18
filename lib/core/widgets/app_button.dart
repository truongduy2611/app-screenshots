import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Button style variants for [AppButton].
enum AppButtonVariant { filled, tonal, outlined, text }

/// A premium styled button with bounce animation and design system integration.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isDestructive;
  final bool isExpanded;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.isDestructive = false,
    this.isExpanded = false,
    this.isLoading = false,
  });

  /// Primary filled button.
  const AppButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.filled,
       isDestructive = false;

  /// Secondary tonal button.
  const AppButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.tonal,
       isDestructive = false;

  /// Outlined button.
  const AppButton.outlined({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.outlined,
       isDestructive = false;

  /// Text-only button.
  const AppButton.text({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.text,
       isDestructive = false;

  /// Destructive action button.
  const AppButton.destructive({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.filled,
       isDestructive = true;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
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
      end: 0.92,
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final destructiveColor = theme.colorScheme.error;

    final child = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.variant == AppButtonVariant.filled
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(widget.label),
            ],
          );

    Widget button;
    switch (widget.variant) {
      case AppButtonVariant.filled:
        button = FilledButton(
          onPressed: isEnabled ? _handlePress : null,
          style: widget.isDestructive
              ? FilledButton.styleFrom(backgroundColor: destructiveColor)
              : null,
          child: child,
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: isEnabled ? _handlePress : null,
          child: child,
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isEnabled ? _handlePress : null,
          child: child,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? _handlePress : null,
          child: child,
        );
    }

    if (widget.isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Listener(
      onPointerDown: isEnabled ? (_) => _controller.forward() : null,
      onPointerUp: isEnabled ? (_) => _bounceBack() : null,
      onPointerCancel: isEnabled ? (_) => _bounceBack() : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: button,
      ),
    );
  }

  void _bounceBack() {
    _controller.reverse().then((_) {
      if (mounted) {
        // Overshoot: scale up slightly beyond 1.0, then settle
        _controller
            .animateTo(
              -0.3, // Negative value → scale goes above 1.0 (1.0 + 0.3*0.08 ≈ 1.024)
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

  void _handlePress() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }
}
