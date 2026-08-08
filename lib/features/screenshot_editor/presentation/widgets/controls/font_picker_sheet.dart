import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/font_resolver.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class FontPickerSheet extends StatefulWidget {
  final String selectedFont;
  final ValueChanged<String> onFontSelected;

  const FontPickerSheet({
    super.key,
    required this.selectedFont,
    required this.onFontSelected,
  });

  @override
  State<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends State<FontPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _allFonts;
  late List<String> _filteredFonts;

  @override
  void initState() {
    super.initState();
    const nativeFonts = [
      'SF Pro',
      'SF Pro Rounded',
      'SF Compact',
      'SF Compact Rounded',
      'SF Mono',
      'New York',
    ];
    final keys = GoogleFonts.asMap().keys.toList();
    if (!keys.contains('Google Sans Rounded')) {
      final index = keys.indexOf('Google Sans');
      if (index != -1) {
        keys.insert(index + 1, 'Google Sans Rounded');
      } else {
        keys.insert(0, 'Google Sans Rounded');
      }
    }
    _allFonts = [
      ...nativeFonts,
      ...keys.where((k) => !nativeFonts.contains(k)),
    ];
    _filteredFonts = _allFonts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFonts = _allFonts;
      } else {
        _filteredFonts = _allFonts
            .where((font) => font.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                context.l10n.selectFont,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Symbols.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.searchFonts,
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                Symbols.search_rounded,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredFonts.length,
            itemBuilder: (context, index) {
              final font = _filteredFonts[index];
              final isSelected = font == widget.selectedFont;
              return ListTile(
                selected: isSelected,
                title: Text(
                  font,
                  style: FontResolver.apply(font, const TextStyle()),
                ),
                trailing: isSelected
                    ? const Icon(Symbols.check_rounded, color: Colors.blue)
                    : null,
                onTap: () {
                  widget.onFontSelected(font);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

