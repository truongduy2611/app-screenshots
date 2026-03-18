part of 'settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App Store Connect Credentials Section
// ─────────────────────────────────────────────────────────────────────────────

class _AscCredentialsSection extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;

  const _AscCredentialsSection({required this.isDark, required this.theme});

  @override
  State<_AscCredentialsSection> createState() => _AscCredentialsSectionState();
}

class _AscCredentialsSectionState extends State<_AscCredentialsSection> {
  AscCredentials? _credentials;
  bool _loading = true;
  final _tileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final creds = await sl<SettingsRepository>().getAscCredentials();
    if (mounted) {
      setState(() {
        _credentials = creds;
        _loading = false;
      });
    }
  }

  String _maskedKeyId(String keyId) {
    if (keyId.length <= 4) return '****$keyId';
    return '****${keyId.substring(keyId.length - 4)}';
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
                icon: Symbols.key_rounded,
                title: context.l10n.apiKeySettingsTitle,
                subtitle: _loading
                    ? context.l10n.apiKeyLoading
                    : isConfigured
                    ? context.l10n.apiKeyConfigured(
                        _maskedKeyId(_credentials!.keyId),
                      )
                    : context.l10n.apiKeyNotConfigured,
                theme: widget.theme,
                onTap: () async {
                  final saved = await AscCredentialsDialog.show(
                    context,
                    sourceRect: _getTileRect(),
                  );
                  if (saved) _loadCredentials();
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
