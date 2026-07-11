part of 'settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Google Play Service Account Section
// ─────────────────────────────────────────────────────────────────────────────

class _PlayCredentialsSection extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;

  const _PlayCredentialsSection({required this.isDark, required this.theme});

  @override
  State<_PlayCredentialsSection> createState() =>
      _PlayCredentialsSectionState();
}

class _PlayCredentialsSectionState extends State<_PlayCredentialsSection> {
  PlayCredentials? _credentials;
  bool _loading = true;
  final _tileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final creds = await sl<SettingsRepository>().getPlayCredentials();
    if (mounted) {
      setState(() {
        _credentials = creds;
        _loading = false;
      });
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
    final isConfigured = _credentials?.isValid ?? false;

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
                icon: Symbols.android_rounded,
                title: context.l10n.googlePlayServiceAccount,
                subtitle: _loading
                    ? context.l10n.apiKeyLoading
                    : isConfigured
                    ? _credentials!.clientEmail
                    : context.l10n.apiKeyNotConfigured,
                theme: widget.theme,
                onTap: () async {
                  await PlayCredentialsDialog.show(
                    context,
                    sourceRect: _getTileRect(),
                  );
                  // Reload unconditionally so clearing also refreshes the tile.
                  _loadCredentials();
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
