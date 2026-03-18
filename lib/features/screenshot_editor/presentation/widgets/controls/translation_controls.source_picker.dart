part of 'translation_controls.dart';

/// A searchable picker dialog for the source language.
///
/// Pops up as a genie dialog from the anchor, shows a search field and a
/// scrollable list of locale options with check-mark highlighting.
class _SourceLanguagePickerDialog extends StatefulWidget {
  const _SourceLanguagePickerDialog({
    required this.availableLocales,
    required this.currentLocale,
  });

  final Map<String, String> availableLocales;
  final String currentLocale;

  /// Shows the picker as a genie dialog anchored to [anchorContext].
  static Future<String?> show({
    required BuildContext context,
    required BuildContext anchorContext,
    required Map<String, String> availableLocales,
    required String currentLocale,
  }) {
    final srcRect = rectFromContext(anchorContext);
    if (srcRect == null) return Future.value();

    return showGenieDialog<String>(
      context: context,
      sourceRect: srcRect,
      builder: (_) => _SourceLanguagePickerDialog(
        availableLocales: availableLocales,
        currentLocale: currentLocale,
      ),
    );
  }

  @override
  State<_SourceLanguagePickerDialog> createState() =>
      _SourceLanguagePickerDialogState();
}

class _SourceLanguagePickerDialogState
    extends State<_SourceLanguagePickerDialog> {
  final _searchController = TextEditingController();
  late List<MapEntry<String, String>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.availableLocales.entries.toList();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.availableLocales.entries.toList();
      } else {
        _filtered = widget.availableLocales.entries
            .where(
              (e) =>
                  e.key.toLowerCase().contains(query) ||
                  e.value.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header + Search ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Symbols.language_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.sourceLanguage,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Symbols.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: theme.textTheme.bodySmall,
                      decoration: InputDecoration(
                        hintText: context.l10n.searchLanguage,
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        prefixIcon: Icon(
                          Symbols.search_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Locale List ──
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.noLanguagesFound,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final entry = _filtered[index];
                          final isSelected = entry.key == widget.currentLocale;
                          return _LocaleTile(
                            code: entry.key,
                            name: entry.value,
                            isSelected: isSelected,
                            onTap: () => Navigator.pop(context, entry.key),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
