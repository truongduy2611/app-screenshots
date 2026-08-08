part of 'command_server.dart';

class _LocaleScreenshotBatch {
  final Map<String, List<File>> screenshots;
  final Directory? temporaryDirectory;

  const _LocaleScreenshotBatch(this.screenshots, [this.temporaryDirectory]);

  Future<void> dispose() async {
    final directory = temporaryDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

extension _UploadRoutes on CommandServer {
  Future<Map<String, dynamic>> handleAsc(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final ascAction = AscAction.fromActionName(action);
    if (ascAction == null) {
      return ServerResponse.error('Unknown ASC action: $action');
    }
    final service = _ascUploadService;
    if (service == null) {
      return ServerResponse.error('App Store Connect uploads are unavailable');
    }

    switch (ascAction) {
      case AscAction.apps:
        final apps = await service.listApps();
        return ServerResponse.ok(
          apps
              .map(
                (app) => {
                  'id': app.id,
                  'name': app.name,
                  'bundleId': app.bundleId,
                  'sku': app.sku,
                  'primaryLocale': app.primaryLocale,
                },
              )
              .toList(),
        );
      case AscAction.customProductPages:
        final body = method == 'POST'
            ? await _readBody(request)
            : const <String, dynamic>{};
        final appId =
            body['appId'] as String? ?? request.uri.queryParameters['appId'];
        if (appId == null || appId.isEmpty) {
          return ServerResponse.error('Missing "appId"');
        }
        final pages = await service.listCustomProductPages(appId);
        final result = <Map<String, dynamic>>[];
        for (final page in pages) {
          final version = await service.getEditableCustomProductPageVersion(
            page.id,
          );
          result.add({
            'id': page.id,
            'name': page.name,
            'hasEditableVersion': version != null,
            if (version != null) 'editableVersionId': version.id,
            if (version != null) 'state': version.state,
          });
        }
        return ServerResponse.ok(result);
      case AscAction.upload:
        final body = await _readBody(request);
        final appId = body['appId'] as String?;
        final displayType = body['displayType'] as String?;
        if (appId == null || appId.isEmpty) {
          return ServerResponse.error('Missing "appId"');
        }
        if (displayType == null || displayType.isEmpty) {
          return ServerResponse.error('Missing "displayType"');
        }
        final batch = await _resolveLocaleScreenshots(body);
        if (batch.screenshots.isEmpty) {
          await batch.dispose();
          return ServerResponse.error(
            'No screenshots supplied. Provide "screenshots" data or a "sourceDirectory".',
          );
        }
        final customProductPageId = body['customProductPageId'] as String?;
        final job = _startJob('asc-upload', (job) async {
          try {
            final result = await service.uploadAll(
              appId: appId,
              localeScreenshots: batch.screenshots,
              displayType: displayType,
              platform: body['platform'] as String?,
              deleteExisting: body['deleteExisting'] as bool? ?? true,
              isCustomProductPage: customProductPageId != null,
              customProductPageId: customProductPageId,
              onProgress: (progress) =>
                  job.setProgress(_uploadProgressToJson(progress)),
            );
            return _uploadResultToJson(result);
          } finally {
            await batch.dispose();
          }
        });
        return ServerResponse.ok(job.toJson());
    }
  }

  Future<Map<String, dynamic>> handlePlay(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final playAction = PlayAction.fromActionName(action);
    if (playAction == null) {
      return ServerResponse.error('Unknown Google Play action: $action');
    }
    final service = _playUploadService;
    if (service == null) {
      return ServerResponse.error('Google Play uploads are unavailable');
    }

    switch (playAction) {
      case PlayAction.upload:
        final body = await _readBody(request);
        final packageName = body['packageName'] as String?;
        final imageType = body['imageType'] as String?;
        if (packageName == null || packageName.isEmpty) {
          return ServerResponse.error('Missing "packageName"');
        }
        if (imageType == null || !kPlayImageTypes.containsKey(imageType)) {
          return ServerResponse.error(
            'Invalid "imageType". Use one of: ${kPlayImageTypes.keys.join(', ')}',
          );
        }
        final batch = await _resolveLocaleScreenshots(body);
        if (batch.screenshots.isEmpty) {
          await batch.dispose();
          return ServerResponse.error(
            'No screenshots supplied. Provide "screenshots" data or a "sourceDirectory".',
          );
        }
        final job = _startJob('play-upload', (job) async {
          try {
            final result = await service.uploadAll(
              packageName: packageName,
              localeScreenshots: batch.screenshots,
              imageType: imageType,
              deleteExisting: body['deleteExisting'] as bool? ?? true,
              changesNotSentForReview:
                  body['changesNotSentForReview'] as bool? ?? true,
              onProgress: (progress) =>
                  job.setProgress(_uploadProgressToJson(progress)),
            );
            return _uploadResultToJson(result);
          } finally {
            await batch.dispose();
          }
        });
        return ServerResponse.ok(job.toJson());
    }
  }

  Future<_LocaleScreenshotBatch> _resolveLocaleScreenshots(
    Map<String, dynamic> body,
  ) async {
    final embedded = body['screenshots'];
    if (embedded is Map) {
      final temp = await Directory.systemTemp.createTemp(
        'appshots_cli_upload_',
      );
      final screenshots = <String, List<File>>{};
      try {
        for (final entry in embedded.entries) {
          final locale = entry.key.toString();
          final items = entry.value;
          if (items is! List) continue;
          final files = <File>[];
          for (var index = 0; index < items.length; index++) {
            final item = items[index];
            if (item is! Map || item['data'] is! String) continue;
            final originalName = item['name']?.toString().toLowerCase() ?? '';
            final extension =
                originalName.endsWith('.jpg') || originalName.endsWith('.jpeg')
                ? 'jpg'
                : 'png';
            final safeLocale = locale.replaceAll(
              RegExp(r'[^A-Za-z0-9_-]'),
              '_',
            );
            final file = File(
              '${temp.path}/${safeLocale}_${index.toString().padLeft(2, '0')}.$extension',
            );
            await file.writeAsBytes(base64Decode(item['data'] as String));
            files.add(file);
          }
          if (files.isNotEmpty) screenshots[locale] = files;
        }
        return _LocaleScreenshotBatch(screenshots, temp);
      } catch (_) {
        await temp.delete(recursive: true);
        rethrow;
      }
    }

    final sourceDirectory = body['sourceDirectory'] as String?;
    if (sourceDirectory == null || sourceDirectory.isEmpty) {
      return const _LocaleScreenshotBatch({});
    }
    return _LocaleScreenshotBatch(
      await _readLocaleScreenshots(sourceDirectory, body['locales'] as List?),
    );
  }

  Future<Map<String, List<File>>> _readLocaleScreenshots(
    String sourceDirectory,
    List<dynamic>? selectedLocales,
  ) async {
    final root = Directory(sourceDirectory);
    if (!await root.exists()) {
      throw ArgumentError('Source directory not found: $sourceDirectory');
    }
    final selected = selectedLocales
        ?.whereType<String>()
        .map((locale) => locale.toLowerCase())
        .toSet();
    final result = <String, List<File>>{};
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final locale = entity.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last;
      if (selected != null && !selected.contains(locale.toLowerCase())) {
        continue;
      }
      final files = <File>[];
      await for (final child in entity.list(followLinks: false)) {
        if (child is! File) continue;
        final lower = child.path.toLowerCase();
        if (lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg')) {
          files.add(child);
        }
      }
      files.sort((a, b) => a.path.compareTo(b.path));
      if (files.isNotEmpty) result[locale] = files;
    }
    return result;
  }

  Map<String, dynamic> _uploadProgressToJson(AscUploadProgress progress) => {
    'locale': progress.locale,
    'current': progress.current,
    'total': progress.total,
    'fraction': progress.fraction,
    if (progress.error != null) 'error': progress.error,
    'localeStatuses': progress.localeStatuses.map(
      (locale, status) => MapEntry(locale, status.name),
    ),
  };

  Map<String, dynamic> _uploadResultToJson(AscUploadResult result) => {
    'successCount': result.successCount,
    'failureCount': result.failureCount,
    'errors': result.errors,
    'localeResults': result.localeResults.map(
      (locale, localeResult) => MapEntry(locale, {
        'successCount': localeResult.successCount,
        'failureCount': localeResult.failureCount,
        'errors': localeResult.errors,
        'isSuccess': localeResult.isSuccess,
      }),
    ),
  };
}
