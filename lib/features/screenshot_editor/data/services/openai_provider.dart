import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:http/http.dart' as http;

/// Translation provider using the OpenAI Chat Completions API.
///
/// Requires a user-provided API key. Uses gpt-4o-mini by default
/// with `response_format: json_object` for reliable JSON output.
class OpenAITranslationProvider implements TranslationProvider {
  final String apiKey;
  final String model;
  final http.Client _client;

  OpenAITranslationProvider({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get displayName => 'OpenAI';

  @override
  bool get requiresApiKey => true;

  @override
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    final systemPrompt = StringBuffer(
      'You are a professional App Store copywriter. '
      'Translate marketing texts. Return ONLY a JSON object '
      'mapping each key to its translation. Keep translations '
      'concise — they appear as headline text on App Store '
      'screenshots. Preserve any emoji. Do not add explanations.',
    );
    if (context != null && context.isNotEmpty) {
      systemPrompt.write(' App context: $context');
    }
    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt.toString()},
          {
            'role': 'user',
            'content': 'Translate from $from to $to:\n${jsonEncode(texts)}',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API error (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['choices'][0]['message']['content'] as String;
    final translated = jsonDecode(content) as Map<String, dynamic>;
    return translated.map((k, v) => MapEntry(k, v.toString()));
  }
}
