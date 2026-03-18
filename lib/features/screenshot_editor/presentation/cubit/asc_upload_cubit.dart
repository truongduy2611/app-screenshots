import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';

import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_version.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart';
import 'package:app_screenshots/features/settings/domain/entities/asc_credentials.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'asc_upload_state.dart';

class AscUploadCubit extends Cubit<AscUploadState> {
  final AscUploadService _uploadService;
  final SettingsRepository _settingsRepo;

  AscUploadCubit(this._uploadService, this._settingsRepo)
    : super(const AscUploadState());

  /// Check if credentials exist and optionally auto-select a saved app.
  ///
  /// [designDisplayType] is the display-type key from the screenshot design
  /// (e.g. `APP_DESKTOP`, `APP_WATCH_ULTRA`). Used to infer the default
  /// platform tab when no saved config exists.
  Future<void> init({
    AscAppConfig? savedAppConfig,
    String? designDisplayType,
  }) async {
    // Resolve initial platform: saved > inferred > fallback.
    final initialPlatform =
        savedAppConfig?.platform ?? _inferPlatform(designDisplayType) ?? 'IOS';
    final initialDisplayType =
        savedAppConfig?.displayType ?? designDisplayType ?? 'APP_IPHONE_67';
    emit(
      state.copyWith(
        platform: initialPlatform,
        displayType: initialDisplayType,
        rememberApp: savedAppConfig != null,
      ),
    );

    final creds = await _settingsRepo.getAscCredentials();
    final hasCreds = creds?.isValid ?? false;
    emit(state.copyWith(hasCredentials: hasCreds));

    if (hasCreds) {
      await loadApps();
      // If we have a saved app config, try auto-selecting it.
      if (savedAppConfig != null &&
          state.status == AscUploadStatus.appsLoaded) {
        final match = state.apps.where((a) => a.id == savedAppConfig.appId);
        if (match.isNotEmpty) {
          await selectApp(match.first);
        }
      }
    }
  }

  /// Save credentials and load apps.
  Future<void> saveCredentials(AscCredentials credentials) async {
    try {
      await _settingsRepo.saveAscCredentials(credentials);
      _uploadService.invalidateClient();
      emit(state.copyWith(hasCredentials: true));
      await loadApps();
    } catch (e, st) {
      AppLogger.error(
        'Failed to save credentials',
        tag: 'AscUpload',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: AscUploadStatus.error,
          errorMessage: 'Failed to save credentials: $e',
        ),
      );
    }
  }

  /// Load available apps from ASC.
  Future<void> loadApps() async {
    emit(state.copyWith(status: AscUploadStatus.loadingApps));
    try {
      final apps = await _uploadService.listApps();
      emit(state.copyWith(status: AscUploadStatus.appsLoaded, apps: apps));
    } catch (e, st) {
      AppLogger.error(
        'Failed to load apps',
        tag: 'AscUpload',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: AscUploadStatus.error,
          errorMessage: 'Failed to load apps: $e',
        ),
      );
    }
  }

  /// Select an app and find its editable version.
  Future<void> selectApp(App app) async {
    emit(
      state.copyWith(selectedApp: app, status: AscUploadStatus.loadingVersion),
    );
    try {
      final version = await _uploadService.getEditableVersion(
        app.id,
        platform: _apiPlatform(state.platform),
      );
      if (version == null) {
        emit(
          state.copyWith(
            status: AscUploadStatus.error,
            errorMessage:
                'No editable version found for ${app.name}. '
                'Create a new version in App Store Connect first.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          version: version,
          status: AscUploadStatus.readyToUpload,
          ascAppConfig: AscAppConfig(
            appId: app.id,
            appName: app.name,
            bundleId: app.bundleId,
            displayType: state.displayType,
            platform: state.platform,
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to load version',
        tag: 'AscUpload',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: AscUploadStatus.error,
          errorMessage: 'Failed to load version: $e',
        ),
      );
    }
  }

  /// Update the target platform (e.g. 'IOS', 'MAC_OS', 'WATCH_OS').
  void setPlatform(String platform) {
    // Reset display type to platform default when switching.
    final String defaultDisplayType;
    switch (platform) {
      case 'MAC_OS':
        defaultDisplayType = 'APP_DESKTOP';
      case 'WATCH_OS':
        defaultDisplayType = 'APP_WATCH_ULTRA';
      default:
        defaultDisplayType = 'APP_IPHONE_67';
    }
    final updatedConfig = state.ascAppConfig?.copyWith(
      platform: platform,
      displayType: defaultDisplayType,
    );
    emit(
      state.copyWith(
        platform: platform,
        displayType: defaultDisplayType,
        ascAppConfig: updatedConfig,
      ),
    );
  }

  /// Update the target display type.
  void setDisplayType(String displayType) {
    final updatedConfig = state.ascAppConfig?.copyWith(
      displayType: displayType,
    );
    emit(state.copyWith(displayType: displayType, ascAppConfig: updatedConfig));
  }

  /// Toggle a locale's selection for upload.
  void toggleLocale(String locale) {
    final updated = Set<String>.from(state.selectedLocales);
    if (updated.contains(locale)) {
      updated.remove(locale);
    } else {
      updated.add(locale);
    }
    emit(state.copyWith(selectedLocales: updated));
  }

  /// Set all selected locales at once.
  void setSelectedLocales(Set<String> locales) {
    emit(state.copyWith(selectedLocales: locales));
  }

  /// Toggle whether existing screenshots should be replaced or appended.
  void setDeleteExisting(bool value) {
    emit(state.copyWith(deleteExisting: value));
  }

  /// Toggle whether the selected app config should be remembered for this
  /// design so subsequent uploads skip app selection.
  void setRememberApp(bool value) {
    emit(state.copyWith(rememberApp: value));
  }

  /// Start uploading screenshots for the selected locales only.
  Future<void> startUpload(Map<String, List<File>> localeScreenshots) async {
    if (state.selectedApp == null) return;

    // Filter to only selected locales.
    final selectedLocales = state.selectedLocales;
    final filtered = <String, List<File>>{};
    for (final entry in localeScreenshots.entries) {
      if (selectedLocales.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }

    if (filtered.isEmpty) return;

    emit(state.copyWith(status: AscUploadStatus.uploading));
    try {
      final result = await _uploadService.uploadAll(
        appId: state.selectedApp!.id,
        localeScreenshots: filtered,
        displayType: state.displayType,
        platform: _apiPlatform(state.platform),
        deleteExisting: state.deleteExisting,
        onProgress: (progress) {
          emit(
            state.copyWith(
              status: AscUploadStatus.uploading,
              progress: progress,
            ),
          );
        },
      );
      emit(state.copyWith(status: AscUploadStatus.done, result: result));
    } catch (e, st) {
      AppLogger.error(
        'Upload failed',
        tag: 'AscUpload',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: AscUploadStatus.error,
          errorMessage: 'Upload failed: $e',
        ),
      );
    }
  }

  /// Reset to initial state for a new upload.
  void reset() {
    emit(const AscUploadState());
    init();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Infer the UI platform tab from a design's display type.
  static String? _inferPlatform(String? displayType) {
    if (displayType == null) return null;
    final lower = displayType.toLowerCase();
    if (lower.contains('desktop')) return 'MAC_OS';
    if (lower.contains('watch')) return 'WATCH_OS';
    if (lower.contains('iphone') || lower.contains('ipad')) return 'IOS';
    return null;
  }

  /// Map the UI platform value to the ASC API platform.
  ///
  /// Watch screenshots are uploaded under the iOS App Store version,
  /// so `WATCH_OS` → `IOS` for the API call.
  static String _apiPlatform(String platform) {
    if (platform == 'WATCH_OS') return 'IOS';
    return platform;
  }
}
