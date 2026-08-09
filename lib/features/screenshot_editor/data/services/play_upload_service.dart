import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/play_api/play_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/play_api/play_token.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart'
    show LocaleUploadStatus, AscUploadProgress, LocaleResult, AscUploadResult;
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots_shared/app_screenshots_shared.dart';

// Re-export the shared upload progress/result types under Play-friendly names
// so callers don't need to reach into the ASC service.
export 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart'
    show LocaleUploadStatus, AscUploadProgress, LocaleResult, AscUploadResult;

// The Play listing vocabulary lives in the shared package so the CLI applies
// the same locale mapping and per-type limits as the app.
export 'package:app_screenshots_shared/app_screenshots_shared.dart'
    show kPlayImageTypes, kPlayMaxScreenshotsPerType, playLocaleFor;

/// Orchestrates screenshot uploads to the Google Play Console using a
/// service-account key (the same credential fastlane's `supply` consumes).
///
/// All image changes happen inside a single edit transaction which is
/// committed once at the end, so the listing is never left half-updated.
class PlayUploadService {
  final SettingsRepository _settingsRepo;

  GooglePlayClient? _client;

  PlayUploadService(this._settingsRepo);

  Future<GooglePlayClient> _getClient() async {
    if (_client != null) return _client!;

    final creds = await _settingsRepo.getPlayCredentials();
    if (creds == null || !creds.isValid) {
      throw Exception('Google Play credentials not configured');
    }

    return _client = GooglePlayClient(
      GooglePlayToken(
        clientEmail: creds.clientEmail,
        privateKey: creds.privateKey,
        tokenUri: creds.tokenUri,
      ),
    );
  }

  /// Invalidates the cached client (e.g. after credentials change).
  void invalidateClient() {
    _client?.dispose();
    _client = null;
  }

  /// Uploads screenshots for multiple locales under a single image type.
  ///
  /// [localeScreenshots] maps an app/translation locale → ordered files.
  /// Locale codes are normalized to Google Play's BCP-47 listing codes.
  Future<AscUploadResult> uploadAll({
    required String packageName,
    required Map<String, List<File>> localeScreenshots,
    required String imageType,
    required void Function(AscUploadProgress) onProgress,
    bool deleteExisting = true,
    bool changesNotSentForReview = true,
  }) async {
    final client = await _getClient();

    int totalFiles = 0;
    for (final files in localeScreenshots.values) {
      totalFiles += files.length;
    }

    // Google occasionally rejects the commit with "A change was made to the
    // application outside of this Edit, please create a new edit." — an
    // optimistic-concurrency conflict between the upload endpoint and commit.
    // The fix it instructs is exactly that: open a fresh edit and retry the
    // whole sequence.
    const maxAttempts = 3;
    PlayApiException? lastConflict;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      // Per-attempt accumulators (a retry re-does everything from scratch).
      int successCount = 0;
      int failureCount = 0;
      final errors = <String>[];
      final localeResults = <String, LocaleResult>{};
      final localeStatuses = <String, LocaleUploadStatus>{
        for (final locale in localeScreenshots.keys)
          locale: LocaleUploadStatus.pending,
      };
      int current = 0;

      void emitProgress(String locale) {
        onProgress(
          AscUploadProgress(
            locale: locale,
            current: current,
            total: totalFiles,
            localeStatuses: Map.unmodifiable(localeStatuses),
          ),
        );
      }

      // Open one edit for the whole batch.
      final editId = await client.insertEdit(packageName);
      AppLogger.d(
        'Opened Play edit $editId for $packageName (attempt $attempt)',
        tag: 'PlayUpload',
      );

      var committed = false;
      var needRetry = false;
      try {
        for (final entry in localeScreenshots.entries) {
          final appLocale = entry.key;
          final files = entry.value;
          final playLocale = toPlayLocale(appLocale);
          final localeErrors = <String>[];
          int localeSuccess = 0;
          int localeFailure = 0;

          localeStatuses[appLocale] = LocaleUploadStatus.uploading;
          emitProgress(appLocale);

          // Replace existing screenshots, or count them to respect the limit
          // when appending. Google Play caps each image type at
          // kPlayMaxScreenshotsPerType per locale.
          int existingCount = 0;
          try {
            if (deleteExisting) {
              await client.deleteAllImages(
                packageName,
                editId,
                playLocale,
                imageType,
              );
            } else {
              existingCount = (await client.listImages(
                packageName,
                editId,
                playLocale,
                imageType,
              )).length;
            }
          } on PlayApiException catch (e) {
            // A missing listing or an unsupported language means the locale
            // can't receive uploads — fail this locale, keep going.
            if (e.isListingMissing || e.isLanguageUnsupported) {
              localeErrors.add(
                e.isLanguageUnsupported
                    ? '"$playLocale" is not a supported Google Play '
                          'listing language.'
                    : 'No store listing for "$playLocale". '
                          'Create it in Play Console first.',
              );
              localeFailure += files.length;
              failureCount += files.length;
              current += files.length;
              localeStatuses[appLocale] = LocaleUploadStatus.failed;
              localeResults[appLocale] = LocaleResult(
                locale: appLocale,
                successCount: 0,
                failureCount: localeFailure,
                errors: localeErrors,
              );
              errors.add('$appLocale: ${localeErrors.last}');
              emitProgress(appLocale);
              continue;
            }
            rethrow;
          }

          // Cap to the free slots so we never exceed Google Play's limit.
          final freeSlots = (kPlayMaxScreenshotsPerType - existingCount).clamp(
            0,
            kPlayMaxScreenshotsPerType,
          );
          final filesToUpload = files.take(freeSlots).toList();
          final skipped = files.length - filesToUpload.length;

          int index = 1;
          for (final file in filesToUpload) {
            try {
              emitProgress(appLocale);
              final bytes = await file.readAsBytes();
              final ext = file.path.split('.').last.toLowerCase();
              final filename =
                  '${playLocale.replaceAll('-', '_')}_${index.toString().padLeft(2, '0')}.$ext';
              await client.uploadImage(
                packageName: packageName,
                editId: editId,
                language: playLocale,
                imageType: imageType,
                bytes: bytes,
                contentType: _contentType(file.path),
                filename: filename,
              );
              localeSuccess++;
              successCount++;
              index++;
            } catch (e) {
              localeFailure++;
              failureCount++;
              final fileName = file.path.split(Platform.pathSeparator).last;
              localeErrors.add('$fileName: $e');
              errors.add('$appLocale ($fileName): $e');
            }
            current++;
          }

          // Note any screenshots dropped to stay within the limit.
          if (skipped > 0) {
            current += skipped; // keep the progress total consistent
            final typeLabel = kPlayImageTypes[imageType] ?? imageType;
            final note =
                'Skipped $skipped — Google Play allows at most '
                '$kPlayMaxScreenshotsPerType $typeLabel screenshots per locale.';
            localeErrors.add(note);
            errors.add('$appLocale: $note');
          }

          localeStatuses[appLocale] = localeFailure > 0
              ? LocaleUploadStatus.failed
              : LocaleUploadStatus.done;
          localeResults[appLocale] = LocaleResult(
            locale: appLocale,
            successCount: localeSuccess,
            failureCount: localeFailure,
            errors: localeErrors,
          );
          emitProgress(appLocale);
        }

        // Commit only if at least one screenshot was staged successfully.
        if (successCount > 0) {
          try {
            if (changesNotSentForReview) {
              await client.commitEdit(
                packageName,
                editId,
                changesNotSentForReview: true,
              );
            } else {
              try {
                await client.commitEdit(
                  packageName,
                  editId,
                  changesNotSentForReview: false,
                );
              } on PlayApiException catch (e) {
                if (e.isReviewRequired) {
                  AppLogger.w(
                    'Auto-submit for review not allowed; committing as a draft '
                    '(changes not sent for review)',
                    tag: 'PlayUpload',
                  );
                  await client.commitEdit(
                    packageName,
                    editId,
                    changesNotSentForReview: true,
                  );
                } else {
                  rethrow;
                }
              }
            }
            committed = true;
            AppLogger.i('Committed Play edit $editId', tag: 'PlayUpload');
          } on PlayApiException catch (e) {
            if (e.isEditConflict && attempt < maxAttempts) {
              lastConflict = e;
              needRetry = true;
              AppLogger.w(
                'Edit $editId went stale on commit; retrying with a fresh '
                'edit (attempt ${attempt + 1}/$maxAttempts)',
                tag: 'PlayUpload',
              );
            } else {
              rethrow;
            }
          }
        }
      } catch (e, st) {
        AppLogger.error(
          'Play upload failed',
          tag: 'PlayUpload',
          error: e,
          stackTrace: st,
        );
        await client.deleteEdit(packageName, editId);
        rethrow;
      } finally {
        // Discard the edit if it wasn't committed (nothing uploaded, or a
        // conflict means we'll open a brand-new one on retry).
        if (!committed) {
          await client.deleteEdit(packageName, editId);
        }
      }

      if (needRetry) {
        await Future.delayed(Duration(seconds: attempt));
        continue;
      }

      onProgress(
        AscUploadProgress(
          locale: 'done',
          current: totalFiles,
          total: totalFiles,
          localeStatuses: Map.unmodifiable(localeStatuses),
        ),
      );

      return AscUploadResult(
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
        localeResults: localeResults,
      );
    }

    // All attempts hit an edit conflict.
    throw lastConflict ??
        Exception('Google Play commit failed after $maxAttempts attempts');
  }

  /// Maps an app/translation locale to the Google Play listing locale code.
  ///
  /// Delegates to the shared [playLocaleFor] so the CLI's custom store
  /// listing export folders match what this service uploads.
  static String toPlayLocale(String locale) => playLocaleFor(locale);

  static String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/png';
  }
}
