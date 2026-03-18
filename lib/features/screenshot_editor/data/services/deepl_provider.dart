import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:http/http.dart' as http;

/// Translation provider using the DeepL Translate API.
///
/// Requires a user-provided API key. Supports both Free and Pro API tiers.
/// Unlike LLM-based providers, DeepL is a dedicated translation engine.
class DeepLTranslationProvider implements TranslationProvider {
  final String apiKey;
  final http.Client _client;

  /// If `true`, uses `api.deepl.com` (Pro). Otherwise `api-free.deepl.com`.
  final bool isPro;

  DeepLTranslationProvider({
    required this.apiKey,
    this.isPro = false,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _baseUrl =>
      isPro ? 'https://api.deepl.com' : 'https://api-free.deepl.com';

  @override
  String get displayName => 'DeepL';

  @override
  bool get requiresApiKey => true;

  @override
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    final results = <String, String>{};

    // DeepL supports batching via multiple `text` entries in one request.
    final textList = texts.values.toList();
    final keyList = texts.keys.toList();

    final response = await _client.post(
      Uri.parse('$_baseUrl/v2/translate'),
      headers: {
        'Authorization': 'DeepL-Auth-Key $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': textList,
        'source_lang': _mapSourceLocale(from),
        'target_lang': _mapTargetLocale(to),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'DeepL API error (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final translations = json['translations'] as List;

    for (int i = 0; i < translations.length; i++) {
      results[keyList[i]] = translations[i]['text'] as String;
    }

    return results;
  }

  /// Maps App Store locale codes to DeepL source language codes.
  String _mapSourceLocale(String locale) {
    return _localeMap[locale.toLowerCase()] ??
        locale.split('-').first.toUpperCase();
  }

  /// Maps App Store locale codes to DeepL target language codes.
  ///
  /// DeepL target languages require specific variants (e.g. EN-US vs EN-GB).
  String _mapTargetLocale(String locale) {
    return _targetLocaleMap[locale.toLowerCase()] ??
        _localeMap[locale.toLowerCase()] ??
        locale.split('-').first.toUpperCase();
  }

  /// Source locale mapping.
  static const _localeMap = <String, String>{
    'en': 'EN',
    'de': 'DE',
    'fr': 'FR',
    'es': 'ES',
    'it': 'IT',
    'ja': 'JA',
    'ko': 'KO',
    'nl': 'NL',
    'pl': 'PL',
    'pt': 'PT',
    'ru': 'RU',
    'zh': 'ZH',
    'da': 'DA',
    'fi': 'FI',
    'el': 'EL',
    'hu': 'HU',
    'id': 'ID',
    'nb': 'NB',
    'ro': 'RO',
    'sk': 'SK',
    'sv': 'SV',
    'tr': 'TR',
    'uk': 'UK',
    'ar': 'AR',
    'bg': 'BG',
    'cs': 'CS',
    'et': 'ET',
    'lt': 'LT',
    'lv': 'LV',
    'sl': 'SL',
  };

  /// Target locale mapping — DeepL requires regional variants for some targets.
  static const _targetLocaleMap = <String, String>{
    'en': 'EN-US',
    'en-us': 'EN-US',
    'en-gb': 'EN-GB',
    'pt': 'PT-PT',
    'pt-br': 'PT-BR',
    'zh': 'ZH-HANS',
    'zh-hans': 'ZH-HANS',
    'zh-hant': 'ZH-HANT',
  };
}
