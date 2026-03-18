import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_card.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/settings/domain/entities/asc_credentials.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Reusable dialog for entering / editing ASC API credentials.
///
/// Returns `true` if the user saved valid credentials, `false` otherwise.
class AscCredentialsDialog extends StatefulWidget {
  const AscCredentialsDialog({super.key});

  /// Shows the dialog and returns `true` when valid credentials are saved.
  ///
  /// When [sourceRect] is provided the dialog opens with a genie animation
  /// from the source widget; otherwise it uses a standard dialog transition.
  static Future<bool> show(BuildContext context, {Rect? sourceRect}) async {
    const dialog = Dialog(child: AscCredentialsDialog());

    final bool? result;
    if (sourceRect != null) {
      result = await showGenieDialog<bool>(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => dialog,
      );
    } else {
      result = await showDialog<bool>(context: context, builder: (_) => dialog);
    }
    return result ?? false;
  }

  @override
  State<AscCredentialsDialog> createState() => _AscCredentialsDialogState();
}

class _AscCredentialsDialogState extends State<AscCredentialsDialog> {
  final _keyIdController = TextEditingController();
  final _issuerIdController = TextEditingController();
  final _privateKeyController = TextEditingController();
  bool _loading = true;
  bool _hasExisting = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = sl<SettingsRepository>();
    final creds = await repo.getAscCredentials();
    if (creds != null && creds.isValid) {
      _keyIdController.text = creds.keyId;
      _issuerIdController.text = creds.issuerId;
      // Don't prefill private key for security — show placeholder.
      _hasExisting = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _keyIdController.dispose();
    _issuerIdController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final keyId = _keyIdController.text.trim();
    final issuerId = _issuerIdController.text.trim();
    final privateKey = _privateKeyController.text.trim();

    // Validate required fields.
    if (keyId.isEmpty || issuerId.isEmpty) return;
    if (!_hasExisting && privateKey.isEmpty) return;

    final repo = sl<SettingsRepository>();

    if (privateKey.isNotEmpty) {
      // Full save — new or updated credentials.
      final creds = AscCredentials(
        keyId: keyId,
        issuerId: issuerId,
        privateKeyContent: privateKey,
      );
      await repo.saveAscCredentials(creds);
    } else {
      // Only update keyId / issuerId, keep existing private key.
      final existing = await repo.getAscCredentials();
      final creds = AscCredentials(
        keyId: keyId,
        issuerId: issuerId,
        privateKeyContent: existing?.privateKeyContent,
      );
      await repo.saveAscCredentials(creds);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _clear() async {
    final confirmed = await AppDialog.show(
      context,
      title: context.l10n.clearCredentialsTitle,
      content: context.l10n.clearCredentialsMessage,
      confirmLabel: context.l10n.clear,
      cancelLabel: context.l10n.cancel,
      isDestructive: true,
      icon: Symbols.delete_rounded,
    );
    if (confirmed != true) return;

    await sl<SettingsRepository>().clearAscCredentials();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isSmall ? screenWidth - 16 : 460,
        maxHeight: isSmall ? MediaQuery.sizeOf(context).height * 0.85 : 560,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Symbols.key,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.appStoreConnectApiKey,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Symbols.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Info banner ──
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.info,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.ascApiKeyGenerateHint,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Fields ──
                  _buildTextField(
                    controller: _keyIdController,
                    label: context.l10n.keyId,
                    hint: context.l10n.keyIdHint,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _issuerIdController,
                    label: context.l10n.issuerId,
                    hint: context.l10n.issuerIdHint,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _privateKeyController,
                    label: context.l10n.privateKeyLabel,
                    hint: _hasExisting
                        ? context.l10n.privateKeyExistingHint
                        : context.l10n.privateKeyNewHint,
                    theme: theme,
                    maxLines: 4,
                    isMonospace: true,
                  ),
                  const SizedBox(height: 20),

                  // ── Actions ──
                  Row(
                    children: [
                      if (_hasExisting)
                        AppButton.destructive(
                          label: context.l10n.clear,
                          icon: Symbols.delete_rounded,
                          onPressed: _clear,
                        ),
                      const Spacer(),
                      AppButton.primary(
                        label: context.l10n.save,
                        icon: Symbols.save,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeData theme,
    int maxLines = 1,
    bool isMonospace = false,
  }) {
    final cs = theme.colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: isMonospace
          ? theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
            )
          : theme.textTheme.bodySmall,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 0.5,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 0.5,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(width: 1, color: cs.primary),
        ),
        filled: true,
        fillColor: cs.surfaceContainerLow,
      ),
    );
  }
}
