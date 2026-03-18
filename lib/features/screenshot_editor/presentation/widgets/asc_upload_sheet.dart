import 'dart:io';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_card.dart';
import 'package:app_screenshots/core/widgets/app_list_tile.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/asc_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_credentials_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:material_symbols_icons/symbols.dart';

part 'asc_upload_sheet/asc_display_types.dart';
part 'asc_upload_sheet/asc_loading_view.dart';
part 'asc_upload_sheet/asc_no_credentials_prompt.dart';
part 'asc_upload_sheet/asc_app_selector.dart';
part 'asc_upload_sheet/asc_ready_to_upload_view.dart';
part 'asc_upload_sheet/asc_upload_progress_view.dart';
part 'asc_upload_sheet/asc_upload_done_view.dart';
part 'asc_upload_sheet/asc_error_view.dart';

/// Sheet for uploading screenshots to App Store Connect.
///
/// Accepts optional [ascAppConfig] for auto-selecting a previously saved app.
/// Emits the selected [AscAppConfig] via [onAppConfigChanged] when the user
/// selects an app, so the design can persist it.
class AscUploadSheet extends StatelessWidget {
  final Map<String, List<File>> localeScreenshots;
  final AscAppConfig? ascAppConfig;
  final ValueChanged<AscAppConfig?>? onAppConfigChanged;

  const AscUploadSheet({
    super.key,
    required this.localeScreenshots,
    this.ascAppConfig,
    this.onAppConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AscUploadCubit, AscUploadState>(
      listenWhen: (prev, curr) =>
          prev.ascAppConfig != curr.ascAppConfig ||
          prev.rememberApp != curr.rememberApp,
      listener: (_, state) {
        if (state.rememberApp && state.ascAppConfig != null) {
          onAppConfigChanged?.call(state.ascAppConfig!);
        } else if (!state.rememberApp) {
          onAppConfigChanged?.call(null);
        }
      },
      builder: (context, state) {
        // Auto-select all locales on first build if none selected.
        if (state.selectedLocales.isEmpty &&
            state.status == AscUploadStatus.readyToUpload) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<AscUploadCubit>().setSelectedLocales(
                localeScreenshots.keys.toSet(),
              );
            }
          });
        }

        final screenWidth = MediaQuery.sizeOf(context).width;
        final isSmall = screenWidth < 600;

        return Container(
          constraints: BoxConstraints(
            maxWidth: isSmall ? screenWidth - 16 : 520,
            maxHeight: isSmall ? MediaQuery.sizeOf(context).height * 0.85 : 640,
            minHeight: isSmall ? 0 : 640,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Symbols.cloud_upload,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.uploadToAppStoreConnect,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Symbols.close, size: 20),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AscUploadState state) {
    if (!state.hasCredentials) {
      return _NoCredentialsPrompt(
        onConfigure: () async {
          final saved = await AscCredentialsDialog.show(context);
          if (saved && context.mounted) {
            context.read<AscUploadCubit>().reset();
          }
        },
      );
    }

    switch (state.status) {
      case AscUploadStatus.initial:
      case AscUploadStatus.loadingApps:
        return _LoadingView(message: context.l10n.loadingApps);

      case AscUploadStatus.appsLoaded:
        return _AppSelector(apps: state.apps);

      case AscUploadStatus.loadingVersion:
        return _LoadingView(
          message: context.l10n.loadingVersionForApp(
            state.selectedApp?.name ?? '',
          ),
        );

      case AscUploadStatus.readyToUpload:
        return SingleChildScrollView(
          child: _ReadyToUploadView(
            app: state.selectedApp,
            versionString: state.version?.versionString ?? '',
            displayType: state.displayType,
            platform: state.platform,
            localeScreenshots: localeScreenshots,
            selectedLocales: state.selectedLocales,
            onUpload: () =>
                context.read<AscUploadCubit>().startUpload(localeScreenshots),
            onDisplayTypeChanged: (type) =>
                context.read<AscUploadCubit>().setDisplayType(type),
            onPlatformChanged: (platform) {
              context.read<AscUploadCubit>().setPlatform(platform);
              if (state.selectedApp != null) {
                context.read<AscUploadCubit>().selectApp(state.selectedApp!);
              }
            },
            onChangeApp: () => context.read<AscUploadCubit>().loadApps(),
            onToggleLocale: (locale) =>
                context.read<AscUploadCubit>().toggleLocale(locale),
            onSelectAll: () => context
                .read<AscUploadCubit>()
                .setSelectedLocales(localeScreenshots.keys.toSet()),
            onDeselectAll: () =>
                context.read<AscUploadCubit>().setSelectedLocales({}),
            deleteExisting: state.deleteExisting,
            onDeleteExistingChanged: (v) =>
                context.read<AscUploadCubit>().setDeleteExisting(v),
            rememberApp: state.rememberApp,
            onRememberAppChanged: (v) =>
                context.read<AscUploadCubit>().setRememberApp(v),
          ),
        );

      case AscUploadStatus.uploading:
        return Center(
          child: SingleChildScrollView(
            child: _UploadProgressView(
              progress: state.progress,
              allLocales: localeScreenshots.keys.toList(),
            ),
          ),
        );

      case AscUploadStatus.done:
        return Center(
          child: SingleChildScrollView(
            child: _UploadDoneView(
              result: state.result!,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );

      case AscUploadStatus.error:
        return Center(
          child: _ErrorView(
            message: state.errorMessage ?? context.l10n.unknownError,
            onRetry: () => context.read<AscUploadCubit>().reset(),
          ),
        );
    }
  }
}
