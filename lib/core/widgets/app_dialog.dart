import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:flutter/material.dart';

/// A premium confirmation dialog with title, content, and action buttons.
class AppDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;
  final double maxWidth;

  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
    this.maxWidth = 320,
  });

  /// Shows this dialog and returns true if confirmed, false/null otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? content,
    Widget? contentWidget,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
    Rect? sourceRect,
    double maxWidth = 320,
  }) {
    final dialog = AppDialog(
      title: title,
      content: content,
      contentWidget: contentWidget,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
      maxWidth: maxWidth,
    );

    if (sourceRect != null) {
      return showGenieDialog<bool>(
        context: context,
        sourceRect: sourceRect,
        builder: (context) => dialog,
      );
    }

    return showDialog<bool>(context: context, builder: (context) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return AlertDialog(
      constraints: BoxConstraints(maxWidth: maxWidth),
      icon: icon != null
          ? Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            )
          : null,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content:
          contentWidget ??
          (content != null
              ? Text(
                  content!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: cancelLabel,
                onPressed: onCancel ?? () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isDestructive
                  ? AppButton.destructive(
                      label: confirmLabel,
                      onPressed:
                          onConfirm ?? () => Navigator.of(context).pop(true),
                    )
                  : AppButton.primary(
                      label: confirmLabel,
                      onPressed:
                          onConfirm ?? () => Navigator.of(context).pop(true),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows a text input dialog and returns the entered text.
Future<String?> showAppInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hintText,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  Rect? sourceRect,
}) {
  final controller = TextEditingController(text: initialValue);

  Widget buildDialog(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hintText),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(controller.text),
              ),
            ),
          ],
        ),
      ],
    );
  }

  if (sourceRect != null) {
    return showGenieDialog<String>(
      context: context,
      sourceRect: sourceRect,
      builder: buildDialog,
    );
  }

  return showDialog<String>(context: context, builder: buildDialog);
}
