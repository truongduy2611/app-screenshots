part of 'command_server.dart';

// =============================================================================
// Translation routes — AI translate, preview, manual edits
// =============================================================================

extension _TranslationRoutes on CommandServer {
  Future<Map<String, dynamic>> handleTranslation(
    String action,
    String method,
    HttpRequest request,
  ) async {
    if (_translationCubit == null || _editorCubit == null) {
      return ServerResponse.notReady('editor/translation');
    }

    final translateAction = TranslateAction.fromActionName(action);
    if (translateAction == null) {
      return ServerResponse.error('Unknown translation action: $action');
    }

    final tCubit = _translationCubit!;
    final eCubit = _editorCubit!;

    switch (translateAction) {
      case TranslateAction.state:
        return ServerResponse.ok({
          'bundle': tCubit.state.bundle?.toJson(),
          'previewLocale': tCubit.state.previewLocale,
          'localeStatuses': tCubit.state.localeStatuses.map(
            (k, v) => MapEntry(k, v.name),
          ),
        });

      case TranslateAction.all:
        final body = await _readBody(request);
        final from = body['from'] as String? ?? 'en';
        final to = (body['to'] as List?)?.cast<String>() ?? [];
        if (to.isEmpty) return ServerResponse.error('Missing "to" (list of target locales)');

        final sourceTexts = <String, String>{};
        for (final overlay in eCubit.state.design.overlays) {
          sourceTexts[overlay.id] = overlay.text;
        }
        if (sourceTexts.isEmpty) {
          return ServerResponse.error('No text overlays to translate');
        }

        await tCubit.translateAll(
          sourceTexts: sourceTexts,
          sourceLocale: from,
          targetLocales: to,
        );
        return ServerResponse.ok({
          'translated': to,
          'bundle': tCubit.state.bundle?.toJson(),
        });

      case TranslateAction.preview:
        final body = await _readBody(request);
        final locale = body['locale'] as String?;
        tCubit.setPreviewLocale(locale);
        return ServerResponse.ok({'previewLocale': locale});

      case TranslateAction.edit:
        final body = await _readBody(request);
        final locale = body['locale'] as String?;
        final overlayId = body['overlayId'] as String?;
        final text = body['text'] as String?;
        if (locale == null || overlayId == null || text == null) {
          return ServerResponse.error('Missing "locale", "overlayId", or "text"');
        }
        tCubit.updateTranslation(locale, overlayId, text);
        return ServerResponse.ok();

      case TranslateAction.removeLocale:
        final body = await _readBody(request);
        final locale = body['locale'] as String?;
        if (locale == null) return ServerResponse.error('Missing "locale"');
        tCubit.removeLocale(locale);
        return ServerResponse.ok({'removed': locale});

      case TranslateAction.setPrompt:
        final body = await _readBody(request);
        final prompt = body['prompt'] as String?;
        tCubit.setCustomPrompt(prompt);
        return ServerResponse.ok({'prompt': prompt});

      case TranslateAction.getTexts:
        final texts = <Map<String, dynamic>>[];
        if (_multiCubit != null) {
          final multi = _multiCubit!;
          for (int i = 0; i < multi.state.designs.length; i++) {
            final design = multi.state.designs[i];
            for (final overlay in design.overlays) {
              texts.add({
                'designIndex': i,
                'overlayId': overlay.id,
                'text': overlay.text,
                'googleFont': overlay.googleFont,
              });
            }
          }
        } else {
          for (final overlay in eCubit.state.design.overlays) {
            texts.add({
              'overlayId': overlay.id,
              'text': overlay.text,
              'googleFont': overlay.googleFont,
            });
          }
        }
        return ServerResponse.ok({
          'totalOverlays': texts.length,
          'texts': texts,
          'currentTranslations': tCubit.state.bundle?.toJson(),
        });

      case TranslateAction.applyManual:
        final body = await _readBody(request);
        final locale = body['locale'] as String?;
        final translations = (body['translations'] as Map?)?.cast<String, String>();
        if (locale == null || translations == null) {
          return ServerResponse.error('Missing "locale" and "translations" ({overlayId: text})');
        }
        tCubit.applyManualTranslation(locale, translations);
        return ServerResponse.ok({'locale': locale, 'count': translations.length});

      case TranslateAction.overrideOverlay:
        final body = await _readBody(request);
        final locale = body['locale'] as String?;
        final overlayId = body['overlayId'] as String?;
        if (locale == null || overlayId == null) {
          return ServerResponse.error('Missing "locale" and/or "overlayId"');
        }
        final override = OverlayOverride(
          fontSize: (body['fontSize'] as num?)?.toDouble(),
          googleFont: body['font'] as String?,
          position: (body['x'] != null || body['y'] != null)
              ? Offset(
                  (body['x'] as num?)?.toDouble() ?? 0,
                  (body['y'] as num?)?.toDouble() ?? 0,
                )
              : null,
          scale: (body['scale'] as num?)?.toDouble(),
          rotation: (body['rotation'] as num?)?.toDouble(),
          width: (body['width'] as num?)?.toDouble(),
          color: body['color'] != null
              ? parseHexColor(body['color'] as String)?.toARGB32()
              : null,
          fontWeightIndex: body['fontWeightIndex'] as int?,
        );
        tCubit.updateOverlayOverride(locale, overlayId, override);
        return ServerResponse.ok({'locale': locale, 'overlayId': overlayId});

      case TranslateAction.setLocaleImage:
        final body = await _readBody(request);
        final locale = body['locale'] as String?;
        final data = body['data'] as String?;
        if (locale == null || data == null) {
          return ServerResponse.error('Missing "locale" and/or "data" (base64)');
        }
        try {
          final bytes = base64Decode(data);
          final tempDir = await getTemporaryDirectory();
          final file = File(
            '${tempDir.path}/locale_image_${locale}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(bytes);
          tCubit.setLocaleImage(locale, file.path);
          return ServerResponse.ok({
            'locale': locale,
            'imagePath': file.path,
          });
        } catch (e) {
          return ServerResponse.error('Failed to save locale image: $e');
        }
    }
  }
}
