part of 'settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI Keys Section
// ─────────────────────────────────────────────────────────────────────────────

class _AiKeysSection extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;

  const _AiKeysSection({required this.isDark, required this.theme});

  @override
  State<_AiKeysSection> createState() => _AiKeysSectionState();
}

class _AiKeysSectionState extends State<_AiKeysSection> {
  AIProviderConfig _config = const AIProviderConfig();
  bool _loading = true;
  final _tileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await sl<AIProviderRepository>().getConfig();
    if (mounted) {
      setState(() {
        _config = config;
        _loading = false;
      });
    }
  }

  String _maskedApiKey(String? key) {
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••${key.substring(key.length - 4)}';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  String _providerLabel(AIProviderType type) {
    switch (type) {
      case AIProviderType.appleFM:
        return 'Apple FM';
      case AIProviderType.gemini:
        return 'Gemini';
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.deepl:
        return 'DeepL';
      case AIProviderType.custom:
        return 'Custom';
      case AIProviderType.manual:
        return 'Manual';
    }
  }

  Rect? _getTileRect() {
    final box = _tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = _config.apiKey != null && _config.apiKey!.isNotEmpty;

    String subtitle;
    if (_loading) {
      subtitle = context.l10n.apiKeyLoading;
    } else {
      // If China locale and a restricted provider is saved, show Apple FM.
      final isChina = ChinaLocaleHelper.isChinaMainland(
        Localizations.localeOf(context),
      );
      final effectiveProvider =
          isChina &&
              (_config.activeProvider == AIProviderType.openai ||
                  _config.activeProvider == AIProviderType.gemini ||
                  _config.activeProvider == AIProviderType.deepl)
          ? AIProviderType.custom
          : _config.activeProvider;

      if (effectiveProvider == AIProviderType.appleFM) {
        subtitle = _providerLabel(effectiveProvider);
      } else if (hasApiKey) {
        subtitle =
            '${_providerLabel(effectiveProvider)}  •  ${_maskedApiKey(_config.apiKey)}';
      } else {
        subtitle = context.l10n.aiKeyNotConfigured;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsTileGroup(
          isDark: widget.isDark,
          theme: widget.theme,
          children: [
            Builder(
              key: _tileKey,
              builder: (_) => _SettingsTile(
                icon: Symbols.auto_awesome_rounded,
                title: context.l10n.aiProviderSettings,
                subtitle: subtitle,
                theme: widget.theme,
                onTap: () async {
                  await TranslationSettingsDialog.show(
                    context,
                    sourceRect: _getTileRect(),
                  );
                  // Reload config after dialog is closed
                  _loadConfig();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 4),
            Icon(
              Symbols.lock_rounded,
              size: 13,
              color: widget.theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.l10n.apiKeysStoredSecurely,
                style: widget.theme.textTheme.labelSmall?.copyWith(
                  color: widget.theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
