import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Visual variant for [AppSnackbar].
enum AppSnackbarType { success, error, info }

/// A premium styled overlay notification matching the app's design system.
///
/// Uses [Overlay] instead of [ScaffoldMessenger] so notifications always
/// render above everything, including dialogs and bottom sheets.
///
/// Use `context.showAppSnackbar(...)` for the simplest API.
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows an overlay-based snackbar notification above all other content.
  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.success,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // Dismiss any existing notification
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = Theme.of(context);

    _currentEntry = OverlayEntry(
      builder: (_) => _AppSnackbarOverlay(
        message: message,
        type: type,
        theme: theme,
        onAction: onAction,
        actionLabel: actionLabel,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);

    _dismissTimer = Timer(duration, dismiss);
  }

  /// Dismiss the currently showing notification, if any.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// The animated overlay widget for the snackbar.
class _AppSnackbarOverlay extends StatefulWidget {
  final String message;
  final AppSnackbarType type;
  final ThemeData theme;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback onDismiss;

  const _AppSnackbarOverlay({
    required this.message,
    required this.type,
    required this.theme,
    required this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  @override
  State<_AppSnackbarOverlay> createState() => _AppSnackbarOverlayState();
}

class _AppSnackbarOverlayState extends State<_AppSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    final (IconData icon, Color accent) = switch (widget.type) {
      AppSnackbarType.success => (
        Symbols.check_circle_rounded,
        theme.colorScheme.primary,
      ),
      AppSnackbarType.error => (Symbols.error_rounded, theme.colorScheme.error),
      AppSnackbarType.info => (
        Symbols.info_rounded,
        theme.colorScheme.tertiary,
      ),
    };

    final bgColor = isDark
        ? const Color(0xFF2C2C2E)
        : theme.colorScheme.surfaceContainerHighest;

    final fgColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : theme.colorScheme.onSurface;

    final screenWidth = MediaQuery.of(context).size.width;
    const maxWidth = 400.0;
    final horizontalMargin = screenWidth > maxWidth + 32
        ? (screenWidth - maxWidth) / 2
        : 16.0;

    return Positioned(
      left: horizontalMargin,
      right: horizontalMargin,
      bottom: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onHorizontalDragEnd: (_) => widget.onDismiss(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),

                    // Message
                    Expanded(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action button
                    if (widget.onAction != null &&
                        widget.actionLabel != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          widget.onAction!();
                          widget.onDismiss();
                        },
                        style: TextButton.styleFrom(foregroundColor: accent),
                        child: Text(widget.actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension for convenient snackbar access from [BuildContext].
extension AppSnackbarExtension on BuildContext {
  /// Shows a premium styled overlay snackbar above all content.
  ///
  /// ```dart
  /// context.showAppSnackbar('Saved!'); // success (default)
  /// context.showAppSnackbar('Oops', type: AppSnackbarType.error);
  /// ```
  void showAppSnackbar(
    String message, {
    AppSnackbarType type = AppSnackbarType.success,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AppSnackbar.show(
      this,
      message,
      type: type,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}
