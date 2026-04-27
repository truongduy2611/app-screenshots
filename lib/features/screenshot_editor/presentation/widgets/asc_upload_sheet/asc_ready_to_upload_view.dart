part of '../asc_upload_sheet.dart';

// ─── Ready to Upload ────────────────────────────────────────────────

class _ReadyToUploadView extends StatelessWidget {
  final App? app;
  final String versionString;
  final String displayType;
  final String platform;
  final Map<String, List<File>> localeScreenshots;
  final Set<String> selectedLocales;
  final VoidCallback onUpload;
  final ValueChanged<String> onDisplayTypeChanged;
  final ValueChanged<String> onPlatformChanged;
  final VoidCallback onChangeApp;
  final ValueChanged<String> onToggleLocale;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final bool deleteExisting;
  final ValueChanged<bool> onDeleteExistingChanged;
  final bool rememberApp;
  final ValueChanged<bool> onRememberAppChanged;

  const _ReadyToUploadView({
    required this.app,
    required this.versionString,
    required this.displayType,
    required this.platform,
    required this.localeScreenshots,
    required this.selectedLocales,
    required this.onUpload,
    required this.onDisplayTypeChanged,
    required this.onPlatformChanged,
    required this.onChangeApp,
    required this.onToggleLocale,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.deleteExisting,
    required this.onDeleteExistingChanged,
    required this.rememberApp,
    required this.onRememberAppChanged,
  });

  int get _totalSelectedFiles {
    int count = 0;
    for (final entry in localeScreenshots.entries) {
      if (selectedLocales.contains(entry.key)) {
        count += entry.value.length;
      }
    }
    return count;
  }

  bool get _allSelected => selectedLocales.length == localeScreenshots.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Map<String, String> displayTypes;
    switch (platform) {
      case 'IMESSAGE':
        displayTypes = _iMessageDisplayTypes;
      case 'MAC_OS':
        displayTypes = _macDisplayTypes;
      case 'WATCH_OS':
        displayTypes = _watchDisplayTypes;
      default:
        displayTypes = _iosDisplayTypes;
    }
    final effectiveDisplayType = displayTypes.containsKey(displayType)
        ? displayType
        : displayTypes.keys.first;
    final totalFiles = _totalSelectedFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── App info card ──
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _AppIcon(iconUrl: app?.iconUrl, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app?.name ?? '',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'v$versionString',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            app?.bundleId ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onChangeApp,
                icon: Icon(
                  Symbols.swap_horiz_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                tooltip: context.l10n.changeApp,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Platform selector ──
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'IOS',
              label: const Text('iOS'),
              icon: SFIcon(SFIcons.sf_iphone, fontSize: 16),
            ),
            ButtonSegment(
              value: 'IMESSAGE',
              label: const Text('iMessage'),
              icon: SFIcon(SFIcons.sf_message_fill, fontSize: 16),
            ),
            ButtonSegment(
              value: 'MAC_OS',
              label: const Text('macOS'),
              icon: SFIcon(SFIcons.sf_macbook, fontSize: 16),
            ),
            ButtonSegment(
              value: 'WATCH_OS',
              label: const Text('watchOS'),
              icon: SFIcon(SFIcons.sf_applewatch, fontSize: 16),
            ),
          ],
          selected: {platform},
          onSelectionChanged: (s) => onPlatformChanged(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 14),

        // ── Display type dropdown ──
        DropdownButtonFormField<String>(
          initialValue: effectiveDisplayType,
          decoration: InputDecoration(
            labelText: context.l10n.screenshotDisplayType,
          ),
          icon: const Icon(Symbols.keyboard_arrow_down_rounded, size: 22),
          borderRadius: BorderRadius.circular(14),
          items: displayTypes.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) {
            if (value != null) onDisplayTypeChanged(value);
          },
        ),
        const SizedBox(height: 14),

        // ── Override / Append toggle ──
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: Text(context.l10n.replace),
              icon: Icon(Symbols.delete_sweep, size: 18),
            ),
            ButtonSegment(
              value: false,
              label: Text(context.l10n.append),
              icon: Icon(Symbols.add_photo_alternate, size: 18),
            ),
          ],
          selected: {deleteExisting},
          onSelectionChanged: (s) => onDeleteExistingChanged(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 8),

        // ── Remember app toggle ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.rememberForThisDesign,
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    rememberApp
                        ? context.l10n.willSkipAppSelectionNextTime
                        : context.l10n.youllPickTheAppEachTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSwitch(value: rememberApp, onChanged: onRememberAppChanged),
          ],
        ),
        const SizedBox(height: 14),
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
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _allSelected ? onDeselectAll : onSelectAll,
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
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: localeScreenshots.entries.map((entry) {
              final locale = entry.key;
              final fileCount = entry.value.length;
              final isSelected = selectedLocales.contains(locale);
              return _LocaleCheckTile(
                locale: locale,
                fileCount: fileCount,
                isSelected: isSelected,
                onChanged: () => onToggleLocale(locale),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // ── Upload summary ──
        if (selectedLocales.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Symbols.info_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: context.l10n.nScreenshots(totalFiles),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' ${context.l10n.across} '),
                          TextSpan(
                            text: context.l10n.nLocales(selectedLocales.length),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Upload button ──
        AppButton.primary(
          onPressed: selectedLocales.isNotEmpty ? onUpload : null,
          icon: Symbols.cloud_upload,
          label: selectedLocales.isEmpty
              ? context.l10n.selectLocalesToUpload
              : context.l10n.uploadNLocales(selectedLocales.length),
          isExpanded: true,
        ),
      ],
    );
  }
}

/// Checkbox tile for selecting a locale to upload.
class _LocaleCheckTile extends StatelessWidget {
  final String locale;
  final int fileCount;
  final bool isSelected;
  final VoidCallback onChanged;

  const _LocaleCheckTile({
    required this.locale,
    required this.fileCount,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onChanged(),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
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
            const Spacer(),
            Text(
              '$fileCount ${context.l10n.nFiles(fileCount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
