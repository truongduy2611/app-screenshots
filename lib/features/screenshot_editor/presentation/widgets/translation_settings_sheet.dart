import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/utils/china_locale_helper.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/apple_fm_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:flutter/material.dart';

/// Dialog for selecting the active translation provider and entering API keys.
///
/// Uses the genie route animation when a [sourceRect] is provided.
class TranslationSettingsDialog extends StatefulWidget {
  const TranslationSettingsDialog({super.key});

  /// Show the settings dialog with a genie animation from [sourceRect].
  static Future<void> show(BuildContext context, {Rect? sourceRect}) {
    final rect = sourceRect ?? rectFromContext(context) ?? Rect.zero;
    return showGenieDialog(
      context: context,
      sourceRect: rect,
      builder: (_) => const TranslationSettingsDialog(),
    );
  }

  @override
  State<TranslationSettingsDialog> createState() =>
      _TranslationSettingsDialogState();
}

class _TranslationSettingsDialogState extends State<TranslationSettingsDialog> {
  final _repo = sl<AIProviderRepository>();
  AIProviderConfig _config = const AIProviderConfig();
  bool _loading = true;
  bool _saving = false;
  bool _appleFMAvailable = false;
  bool _obscureKey = true;

  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _repo.getConfig();
    final fmAvailable = await AppleFMTranslationProvider.isAvailable();
    setState(() {
      _config = config;
      _appleFMAvailable = fmAvailable;
      _apiKeyController.text = config.apiKey ?? '';
      _endpointController.text = config.customEndpoint ?? '';
      _modelController.text = config.customModel ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = _config.copyWith(
        apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
        customEndpoint: _endpointController.text.isEmpty
            ? null
            : _endpointController.text,
        customModel: _modelController.text.isEmpty
            ? null
            : _modelController.text,
      );
      await _repo.saveConfig(updated);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 420,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.translate_rounded,
                              size: 22,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.aiProviderSettings,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.chooseHowTextGetsTranslated,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Provider Picker ──
                      ..._buildProviderOptions(cs),

                      const SizedBox(height: 20),

                      // ── API Key field (hidden for Apple FM) ──
                      if (_config.activeProvider !=
                              AIProviderType.appleFM &&
                          _config.activeProvider !=
                              AIProviderType.manual) ...[
                        _buildTextField(
                          controller: _apiKeyController,
                          label: context.l10n.apiKey,
                          hint: _hintForProvider(_config.activeProvider),
                          obscureText: _obscureKey,
                          cs: cs,
                          theme: theme,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureKey
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _obscureKey = !_obscureKey),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                context.l10n.apiKeysStoredSecurely,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Custom endpoint fields ──
                      if (_config.activeProvider ==
                          AIProviderType.custom) ...[
                        _buildTextField(
                          controller: _endpointController,
                          label: context.l10n.endpointUrl,
                          hint: 'http://localhost:11434',
                          cs: cs,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Model name (OpenAI, Gemini, Custom) ──
                      if (_config.activeProvider !=
                              AIProviderType.appleFM &&
                          _config.activeProvider !=
                              AIProviderType.deepl) ...[
                        _buildTextField(
                          controller: _modelController,
                          label: context.l10n.model,
                          hint: _modelHintForProvider(_config.activeProvider),
                          cs: cs,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 8),

                      // ── Action Buttons ──
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              label: context.l10n.cancel,
                              isExpanded: true,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.primary(
                              label: context.l10n.save,
                              icon: Icons.check_rounded,
                              isLoading: _saving,
                              isExpanded: true,
                              onPressed: _save,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ColorScheme cs,
    required ThemeData theme,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: theme.textTheme.bodySmall,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        filled: true,
        fillColor: cs.surfaceContainerLow,
        suffixIcon: suffixIcon,
      ),
    );
  }

  List<Widget> _buildProviderOptions(ColorScheme cs) {
    final isChina = ChinaLocaleHelper.isChinaMainland(
      Localizations.localeOf(context),
    );
    final providers = [
      if (_appleFMAvailable) AIProviderType.appleFM,
      if (!isChina) AIProviderType.openai,
      if (!isChina) AIProviderType.gemini,
      if (!isChina) AIProviderType.deepl,
      AIProviderType.custom,
    ];

    return providers.map((type) {
      final selected = _config.activeProvider == type;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(
              () => _config = _config.copyWith(activeProvider: type),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.08)
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconForProvider(type),
                    size: 20,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labelForProvider(type),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _subtitleForProvider(type),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData _iconForProvider(AIProviderType type) => switch (type) {
    AIProviderType.appleFM => Icons.apple_rounded,
    AIProviderType.openai => Icons.auto_awesome_rounded,
    AIProviderType.gemini => Icons.diamond_rounded,
    AIProviderType.deepl => Icons.g_translate_rounded,
    AIProviderType.custom => Icons.dns_rounded,
    AIProviderType.manual => Icons.content_paste_rounded,
  };

  String _labelForProvider(AIProviderType type) => switch (type) {
    AIProviderType.appleFM => context.l10n.providerApple,
    AIProviderType.openai => context.l10n.providerOpenai,
    AIProviderType.gemini => context.l10n.providerGemini,
    AIProviderType.deepl => context.l10n.providerDeepl,
    AIProviderType.custom => context.l10n.providerCustom,
    AIProviderType.manual => context.l10n.providerManual,
  };

  String _subtitleForProvider(AIProviderType type) {
    if (type == AIProviderType.custom &&
        ChinaLocaleHelper.isChinaMainland(Localizations.localeOf(context))) {
      return '自定义 AI 端点';
    }
    return switch (type) {
      AIProviderType.appleFM => context.l10n.providerAppleSubtitle,
      AIProviderType.openai => context.l10n.providerOpenaiSubtitle,
      AIProviderType.gemini => context.l10n.providerGeminiSubtitle,
      AIProviderType.deepl => context.l10n.providerDeeplSubtitle,
      AIProviderType.custom => context.l10n.providerCustomSubtitle,
      AIProviderType.manual => context.l10n.providerManualSubtitle,
    };
  }

  String _hintForProvider(AIProviderType type) => switch (type) {
    AIProviderType.openai => 'sk-...',
    AIProviderType.gemini => 'AIza...',
    AIProviderType.deepl => 'xxxxxxxx-xxxx-...',
    _ => 'API key',
  };

  String _modelHintForProvider(AIProviderType type) => switch (type) {
    AIProviderType.openai => 'gpt-4o-mini',
    AIProviderType.gemini => 'gemini-2.0-flash',
    AIProviderType.custom => 'llama3.2',
    _ => 'model name',
  };
}
