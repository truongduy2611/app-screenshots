import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Horizontal pill bar for switching the canvas preview locale.
///
/// Shows source locale + all target locales. The active one is highlighted.
/// Null selection means "show original (source) text".
class LocaleSwitcher extends StatelessWidget {
  const LocaleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, state) {
        if (state.bundle == null || state.bundle!.targetLocales.isEmpty) {
          return const SizedBox.shrink();
        }

        final bundle = state.bundle!;
        final allLocales = [bundle.sourceLocale, ...bundle.targetLocales];
        final activeLocale = state.previewLocale ?? bundle.sourceLocale;
        final theme = Theme.of(context);

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allLocales.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final locale = allLocales[index];
              final isSource = index == 0;
              final isActive = locale == activeLocale;
              final status = isSource ? null : state.localeStatuses[locale];

              return _LocalePill(
                locale: locale,
                isActive: isActive,
                isSource: isSource,
                status: status,
                onTap: () {
                  final cubit = context.read<TranslationCubit>();
                  cubit.setPreviewLocale(isSource ? null : locale);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _LocalePill extends StatelessWidget {
  final String locale;
  final bool isActive;
  final bool isSource;
  final TranslationStatus? status;
  final VoidCallback onTap;

  const _LocalePill({
    required this.locale,
    required this.isActive,
    required this.isSource,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bg;
    final Color fg;
    final Color borderColor;

    if (isActive) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
      borderColor = theme.colorScheme.primary;
    } else {
      bg = theme.colorScheme.surface;
      fg = theme.colorScheme.onSurfaceVariant;
      borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSource) ...[
                Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: isActive
                      ? fg.withValues(alpha: 0.7)
                      : theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                _localeLabels[locale] ?? locale.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.5,
                ),
              ),
              if (status == TranslationStatus.translating) ...[
                const SizedBox(width: 5),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(
                      isActive ? fg : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ] else if (status == TranslationStatus.done) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: isActive ? fg : const Color(0xFF34C759),
                ),
              ] else if (status == TranslationStatus.error) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.error_rounded,
                  size: 12,
                  color: isActive ? fg : theme.colorScheme.error,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _localeLabels = <String, String>{
    'en': 'EN',
    'en-US': 'EN',
    'en-GB': 'EN-GB',
    'es': 'ES',
    'es-MX': 'ES-MX',
    'fr': 'FR',
    'fr-CA': 'FR-CA',
    'de': 'DE',
    'it': 'IT',
    'pt': 'PT',
    'pt-BR': 'PT-BR',
    'ja': 'JA',
    'ko': 'KO',
    'zh-Hans': 'ZH-CN',
    'zh-Hant': 'ZH-TW',
    'ar': 'AR',
    'th': 'TH',
    'vi': 'VI',
    'id': 'ID',
    'ms': 'MS',
    'tr': 'TR',
    'nl': 'NL',
    'ru': 'RU',
    'pl': 'PL',
    'uk': 'UK',
    'sv': 'SV',
    'da': 'DA',
    'no': 'NO',
    'fi': 'FI',
    'el': 'EL',
    'hi': 'HI',
  };
}
