
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_card.dart';
import 'package:app_screenshots/core/widgets/app_list_tile.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AscAppConfigResult {
  final AscAppConfig? config;
  final bool didSave;

  const AscAppConfigResult({required this.config, required this.didSave});
}

class AscAppConfigDialog extends StatefulWidget {
  final AscAppConfig? initialConfig;

  const AscAppConfigDialog({super.key, this.initialConfig});

  static Future<AscAppConfigResult?> show(
    BuildContext context, {
    AscAppConfig? initialConfig,
    Rect? sourceRect,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;

    return showDialog<AscAppConfigResult>(
      context: context,
      useSafeArea: !isSmall,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AscAppConfigDialog(initialConfig: initialConfig),
      ),
    );
  }

  @override
  State<AscAppConfigDialog> createState() => _AscAppConfigDialogState();
}

class _AscAppConfigDialogState extends State<AscAppConfigDialog> {
  late final TextEditingController _appNameController;
  late final TextEditingController _appIdController;
  late final TextEditingController _bundleIdController;

  bool _loadingCreds = true;
  bool _hasCredentials = false;
  bool _loadingApps = false;
  List<App>? _apps;
  String _appSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController(text: widget.initialConfig?.appName ?? '');
    _appIdController = TextEditingController(text: widget.initialConfig?.appId ?? '');
    _bundleIdController = TextEditingController(text: widget.initialConfig?.bundleId ?? '');
    _checkCredentials();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appIdController.dispose();
    _bundleIdController.dispose();
    super.dispose();
  }

  Future<void> _checkCredentials() async {
    final creds = await sl<SettingsRepository>().getAscCredentials();
    if (mounted) {
      setState(() {
        _hasCredentials = creds?.isValid ?? false;
        _loadingCreds = false;
      });
    }
  }

  Future<void> _fetchApps() async {
    setState(() {
      _loadingApps = true;
    });

    try {
      final apps = await sl<AscUploadService>().listApps();
      if (mounted) {
        setState(() {
          _apps = apps;
          _loadingApps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingApps = false;
        });
        context.showAppSnackbar(
          context.l10n.ascAppConfigFetchError(e.toString()),
          type: AppSnackbarType.error,
        );
      }
    }
  }

  void _selectApp(App app) {
    setState(() {
      _appNameController.text = app.name;
      _appIdController.text = app.id;
      _bundleIdController.text = app.bundleId;
      _apps = null; // Close the selector view
    });
  }

  void _save() {
    final name = _appNameController.text.trim();
    final id = _appIdController.text.trim();
    final bundle = _bundleIdController.text.trim();

    if (id.isEmpty) {
      context.showAppSnackbar(
        context.l10n.ascAppConfigAppIdEmpty,
        type: AppSnackbarType.error,
      );
      return;
    }

    final newConfig = AscAppConfig(
      appId: id,
      appName: name.isEmpty ? context.l10n.ascAppConfigUnnamedApp : name,
      bundleId: bundle.isEmpty ? context.l10n.ascAppConfigUnknownBundleId : bundle,
      displayType: widget.initialConfig?.displayType ?? 'APP_IPHONE_67',
      platform: widget.initialConfig?.platform ?? 'IOS',
    );

    Navigator.of(context).pop(AscAppConfigResult(config: newConfig, didSave: true));
  }

  void _clear() {
    Navigator.of(context).pop(const AscAppConfigResult(config: null, didSave: true));
  }

  List<App> get _filteredApps {
    if (_apps == null) return [];
    if (_appSearchQuery.isEmpty) return _apps!;
    final q = _appSearchQuery.toLowerCase();
    return _apps!
        .where((app) => app.name.toLowerCase().contains(q) || app.bundleId.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isSmall ? screenWidth - 16 : 460,
        maxHeight: isSmall ? MediaQuery.sizeOf(context).height * 0.85 : 580,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Symbols.settings_suggest_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.ascAppConfigSettings,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Symbols.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // If we are showing the App Store Connect apps list selector
            if (_apps != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.selectApp,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _apps = null),
                          child: Text(context.l10n.cancel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.l10n.searchApps,
                        prefixIcon: const Icon(Symbols.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _appSearchQuery = v),
                      autofocus: true,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _filteredApps.isEmpty
                          ? Center(
                              child: Text(
                                context.l10n.noAppsMatchQuery(_appSearchQuery),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                return AppListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Symbols.apps_rounded, size: 20),
                                  ),
                                  title: Text(app.name),
                                  subtitle: Text(app.bundleId),
                                  onTap: () => _selectApp(app),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Default manual entry / config view
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ASC loading or credentials info
                      if (_loadingCreds)
                        const Center(child: CircularProgressIndicator())
                      else if (_loadingApps)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 8),
                                Text(context.l10n.ascAppConfigLoadingApps),
                              ],
                            ),
                          ),
                        )
                      else if (_hasCredentials)
                        AppButton(
                          label: context.l10n.ascAppConfigLoad,
                          icon: Symbols.cloud_download_rounded,
                          variant: AppButtonVariant.tonal,
                          onPressed: _fetchApps,
                        )
                      else
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
                                  context.l10n.ascAppConfigNoCreds,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Manual Fields
                      TextField(
                        controller: _appNameController,
                        decoration: InputDecoration(
                          labelText: context.l10n.ascAppConfigAppName,
                          hintText: context.l10n.ascAppConfigAppNameHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _appIdController,
                        decoration: InputDecoration(
                          labelText: context.l10n.ascAppConfigAppId,
                          hintText: context.l10n.ascAppConfigAppIdHint,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bundleIdController,
                        decoration: InputDecoration(
                          labelText: context.l10n.ascAppConfigBundleId,
                          hintText: context.l10n.ascAppConfigBundleIdHint,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                children: [
                  if (widget.initialConfig != null)
                    TextButton(
                      onPressed: _clear,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: Text(context.l10n.ascAppConfigClear),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(context.l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: Text(context.l10n.ascAppConfigSave),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
