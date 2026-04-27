import 'dart:io';

import 'package:app_screenshots/core/app_constants.dart';
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/services/icloud_backup_service.dart';
import 'package:app_screenshots/core/utils/china_locale_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_credentials_dialog.dart';
import 'package:app_screenshots/features/settings/domain/entities/asc_credentials.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/translation_settings_sheet.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/core/widgets/app_list_tile.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/cli_cubit.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubit/app_icon_cubit.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/theme_cubit.dart';

part 'settings_review_card.dart';
part 'settings_app_icon.dart';
part 'settings_asc_credentials.dart';
part 'settings_icloud_backup.dart';
part 'settings_ai_keys.dart';
part 'settings_support_card.dart';
part 'settings_cli_card.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, this.asPage = false});

  /// When true, renders as a full-screen page (with AppBar) instead of a
  /// floating dialog.
  final bool asPage;

  /// Shows Settings as a dialog on wide screens (≥ 600 px) or pushes a
  /// full-page route on small / mobile screens.
  ///
  /// When [sourceRect] is provided, a genie animation is used.
  static Future<void> show(BuildContext context, {Rect? sourceRect}) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    Widget buildProviders({required Widget child}) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<ThemeCubit>()),
        BlocProvider.value(value: context.read<AppIconCubit>()),
        BlocProvider.value(value: context.read<BackupCubit>()),
      ],
      child: child,
    );

    if (isSmallScreen) {
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              buildProviders(child: const SettingsDialog(asPage: true)),
        ),
      );
    }

    if (sourceRect != null) {
      return showGenieDialog(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => buildProviders(child: const SettingsDialog()),
      );
    }

    return showDialog(
      context: context,
      builder: (_) => buildProviders(child: const SettingsDialog()),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _versionTapCount = 0;

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendFeedback() async {
    if (Platform.isMacOS) {
      // On macOS, open the support page instead of mailto:
      await launchUrl(
        Uri.parse(AppConstants.supportUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      final uri = Uri(
        scheme: 'mailto',
        path: AppConstants.feedbackEmail,
        queryParameters: {'subject': AppConstants.feedbackSubject},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _onVersionTap() {
    if (!kDebugMode) return;
    setState(() => _versionTapCount++);
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
    }
  }

  // ── Shared settings content ─────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Builder(
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Pro Section
            const SizedBox(height: 24),

            // ── Appearance ──
            _SectionHeader(title: context.l10n.appearance),
            const SizedBox(height: 8),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(context.l10n.themeSystem),
                      icon: const Icon(Symbols.settings_suggest_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(context.l10n.themeLight),
                      icon: const Icon(Symbols.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(context.l10n.themeDark),
                      icon: const Icon(Symbols.dark_mode_rounded),
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (val) {
                    context.read<ThemeCubit>().setThemeMode(val.first);
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // ── App Icon ──
            _SectionHeader(title: context.l10n.appIcon),
            const SizedBox(height: 8),
            BlocBuilder<AppIconCubit, AppIconState>(
              builder: (context, iconState) {
                return Row(
                  children: [
                    _AppIconCard(
                      label: context.l10n.defaultLabel,
                      isSelected: iconState.isDefault,
                      iconWidget: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'main-icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      theme: theme,
                      onTap: () =>
                          context.read<AppIconCubit>().setIcon('default'),
                    ),
                    const SizedBox(width: 12),
                    _AppIconCard(
                      label: context.l10n.purpleLabel,
                      isSelected: iconState.isAlternative,
                      iconWidget: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'app-icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      theme: theme,
                      onTap: () =>
                          context.read<AppIconCubit>().setIcon('alternative'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── iCloud Backup ──
            _SectionHeader(title: context.l10n.icloudBackup),
            const SizedBox(height: 8),
            _ICloudBackupSection(isDark: isDark, theme: theme),
            const SizedBox(height: 24),

            // ── AI Keys ──
            _SectionHeader(title: context.l10n.aiProviderSettings),
            const SizedBox(height: 8),
            _AiKeysSection(isDark: isDark, theme: theme),
            const SizedBox(height: 24),

            // ── App Store Connect ──
            _SectionHeader(title: context.l10n.appStoreConnect),
            const SizedBox(height: 8),
            _AscCredentialsSection(isDark: isDark, theme: theme),

            const SizedBox(height: 24),
            _SectionHeader(title: context.l10n.support),
            const SizedBox(height: 8),
            if (Platform.isMacOS) ...[
              _SettingsCliCard(isDark: isDark, theme: theme),
              const SizedBox(height: 12),
            ],
            _SupportMeCard(isDark: isDark, theme: theme),
            const SizedBox(height: 16),
            _SettingsTileGroup(
              isDark: isDark,
              theme: theme,
              children: [
                _SettingsTile(
                  icon: Symbols.star_rounded,
                  title: context.l10n.rateOnAppStore,
                  theme: theme,
                  onTap: () => _openUrl(AppConstants.appStoreReviewUrl),
                ),
                _SettingsTile(
                  icon: Symbols.mail_rounded,
                  title: context.l10n.sendFeedback,
                  theme: theme,
                  onTap: _sendFeedback,
                ),
                _SettingsTile(
                  icon: Symbols.code_rounded,
                  title: 'GitHub',
                  subtitle: 'Open source repository',
                  theme: theme,
                  onTap: () => _openUrl(AppConstants.githubRepoUrl),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Legal ──
            _SectionHeader(title: context.l10n.legal),
            const SizedBox(height: 8),
            _SettingsTileGroup(
              isDark: isDark,
              theme: theme,
              children: [
                _SettingsTile(
                  icon: Symbols.description_rounded,
                  title: context.l10n.termsOfService,
                  theme: theme,
                  onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
                ),
                _SettingsTile(
                  icon: Symbols.shield_rounded,
                  title: context.l10n.privacyPolicy,
                  theme: theme,
                  onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── About ──
            _SectionHeader(title: context.l10n.about),
            const SizedBox(height: 8),
            _SettingsTileGroup(
              isDark: isDark,
              theme: theme,
              children: [
                _SettingsTile(
                  icon: Symbols.info_rounded,
                  title: context.l10n.appTitle,
                  subtitle: context.l10n.version('1.0.0'),
                  theme: theme,
                  onTap: _onVersionTap,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Review prompt ──
            _ReviewPromptCard(
              isDark: isDark,
              theme: theme,
              onTap: _requestReview,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Full-page mode (mobile / small screens) ──
    if (widget.asPage) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.settings), centerTitle: true),
        body: _buildContent(context),
      );
    }

    // ── Dialog mode (desktop / wide screens) ──
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.settings_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.settings,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Symbols.close_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? theme.colorScheme.surfaceContainerLow
                          : theme.colorScheme.surfaceContainerHighest,
                      fixedSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Flexible(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// A visually grouped container for settings tiles with proper dark mode
/// styling.
class _SettingsTileGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final ThemeData theme;

  const _SettingsTileGroup({
    required this.children,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.15 : 0.2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.12 : 0.18,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.theme,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      mouseCursor: onTap != null ? SystemMouseCursors.click : null,
      leading: Icon(icon, size: 20),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Symbols.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            )
          : null,
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
