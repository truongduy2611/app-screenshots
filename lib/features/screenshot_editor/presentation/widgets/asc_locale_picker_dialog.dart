import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Dialog that lets the user pick which locales to render for ASC upload.
///
/// Returns the set of selected locale codes, or null if cancelled.
class AscLocalePickerDialog extends StatefulWidget {
  /// All available locales (source + targets) from the translation bundle.
  final List<String> allLocales;

  /// The source locale (always shown first, always pre-selected).
  final String sourceLocale;

  const AscLocalePickerDialog({
    super.key,
    required this.allLocales,
    required this.sourceLocale,
  });

  /// Shows the dialog and returns the selected locale set, or null if cancelled.
  static Future<Set<String>?> show({
    required BuildContext context,
    required List<String> allLocales,
    required String sourceLocale,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (_) => Dialog(
        child: AscLocalePickerDialog(
          allLocales: allLocales,
          sourceLocale: sourceLocale,
        ),
      ),
    );
  }

  @override
  State<AscLocalePickerDialog> createState() => _AscLocalePickerDialogState();
}

class _AscLocalePickerDialogState extends State<AscLocalePickerDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    // Pre-select all locales.
    _selected = widget.allLocales.toSet();
  }

  bool get _allSelected => _selected.length == widget.allLocales.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isSmall ? screenWidth - 16 : 440,
        maxHeight: isSmall ? MediaQuery.sizeOf(context).height * 0.85 : 560,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Symbols.translate_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.selectLocalesToUpload,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.onlySelectedLocalesWillBeRendered,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Select All / Deselect All ──
            Row(
              children: [
                Text(
                  context.l10n.localesHeader,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${_selected.length}/${widget.allLocales.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_allSelected) {
                          _selected.clear();
                        } else {
                          _selected.addAll(widget.allLocales);
                        }
                      });
                    },
                    child: Text(
                      _allSelected
                          ? context.l10n.deselectAll
                          : context.l10n.selectAll,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Locale list ──
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListView.builder(
                  itemCount: widget.allLocales.length,
                  itemBuilder: (context, index) {
                    final locale = widget.allLocales[index];
                    final isSource = locale == widget.sourceLocale;
                    final isSelected = _selected.contains(locale);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(locale);
                          } else {
                            _selected.add(locale);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _selected.remove(locale);
                                    } else {
                                      _selected.add(locale);
                                    }
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.5)
                                    : theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                locale.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (isSource) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  context.l10n.source,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Continue button ──
            AppButton.primary(
              onPressed: _selected.isNotEmpty
                  ? () => Navigator.of(context).pop(_selected)
                  : null,
              icon: Symbols.arrow_forward_rounded,
              label: _selected.isEmpty
                  ? context.l10n.selectLocalesToUpload
                  : context.l10n.renderNLocales(_selected.length),
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}
