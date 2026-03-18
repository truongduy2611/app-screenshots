import 'package:flutter/material.dart';

/// Shows a premium styled bottom sheet with rounded top corners and drag handle.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  double? maxHeight,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    constraints: maxHeight != null
        ? BoxConstraints(maxHeight: maxHeight)
        : null,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Flexible(child: builder(context)),
        ],
      );
    },
  );
}

/// A bottom sheet with a title bar, drag handle, and close button.
Future<T?> showAppBottomSheetWithTitle<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  double? maxHeight,
  List<Widget>? actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    constraints: maxHeight != null
        ? BoxConstraints(maxHeight: maxHeight)
        : null,
    builder: (context) {
      final theme = Theme.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (actions != null) ...actions,
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(child: builder(context)),
        ],
      );
    },
  );
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
