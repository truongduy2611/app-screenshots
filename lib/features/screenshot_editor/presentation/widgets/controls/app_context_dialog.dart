import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Genie dialog for editing the per-design app context (custom prompt).
class AppContextDialog {
  AppContextDialog._();

  /// Show the App Context editing dialog with a genie animation.
  static void show(
    BuildContext context, {
    required BuildContext anchorContext,
    String? currentPrompt,
  }) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentPrompt ?? '');

    final sourceRect = rectFromContext(anchorContext);
    if (sourceRect == null) return;

    showGenieDialog(
      context: context,
      sourceRect: sourceRect,
      barrierDismissible: true,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Symbols.description_rounded,
                      size: 20,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.appContextDialogTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.appContextDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.l10n.appContextHint,
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (currentPrompt?.isNotEmpty == true)
                      TextButton(
                        onPressed: () {
                          context.read<TranslationCubit>().setCustomPrompt(
                            null,
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          context.l10n.clear,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        context.read<TranslationCubit>().setCustomPrompt(
                          controller.text,
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(context.l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
