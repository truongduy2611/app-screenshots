import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/play_upload_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/play_api/play_client.dart';
import 'package:app_screenshots/features/settings/domain/entities/play_credentials.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'play_upload_state.dart';

/// Drives the Google Play screenshot upload sheet.
///
/// Unlike App Store Connect, the Android Publisher API has no "list apps"
/// endpoint, so the target app is identified by its package name (entered or
/// remembered as the last-used default).
class PlayUploadCubit extends Cubit<PlayUploadState> {
  final PlayUploadService _uploadService;
  final SettingsRepository _settingsRepo;

  PlayUploadCubit(this._uploadService, this._settingsRepo)
    : super(const PlayUploadState());

  /// Loads credentials and any saved package name.
  Future<void> init() async {
    final creds = await _settingsRepo.getPlayCredentials();
    final hasCreds = creds?.isValid ?? false;
    final savedPackage = await _settingsRepo.getPlayPackageName();
    emit(
      state.copyWith(
        hasCredentials: hasCreds,
        packageName: savedPackage ?? '',
        status: PlayUploadStatus.ready,
      ),
    );
  }

  /// Saves service-account credentials and marks the sheet ready.
  Future<void> saveCredentials(PlayCredentials credentials) async {
    try {
      await _settingsRepo.savePlayCredentials(credentials);
      _uploadService.invalidateClient();
      emit(
        state.copyWith(hasCredentials: true, status: PlayUploadStatus.ready),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to save Play credentials',
        tag: 'PlayUpload',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: PlayUploadStatus.error,
          errorMessage: 'Failed to save credentials: $e',
        ),
      );
    }
  }

  void setPackageName(String packageName) {
    emit(state.copyWith(packageName: packageName.trim()));
  }

  void setImageType(String imageType) {
    emit(state.copyWith(imageType: imageType));
  }

  void setDeleteExisting(bool value) {
    emit(state.copyWith(deleteExisting: value));
  }

  void setCommitAsDraft(bool value) {
    emit(state.copyWith(commitAsDraft: value));
  }

  void setDestination(PlayDestination destination) {
    emit(state.copyWith(destination: destination));
  }

  void setListingName(String name) {
    emit(state.copyWith(listingName: name));
  }

  void setTargetingNote(String note) {
    emit(state.copyWith(targetingNote: note));
  }

  void toggleLocale(String locale) {
    final updated = Set<String>.from(state.selectedLocales);
    if (updated.contains(locale)) {
      updated.remove(locale);
    } else {
      updated.add(locale);
    }
    emit(state.copyWith(selectedLocales: updated));
  }

  void setSelectedLocales(Set<String> locales) {
    emit(state.copyWith(selectedLocales: locales));
  }

  /// Uploads the selected locales' screenshots to Google Play.
  Future<void> startUpload(Map<String, List<File>> localeScreenshots) async {
    final packageName = state.packageName.trim();
    if (packageName.isEmpty) {
      emit(
        state.copyWith(
          status: PlayUploadStatus.error,
          errorMessage: 'Enter a package name first.',
        ),
      );
      return;
    }

    final filtered = <String, List<File>>{};
    for (final entry in localeScreenshots.entries) {
      if (state.selectedLocales.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    if (filtered.isEmpty) return;

    // Remember the package name as the default for next time.
    await _settingsRepo.setPlayPackageName(packageName);

    emit(state.copyWith(status: PlayUploadStatus.uploading));
    try {
      final result = await _uploadService.uploadAll(
        packageName: packageName,
        localeScreenshots: filtered,
        imageType: state.imageType,
        deleteExisting: state.deleteExisting,
        changesNotSentForReview: state.commitAsDraft,
        onProgress: (progress) {
          emit(
            state.copyWith(
              status: PlayUploadStatus.uploading,
              progress: progress,
            ),
          );
        },
      );
      emit(state.copyWith(status: PlayUploadStatus.done, result: result));
    } catch (e, st) {
      AppLogger.error(
        'Play upload failed',
        tag: 'PlayUpload',
        error: e,
        stackTrace: st,
      );
      PlayUploadFailure? failure;
      if (e is PlayApiException) {
        if (e.isAutoSubmitRequired) {
          failure = PlayUploadFailure.autoSubmitRequired;
        } else if (e.isHealthDeclarationRequired) {
          failure = PlayUploadFailure.declarationRequired;
        }
      }
      emit(
        state.copyWith(
          status: PlayUploadStatus.error,
          failure: failure,
          errorMessage:
              'Upload failed: ${e is PlayApiException ? e.message : e}',
        ),
      );
    }
  }

  /// Exports the selected locales as a custom store listing upload kit.
  ///
  /// Google Play has no custom store listing API, so this writes a folder
  /// tree plus an `UPLOAD.md` walkthrough instead of calling Google.
  Future<void> startExport(
    Map<String, List<File>> localeScreenshots,
    String outputDirectory,
  ) async {
    final listingName = state.listingName.trim();
    if (listingName.isEmpty) {
      emit(
        state.copyWith(
          status: PlayUploadStatus.error,
          errorMessage: 'Name the custom store listing first.',
        ),
      );
      return;
    }

    final filtered = <String, List<File>>{};
    for (final entry in localeScreenshots.entries) {
      if (state.selectedLocales.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    if (filtered.isEmpty) return;

    final packageName = state.packageName.trim();
    if (packageName.isNotEmpty) {
      await _settingsRepo.setPlayPackageName(packageName);
    }

    emit(state.copyWith(status: PlayUploadStatus.uploading));
    try {
      final targetingNote = state.targetingNote.trim();
      final result = await PlayCslExporter().export(
        outputDirectory: outputDirectory,
        packageName: packageName.isEmpty ? null : packageName,
        listings: [
          PlayCslListing.singleType(
            name: listingName,
            imageType: state.imageType,
            localeScreenshots: filtered,
            targetingNote: targetingNote.isEmpty ? null : targetingNote,
          ),
        ],
      );
      emit(
        state.copyWith(
          status: PlayUploadStatus.exported,
          exportResult: result,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Play custom store listing export failed',
        tag: 'PlayUpload',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: PlayUploadStatus.error,
          errorMessage: 'Export failed: $e',
        ),
      );
    }
  }

  /// Resets to a fresh ready state (keeps stored credentials/package name).
  ///
  /// The chosen destination and listing details survive a reset so retrying
  /// after an error doesn't silently drop the user back to the main listing.
  void reset() {
    emit(
      PlayUploadState(
        destination: state.destination,
        listingName: state.listingName,
        targetingNote: state.targetingNote,
        imageType: state.imageType,
      ),
    );
    init();
  }
}
