import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/play_api/play_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/play_api/play_token.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart'
    show LocaleUploadStatus, AscUploadProgress, LocaleResult, AscUploadResult;
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';

// Re-export the shared upload progress/result types under Play-friendly names
// so callers don't need to reach into the ASC service.
export 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart'
    show LocaleUploadStatus, AscUploadProgress, LocaleResult, AscUploadResult;

/// Google Play `imageType` values that hold screenshots, keyed for the UI.
const kPlayImageTypes = <String, String>{
  'phoneScreenshots': 'Phone',
  'sevenInchScreenshots': '7" Tablet',
  'tenInchScreenshots': '10" Tablet',
  'tvScreenshots': 'Android TV',
  'wearScreenshots': 'Wear OS',
};

/// Google Play allows at most this many screenshots per image type per locale.
const kPlayMaxScreenshotsPerType = 8;

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
          final playLocale = _toPlayLocale(appLocale);
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
          final freeSlots = (kPlayMaxScreenshotsPerType - existingCount)
              .clamp(0, kPlayMaxScreenshotsPerType);
          final filesToUpload = files.take(freeSlots).toList();
          final skipped = files.length - filesToUpload.length;

          for (final file in filesToUpload) {
            try {
              emitProgress(appLocale);
              final bytes = await file.readAsBytes();
              await client.uploadImage(
                packageName: packageName,
                editId: editId,
                language: playLocale,
                imageType: imageType,
                bytes: bytes,
                contentType: _contentType(file.path),
              );
              localeSuccess++;
              successCount++;
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
            // Send the changes for review so they actually land on the
            // listing without a manual step. If Google refuses to auto-submit
            // (some apps can't), fall back to committing them as a draft.
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
  /// Google Play uses BCP-47 codes that differ from Apple's in a few cases
  /// (notably Chinese script tags). Unknown codes pass through unchanged.
  static String _toPlayLocale(String locale) {
    final lower = locale.toLowerCase().replaceAll('_', '-');
    const map = <String, String>{
      'en': 'en-US',
      'en-us': 'en-US',
      'en-gb': 'en-GB',
      'de': 'de-DE',
      'de-de': 'de-DE',
      'fr': 'fr-FR',
      'fr-fr': 'fr-FR',
      'es': 'es-ES',
      'es-es': 'es-ES',
      'es-419': 'es-419',
      'es-mx': 'es-419',
      'it': 'it-IT',
      'it-it': 'it-IT',
      'ja': 'ja-JP',
      'ja-jp': 'ja-JP',
      'ko': 'ko-KR',
      'ko-kr': 'ko-KR',
      'nl': 'nl-NL',
      'nl-nl': 'nl-NL',
      'pt': 'pt-PT',
      'pt-pt': 'pt-PT',
      'pt-br': 'pt-BR',
      'ru': 'ru-RU',
      'ru-ru': 'ru-RU',
      'tr': 'tr-TR',
      'tr-tr': 'tr-TR',
      'th': 'th',
      'th-th': 'th',
      'vi': 'vi',
      'vi-vn': 'vi',
      'ar': 'ar',
      'ar-sa': 'ar',
      'zh': 'zh-CN',
      'zh-cn': 'zh-CN',
      'zh-hans': 'zh-CN',
      'zh-hans-cn': 'zh-CN',
      'zh-hant': 'zh-TW',
      'zh-tw': 'zh-TW',
      'zh-hant-tw': 'zh-TW',
      'zh-hk': 'zh-HK',
      // Languages Google Play requires with a region suffix.
      'pl': 'pl-PL',
      'pl-pl': 'pl-PL',
      'sv': 'sv-SE',
      'sv-se': 'sv-SE',
      'da': 'da-DK',
      'da-dk': 'da-DK',
      'fi': 'fi-FI',
      'fi-fi': 'fi-FI',
      'cs': 'cs-CZ',
      'cs-cz': 'cs-CZ',
      'hu': 'hu-HU',
      'hu-hu': 'hu-HU',
      'el': 'el-GR',
      'el-gr': 'el-GR',
      'no': 'no-NO',
      'nb': 'no-NO',
      'nb-no': 'no-NO',
      'nn': 'no-NO',
      'he': 'iw-IL',
      'iw': 'iw-IL',
      'hi': 'hi-IN',
      'bn': 'bn-BD',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'ml': 'ml-IN',
      'mr': 'mr-IN',
      'kn': 'kn-IN',
      'az': 'az-AZ',
      'ka': 'ka-GE',
      'hy': 'hy-AM',
      'km': 'km-KH',
      'lo': 'lo-LA',
      'mk': 'mk-MK',
      'mn': 'mn-MN',
      'my': 'my-MM',
      'ne': 'ne-NP',
      'si': 'si-LK',
      'is': 'is-IS',
      'gl': 'gl-ES',
      'eu': 'eu-ES',
      // Languages Google Play accepts as a bare language code.
      'sk': 'sk',
      'ro': 'ro',
      'uk': 'uk',
      'hr': 'hr',
      'bg': 'bg',
      'sr': 'sr',
      'sl': 'sl',
      'lt': 'lt',
      'lv': 'lv',
      'et': 'et',
      'ca': 'ca',
      'fa': 'fa',
      'af': 'af',
      'sw': 'sw',
      'am': 'am',
      'be': 'be',
      'kk': 'kk',
      'ur': 'ur',
      'sq': 'sq',
      'zu': 'zu',
      'ms': 'ms',
      'ms-my': 'ms',
      'id': 'id',
      'fil': 'fil',
      'tl': 'fil',
    };
    return map[lower] ?? locale;
  }

  static String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/png';
  }
}
