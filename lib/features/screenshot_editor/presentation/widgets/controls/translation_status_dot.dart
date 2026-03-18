import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:flutter/material.dart';

/// A small status indicator dot for translation progress.
class TranslationStatusDot extends StatelessWidget {
  final TranslationStatus status;
  final double size;

  const TranslationStatusDot({required this.status, this.size = 10, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case TranslationStatus.translating:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        );
      case TranslationStatus.done:
        return Icon(
          Icons.check_circle_rounded,
          size: size + 2,
          color: const Color(0xFF34C759),
        );
      case TranslationStatus.idle:
        return SizedBox(width: size, height: size);
      case TranslationStatus.error:
        return Icon(
          Icons.error_rounded,
          size: size + 2,
          color: theme.colorScheme.error,
        );
    }
  }
}
