import 'dart:io';

import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_card.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/settings/domain/entities/play_credentials.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog for configuring the Google Play service-account key.
///
/// Users can either pick the downloaded JSON key file or paste its contents.
/// Returns `true` when a valid key is saved, `false` otherwise.
class PlayCredentialsDialog extends StatefulWidget {
  const PlayCredentialsDialog({super.key});

  /// Play Console API access documentation.
  static final Uri docsUrl = Uri.parse(
    'https://developers.google.com/android-publisher/getting_started',
  );

  static Future<bool> show(BuildContext context, {Rect? sourceRect}) async {
    const dialog = Dialog(child: PlayCredentialsDialog());

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
  State<PlayCredentialsDialog> createState() => _PlayCredentialsDialogState();
}

class _PlayCredentialsDialogState extends State<PlayCredentialsDialog> {
  final _pasteController = TextEditingController();
  bool _loading = true;
  PlayCredentials? _existing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final creds = await sl<SettingsRepository>().getPlayCredentials();
    if (mounted) {
      setState(() {
        _existing = creds;
        _loading = false;
      });
    }
  }

  /// Parses and persists the service-account JSON contents.
  Future<void> _saveContents(String contents) async {
    try {
      final creds = PlayCredentials.fromServiceAccountJson(contents);
      await sl<SettingsRepository>().savePlayCredentials(creds);
      if (mounted) Navigator.of(context).pop(true);
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _error = context.l10n.invalidServiceAccount(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = context.l10n.invalidServiceAccount('$e'));
      }
    }
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    try {
      String contents;
      if (picked.bytes != null) {
        contents = String.fromCharCodes(picked.bytes!);
      } else if (picked.path != null) {
        contents = await File(picked.path!).readAsString();
      } else {
        throw const FormatException('Could not read the selected file');
      }
      await _saveContents(contents);
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _error = context.l10n.invalidServiceAccount(e.message));
      }
    }
  }

  void _savePasted() {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _error = null);
    _saveContents(text);
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
    await sl<SettingsRepository>().clearPlayCredentials();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;
    final hasExisting = _existing?.isValid ?? false;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isSmall ? screenWidth - 16 : 480,
        maxHeight: isSmall
            ? MediaQuery.sizeOf(context).height * 0.9
            : 660,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInstructions(theme),
                          const SizedBox(height: 16),
                          if (hasExisting) ...[
                            _buildCurrentKey(theme),
                            const SizedBox(height: 12),
                          ],
                          if (_error != null) ...[
                            _buildError(theme),
                            const SizedBox(height: 12),
                          ],
                          AppButton.primary(
                            onPressed: _pickFile,
                            icon: Symbols.upload_file,
                            label: context.l10n.selectJsonKeyFile,
                            isExpanded: true,
                          ),
                          const SizedBox(height: 14),
                          _buildOrDivider(theme),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _pasteController,
                            maxLines: 5,
                            autocorrect: false,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              labelText: context.l10n.pasteJsonLabel,
                              hintText: context.l10n.playPasteJsonHint,
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppButton.secondary(
                            onPressed: _savePasted,
                            icon: Symbols.content_paste_go,
                            label: context.l10n.saveJsonContents,
                            isExpanded: true,
                          ),
                          if (hasExisting) ...[
                            const SizedBox(height: 14),
                            AppButton.destructive(
                              onPressed: _clear,
                              icon: Symbols.delete_rounded,
                              label: context.l10n.clear,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Symbols.key, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.googlePlayServiceAccount,
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
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    final steps = [
      context.l10n.playInstructionsStep1,
      context.l10n.playInstructionsStep2,
      context.l10n.playInstructionsStep3,
      context.l10n.playInstructionsStep4,
    ];
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.info, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                context.l10n.playInstructionsTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => launchUrl(
              PlayCredentialsDialog.docsUrl,
              mode: LaunchMode.externalApplication,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.open_in_new,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.learnMore,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentKey(ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Symbols.check_circle,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _existing!.clientEmail,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _error!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildOrDivider(ThemeData theme) {
    final color = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            context.l10n.orLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}
