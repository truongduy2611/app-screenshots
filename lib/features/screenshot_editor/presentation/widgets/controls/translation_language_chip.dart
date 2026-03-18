import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/translation_status_dot.dart';
import 'package:flutter/material.dart';

/// Maps a locale code to its corresponding flag emoji.
///
/// Uses the ISO 3166-1 alpha-2 country code and converts each letter to its
/// Regional Indicator Symbol.
String _flagForLocale(String code) {
  const localeToCountry = <String, String>{
    'en': 'US',
    'en-AU': 'AU',
    'en-CA': 'CA',
    'en-GB': 'GB',
    'es': 'ES',
    'es-MX': 'MX',
    'fr': 'FR',
    'fr-CA': 'CA',
    'de': 'DE',
    'it': 'IT',
    'pt-BR': 'BR',
    'pt-PT': 'PT',
    'ja': 'JP',
    'ko': 'KR',
    'zh-Hans': 'CN',
    'zh-Hant': 'TW',
    'ar': 'SA',
    'th': 'TH',
    'vi': 'VN',
    'ru': 'RU',
    'tr': 'TR',
    'nl': 'NL',
    'sv': 'SE',
    'da': 'DK',
    'id': 'ID',
    'ms': 'MY',
    'pl': 'PL',
    'uk': 'UA',
    'hi': 'IN',
    'el': 'GR',
    'no': 'NO',
    'fi': 'FI',
    'he': 'IL',
    'hu': 'HU',
    'cs': 'CZ',
    'ro': 'RO',
    'sk': 'SK',
    'hr': 'HR',
    'ca': 'ES',
    'bg': 'BG',
  };

  final country = localeToCountry[code];
  if (country == null || country.length != 2) return '';

  // Each ASCII uppercase letter → Regional Indicator Symbol
  const base = 0x1F1E6 - 0x41; // 'A' = 0x41
  final first = String.fromCharCode(base + country.codeUnitAt(0));
  final second = String.fromCharCode(base + country.codeUnitAt(1));
  return '$first$second';
}

/// A compact locale chip used in the target-language grid.
class TranslationLanguageChip extends StatelessWidget {
  final String code;
  final String name;
  final bool isSelected;
  final TranslationStatus? status;
  final VoidCallback onTap;

  const TranslationLanguageChip({
    required this.code,
    required this.name,
    required this.isSelected,
    required this.status,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flag = _flagForLocale(code);

    final Color bg;
    final Color fg;
    final Color border;

    if (isSelected) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.12);
      fg = theme.colorScheme.primary;
      border = theme.colorScheme.primary.withValues(alpha: 0.4);
    } else {
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      fg = theme.colorScheme.onSurfaceVariant;
      border = theme.colorScheme.outlineVariant.withValues(alpha: 0.2);
    }

    return Tooltip(
      message: name,
      waitDuration: const Duration(milliseconds: 400),
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_rounded, size: 12, color: fg),
                  const SizedBox(width: 3),
                ],
                if (flag.isNotEmpty) ...[
                  Text(flag, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                ],
                Text(
                  code.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.5,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 4),
                  TranslationStatusDot(status: status!, size: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
