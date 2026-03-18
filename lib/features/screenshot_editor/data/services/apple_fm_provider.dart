import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Translation provider using Apple's on-device Foundation Model.
///
/// Uses a MethodChannel bridge to Swift `FoundationModels` framework.
/// Available on macOS 26+ with Apple Intelligence (M-series chips).
/// No API key required — runs entirely on device.
class AppleFMTranslationProvider implements TranslationProvider {
  static const _channel = MethodChannel('com.appscreenshots/ai');

  /// Check if Apple Foundation Model is available on this device.
  static Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  String get displayName => 'Apple (On-Device)';

  @override
  bool get requiresApiKey => false;

  @override
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    final textsJson = jsonEncode(texts);
    debugPrint(
      '[AppleFM] translate: from=$from to=$to '
      'texts.length=${texts.length} json.length=${textsJson.length}',
    );

    final resultJson = await _channel
        .invokeMethod<String>('translate', {
          'texts': textsJson,
          'from': from,
          'to': to,
        })
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () =>
              throw Exception('Apple FM translate timed out after 90s'),
        );
    debugPrint('[AppleFM] translate: response.length=${resultJson?.length}');

    if (resultJson == null || resultJson.isEmpty) {
      throw Exception('Empty response from Apple Foundation Model');
    }

    // Parse the JSON response and extract translations.
    // The model may return the JSON wrapped in markdown code fences,
    // so we strip those if present.
    String cleaned = resultJson.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }
}
