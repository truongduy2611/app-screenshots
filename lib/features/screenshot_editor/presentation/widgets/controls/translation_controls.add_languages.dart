part of 'translation_controls.dart';

/// A multi-select dialog for adding extra (non-popular) target locales.
class _AddLanguagesDialog extends StatefulWidget {
  const _AddLanguagesDialog({required this.extras});

  final List<MapEntry<String, String>> extras;

  @override
  State<_AddLanguagesDialog> createState() => _AddLanguagesDialogState();
}

class _AddLanguagesDialogState extends State<_AddLanguagesDialog> {
  final _searchController = TextEditingController();
  late List<MapEntry<String, String>> _filtered;
  final Set<String> _checked = {};

  @override
  void initState() {
    super.initState();
    _filtered = widget.extras;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.extras;
      } else {
        _filtered = widget.extras
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
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
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
                          Symbols.add_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.addLanguages,
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
                          final isChecked = _checked.contains(entry.key);
                          return _LocaleTile(
                            code: entry.key,
                            name: entry.value,
                            isSelected: isChecked,
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  _checked.remove(entry.key);
                                } else {
                                  _checked.add(entry.key);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),

              // ── Action bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checked.isEmpty
                        ? null
                        : () => Navigator.pop(context, _checked.toList()),
                    icon: const Icon(Symbols.add_rounded, size: 18),
                    label: Text(
                      _checked.isEmpty
                          ? context.l10n.selectLanguages
                          : context.l10n.addNLanguages(_checked.length),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
