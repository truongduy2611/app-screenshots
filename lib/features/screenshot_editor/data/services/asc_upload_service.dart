import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_api.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:http/http.dart' as http;

/// Per-locale upload status.
enum LocaleUploadStatus { pending, uploading, done, failed }

/// Progress callback for batch uploads.
class AscUploadProgress {
  final String locale;
  final int current;
  final int total;
  final String? error;
  final Map<String, LocaleUploadStatus> localeStatuses;

  const AscUploadProgress({
    required this.locale,
    required this.current,
    required this.total,
    this.error,
    this.localeStatuses = const {},
  });

  double get fraction => total > 0 ? current / total : 0;
}

/// Per-locale result details.
class LocaleResult {
  final String locale;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const LocaleResult({
    required this.locale,
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  bool get isSuccess => failureCount == 0 && successCount > 0;
}

/// Result of a batch upload.
class AscUploadResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final Map<String, LocaleResult> localeResults;

  const AscUploadResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
    this.localeResults = const {},
  });
}

/// Configuration for upload retry behavior.
class _RetryConfig {
  static const maxRetries = 3;
  static const initialDelay = Duration(seconds: 1);
}

/// Orchestrates screenshot uploads to App Store Connect.
///
/// Uses the ASC API subset to:
/// 1. List apps
/// 2. Find editable versions
/// 3. Get/create localizations
/// 4. Upload screenshots (reserve → chunked PUT → commit → wait for delivery)
/// 5. Set screenshot ordering
class AscUploadService {
  final SettingsRepository _settingsRepo;

  AppStoreConnectClient? _client;

  /// Polling interval for delivery state checks.
  static const _pollInterval = Duration(seconds: 2);

  /// Maximum time to wait for a single screenshot delivery.
  static const _deliveryTimeout = Duration(minutes: 2);

  AscUploadService(this._settingsRepo);

  /// Creates a fresh client from stored credentials.
  Future<AppStoreConnectClient> _getClient() async {
    if (_client != null) return _client!;

    final credentials = await _settingsRepo.getAscCredentials();
    if (credentials == null || !credentials.isValid) {
      throw Exception('ASC credentials not configured');
    }

    return _client = AppStoreConnectClient(
      AppStoreConnectCredentials(
        keyId: credentials.keyId,
        issuerId: credentials.issuerId,
        keyContent: credentials.privateKeyContent,
      ),
    );
  }

  /// Invalidates the cached client (e.g., after credential change).
  void invalidateClient() {
    _client?.dispose();
    _client = null;
  }

  /// Lists all apps the user has access to.
  Future<List<App>> listApps() async {
    final client = await _getClient();
    final request = GetRequest(AppStoreConnectUri.v1('apps'))
      ..limit(200)
      ..include('builds', limit: 1);
    final response = await client.get(request);
    return response.asList<App>();
  }

  /// Finds the editable version for an app (PREPARE_FOR_SUBMISSION).
  /// Optionally filters by [platform] (e.g. 'IOS', 'MAC_OS').
  Future<AppStoreVersion?> getEditableVersion(
    String appId, {
    String? platform,
  }) async {
    final client = await _getClient();
    final request =
        GetRequest(AppStoreConnectUri.v1('apps/$appId/appStoreVersions'))
          ..filter('appVersionState', [
            'PREPARE_FOR_SUBMISSION',
            'DEVELOPER_REJECTED',
            'REJECTED',
            'METADATA_REJECTED',
          ]);
    if (platform != null) {
      request.filter('platform', [platform]);
    }
    final response = await client.get(request);
    final versions = response.asList<AppStoreVersion>();
    return versions.isNotEmpty ? versions.first : null;
  }

  /// Gets all existing localizations for a version.
  Future<List<VersionLocalization>> getLocalizations(String versionId) async {
    final client = await _getClient();
    final request = GetRequest(
      AppStoreConnectUri.v1(
        'appStoreVersions/$versionId/appStoreVersionLocalizations',
      ),
    );
    final response = await client.get(request);
    return response.asList<VersionLocalization>();
  }

  /// Gets or creates localizations for the given locales.
  ///
  /// If a locale doesn't exist yet, the method will:
  /// 1. Try to create it directly as a version localization.
  /// 2. If that fails (e.g. locale not configured on the app),
  ///    auto-add it at the app-info level first, then retry.
  Future<Map<String, VersionLocalization>> getOrCreateLocalizations(
    String versionId,
    List<String> locales, {
    String? appId,
  }) async {
    final client = await _getClient();
    final existing = await getLocalizations(versionId);
    final result = <String, VersionLocalization>{};

    // Build a lookup from existing locales for exact + fuzzy matching.
    final existingByLocale = <String, VersionLocalization>{
      for (final loc in existing) loc.locale: loc,
    };

    AppLogger.d(
      'ASC existing locales: ${existingByLocale.keys.toList()}, '
      'requested: $locales',
      tag: 'AscUpload',
    );

    // Map existing — exact match first, then language-prefix match.
    for (final locale in locales) {
      if (existingByLocale.containsKey(locale)) {
        result[locale] = existingByLocale[locale]!;
      } else {
        // Fuzzy: e.g. locale 'en' matches 'en-US', 'vi' matches 'vi-VN'.
        final langPrefix = locale.split('-').first.toLowerCase();
        for (final entry in existingByLocale.entries) {
          if (entry.key.split('-').first.toLowerCase() == langPrefix) {
            AppLogger.d(
              'Fuzzy match: "$locale" → "${entry.key}"',
              tag: 'AscUpload',
            );
            result[locale] = entry.value;
            break;
          }
        }
      }
    }

    // Create missing localizations.
    for (final locale in locales) {
      if (!result.containsKey(locale)) {
        try {
          AppLogger.d(
            'Creating version localization for "$locale"…',
            tag: 'AscUpload',
          );
          result[locale] = await _createVersionLocalization(
            client,
            versionId,
            locale,
          );
        } catch (e) {
          // Try adding the locale at the app-info level first, then retry.
          if (appId != null) {
            AppLogger.d(
              'Version localization failed for "$locale". '
              'Attempting to add locale at app-info level…',
              tag: 'AscUpload',
            );
            try {
              await _addAppInfoLocale(client, appId, locale);
              result[locale] = await _createVersionLocalization(
                client,
                versionId,
                locale,
              );
              AppLogger.i(
                'Successfully added "$locale" after app-info update.',
                tag: 'AscUpload',
              );
            } catch (retryError) {
              AppLogger.error(
                'Failed to add locale "$locale" even after app-info update',
                tag: 'AscUpload',
                error: retryError,
              );
            }
          } else {
            AppLogger.w(
              'Failed to create localization for "$locale": $e\n'
              'Pass appId to auto-add the locale at the app level.',
              tag: 'AscUpload',
            );
          }
        }
      }
    }

    return result;
  }

  /// Creates a single version localization.
  Future<VersionLocalization> _createVersionLocalization(
    AppStoreConnectClient client,
    String versionId,
    String locale,
  ) async {
    return client.postModel<VersionLocalization>(
      AppStoreConnectUri.v1(),
      VersionLocalization.type,
      attributes: VersionLocalizationCreateAttributes(locale: locale),
      relationships: {
        'appStoreVersion': SingleModelRelationship(
          type: AppStoreVersion.type,
          id: versionId,
        ),
      },
    );
  }

  /// Fetches the latest app-info ID for a given app.
  Future<String> _getAppInfoId(
    AppStoreConnectClient client,
    String appId,
  ) async {
    final request = GetRequest(AppStoreConnectUri.v1('apps/$appId/appInfos'));
    final response = await client.get(request);
    final infos = response.asList<AppInfoModel>();
    if (infos.isEmpty) {
      throw Exception('No app info found for app $appId');
    }
    return infos.first.id;
  }

  /// Adds a new locale to the app at the app-info level.
  ///
  /// This is required before creating version localizations for new locales
  /// that haven't been configured on the app yet.
  Future<void> _addAppInfoLocale(
    AppStoreConnectClient client,
    String appId,
    String locale,
  ) async {
    final appInfoId = await _getAppInfoId(client, appId);
    AppLogger.d(
      'Adding locale "$locale" to appInfo "$appInfoId"…',
      tag: 'AscUpload',
    );
    await client.postModel<AppInfoLocalization>(
      AppStoreConnectUri.v1(),
      AppInfoLocalization.type,
      attributes: AppInfoLocalizationCreateAttributes(locale: locale),
      relationships: {
        'appInfo': SingleModelRelationship(
          type: AppInfoModel.type,
          id: appInfoId,
        ),
      },
    );
  }

  /// Gets or creates a screenshot set for a localization + display type.
  Future<AppScreenshotSet> _getOrCreateScreenshotSet(
    String localizationId,
    String displayType,
  ) async {
    final client = await _getClient();

    // Check existing
    final request = GetRequest(
      AppStoreConnectUri.v1(
        'appStoreVersionLocalizations/$localizationId/appScreenshotSets',
      ),
    );
    request.include('appScreenshots');
    final response = await client.get(request);
    final sets = response.asList<AppScreenshotSet>();

    for (final set in sets) {
      if (set.screenshotDisplayType == displayType) {
        return set;
      }
    }

    // Create new
    return client.postModel<AppScreenshotSet>(
      AppStoreConnectUri.v1(),
      AppScreenshotSet.type,
      attributes: AppScreenshotSetAttributes(
        screenshotDisplayType: displayType,
      ),
      relationships: {
        'appStoreVersionLocalization': SingleModelRelationship(
          type: VersionLocalization.type,
          id: localizationId,
        ),
      },
    );
  }

  /// Deletes all existing screenshots in a set.
  Future<void> _deleteExistingScreenshots(
    AppScreenshotSet screenshotSet,
  ) async {
    final client = await _getClient();
    for (final screenshot in screenshotSet.appScreenshots) {
      await client.deleteResource(
        AppStoreConnectUri.v1('${AppScreenshot.type}/${screenshot.id}'),
      );
    }
  }

  /// Fetches a single screenshot by ID (used for delivery polling).
  Future<AppScreenshot> _getScreenshot(String screenshotId) async {
    final client = await _getClient();
    return client.getModel<AppScreenshot>(
      AppStoreConnectUri.v1('${AppScreenshot.type}/$screenshotId'),
    );
  }

  /// Polls until the screenshot delivery state is COMPLETE or FAILED.
  ///
  /// Mirrors the CLI's `waitForAssetDeliveryState` behavior:
  /// polls every 2 seconds with a 2-minute timeout.
  Future<void> _waitForDelivery(String screenshotId) async {
    final deadline = DateTime.now().add(_deliveryTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_pollInterval);

      final screenshot = await _getScreenshot(screenshotId);
      final state = screenshot.assetDeliveryState;

      if (state == null) continue;

      if (state.isComplete) return;

      if (state.isFailed) {
        throw Exception(
          'Screenshot delivery failed for $screenshotId: ${state.errorSummary}',
        );
      }
    }

    throw Exception(
      'Timed out waiting for screenshot $screenshotId delivery '
      '(timeout: ${_deliveryTimeout.inSeconds}s)',
    );
  }

  /// Sets the ordering of screenshots in a set.
  ///
  /// Mirrors the CLI's `SetOrderedAppScreenshots` behavior.
  Future<void> _setScreenshotOrder(
    String setId,
    List<String> orderedIds,
  ) async {
    if (orderedIds.isEmpty) return;
    final client = await _getClient();

    // De-duplicate while preserving order.
    final seen = <String>{};
    final unique = <String>[];
    for (final id in orderedIds) {
      if (id.trim().isEmpty) continue;
      if (seen.add(id)) unique.add(id);
    }

    await client.replaceRelationshipOrder(
      AppStoreConnectUri.v1(
        '${AppScreenshotSet.type}/$setId/relationships/${AppScreenshot.type}',
      ),
      AppScreenshot.type,
      unique,
    );
  }

  /// Executes an HTTP request with basic retry logic.
  ///
  /// Retries on transient failures (5xx, 429) with exponential backoff.
  Future<http.StreamedResponse> _sendWithRetry(http.Request request) async {
    var attempt = 0;
    var delay = _RetryConfig.initialDelay;

    while (true) {
      attempt++;
      final httpClient = http.Client();
      try {
        // We need to clone the request for retries because the body stream
        // is consumed on send.
        final cloned = http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes;

        final response = await httpClient.send(cloned);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        final isRetryable =
            response.statusCode == 429 ||
            response.statusCode == 503 ||
            response.statusCode >= 500;

        if (!isRetryable || attempt >= _RetryConfig.maxRetries) {
          final body = await response.stream.bytesToString();
          throw Exception(
            'Upload failed (attempt $attempt): '
            '${response.statusCode} $body',
          );
        }

        // Parse Retry-After header if present.
        final retryAfter = response.headers['retry-after'];
        if (retryAfter != null) {
          final seconds = int.tryParse(retryAfter);
          if (seconds != null) {
            delay = Duration(seconds: seconds);
          }
        }
      } finally {
        httpClient.close();
      }

      await Future.delayed(delay);
      delay *= 2; // Exponential backoff.
    }
  }

  /// Uploads a single screenshot file.
  ///
  /// Follows the CLI's 4-step pipeline:
  /// 1. Reserve (POST screenshot with file name + size)
  /// 2. Upload binary chunks via upload operations
  /// 3. Commit (PATCH with uploaded=true + MD5 checksum)
  /// 4. Wait for delivery (poll until COMPLETE or FAILED)
  Future<AppScreenshot> uploadScreenshot({
    required String localizationId,
    required String displayType,
    required File file,
  }) async {
    final client = await _getClient();
    final targetSet = await _getOrCreateScreenshotSet(
      localizationId,
      displayType,
    );

    final fileSize = await file.length();
    final fileName = file.path.split('/').last;

    // 1. Reserve
    final screenshot = await client.postModel<AppScreenshot>(
      AppStoreConnectUri.v1(),
      AppScreenshot.type,
      attributes: AppScreenshotCreateAttributes(
        fileSize: fileSize,
        fileName: fileName,
      ),
      relationships: {
        'appScreenshotSet': SingleModelRelationship(
          type: AppScreenshotSet.type,
          id: targetSet.id,
        ),
      },
    );

    // 2. Upload binary chunks
    final bytes = await file.readAsBytes();
    final checksum = md5.convert(bytes).toString();

    final uploadOperations = screenshot.uploadOperations;
    if (uploadOperations == null || uploadOperations.isEmpty) {
      throw Exception('No upload operations returned');
    }

    for (final op in uploadOperations) {
      final method = op['method'] as String;
      final url = op['url'] as String;
      final headers = (op['requestHeaders'] as List<dynamic>)
          .fold<Map<String, String>>({}, (map, header) {
            map[header['name']] = header['value'];
            return map;
          });
      final length = op['length'] as int;
      final offset = op['offset'] as int;

      final chunk = bytes.sublist(offset, offset + length);

      final request = http.Request(method, Uri.parse(url));
      request.headers.addAll(headers);
      request.headers['Content-Length'] = length.toString();
      request.bodyBytes = chunk;

      await _sendWithRetry(request);
    }

    // 3. Commit
    await client.patchModel(
      AppStoreConnectUri.v1(),
      AppScreenshot.type,
      screenshot.id,
      attributes: AppScreenshotAttributes(
        uploaded: true,
        sourceFileChecksum: checksum,
      ),
    );

    // 4. Wait for delivery
    await _waitForDelivery(screenshot.id);

    return screenshot;
  }

  /// Batch uploads screenshots for multiple locales.
  ///
  /// Improvements over previous implementation:
  /// - Accepts [platform] to filter the correct version
  /// - Optionally deletes existing screenshots before uploading
  /// - Sets screenshot ordering after upload
  /// - Uses delivery-wait polling for each screenshot
  Future<AscUploadResult> uploadAll({
    required String appId,
    required Map<String, List<File>> localeScreenshots,
    required String displayType,
    required void Function(AscUploadProgress) onProgress,
    String? platform,
    bool deleteExisting = true,
  }) async {
    // Resolve version (now with platform filter).
    final version = await getEditableVersion(appId, platform: platform);
    if (version == null) {
      throw Exception(
        'No editable version found. Create a new version in ASC first.',
      );
    }

    // Resolve localizations.
    final locales = localeScreenshots.keys.toList();
    final localizations = await getOrCreateLocalizations(
      version.id,
      locales,
      appId: appId,
    );

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];
    final localeResults = <String, LocaleResult>{};

    // Initialize per-locale statuses.
    final localeStatuses = <String, LocaleUploadStatus>{
      for (final locale in localeScreenshots.keys)
        locale: LocaleUploadStatus.pending,
    };

    int totalFiles = 0;
    for (final files in localeScreenshots.values) {
      totalFiles += files.length;
    }
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

    for (final entry in localeScreenshots.entries) {
      final locale = entry.key;
      final files = entry.value;
      final localization = localizations[locale];
      final localeErrors = <String>[];
      int localeSuccess = 0;
      int localeFailure = 0;

      localeStatuses[locale] = LocaleUploadStatus.uploading;
      emitProgress(locale);

      if (localization == null) {
        localeErrors.add('Failed to resolve localization');
        localeFailure += files.length;
        failureCount += files.length;
        current += files.length;
        localeStatuses[locale] = LocaleUploadStatus.failed;
        localeResults[locale] = LocaleResult(
          locale: locale,
          successCount: 0,
          failureCount: localeFailure,
          errors: localeErrors,
        );
        emitProgress(locale);
        continue;
      }

      // Get or create the screenshot set for this locale + display type.
      AppScreenshotSet? screenshotSet;
      try {
        screenshotSet = await _getOrCreateScreenshotSet(
          localization.id,
          displayType,
        );

        // Delete existing screenshots if requested.
        if (deleteExisting && screenshotSet.appScreenshots.isNotEmpty) {
          await _deleteExistingScreenshots(screenshotSet);
        }
      } catch (e) {
        localeErrors.add('Failed to prepare screenshot set: $e');
        localeFailure += files.length;
        failureCount += files.length;
        current += files.length;
        localeStatuses[locale] = LocaleUploadStatus.failed;
        localeResults[locale] = LocaleResult(
          locale: locale,
          successCount: 0,
          failureCount: localeFailure,
          errors: localeErrors,
        );
        emitProgress(locale);
        continue;
      }

      // Track uploaded IDs for ordering.
      final uploadedIds = <String>[];

      // If preserving existing and not deleting, get existing order.
      if (!deleteExisting && screenshotSet.appScreenshots.isNotEmpty) {
        uploadedIds.addAll(screenshotSet.appScreenshots.map((s) => s.id));
      }

      for (final file in files) {
        try {
          emitProgress(locale);
          final uploaded = await uploadScreenshot(
            localizationId: localization.id,
            displayType: displayType,
            file: file,
          );
          uploadedIds.add(uploaded.id);
          localeSuccess++;
          successCount++;
        } catch (e) {
          localeFailure++;
          failureCount++;
          final fileName = file.path.split('/').last;
          localeErrors.add('$fileName: $e');
          errors.add('$locale ($fileName): $e');
        }
        current++;
      }

      // Set screenshot ordering for this set.
      if (uploadedIds.isNotEmpty) {
        try {
          await _setScreenshotOrder(screenshotSet.id, uploadedIds);
        } catch (e) {
          // Ordering failure is non-fatal — screenshots are uploaded.
          localeErrors.add('Failed to set ordering: $e');
          errors.add('$locale: Failed to set ordering: $e');
        }
      }

      localeStatuses[locale] = localeFailure > 0
          ? LocaleUploadStatus.failed
          : LocaleUploadStatus.done;
      localeResults[locale] = LocaleResult(
        locale: locale,
        successCount: localeSuccess,
        failureCount: localeFailure,
        errors: localeErrors,
      );
      emitProgress(locale);
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
}
