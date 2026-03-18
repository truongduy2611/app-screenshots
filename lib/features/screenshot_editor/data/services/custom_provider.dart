import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:http/http.dart' as http;

/// Translation provider using an OpenAI-compatible custom endpoint.
///
/// Works with any server that implements the `/v1/chat/completions` API:
/// Ollama, Together AI, LM Studio, vLLM, etc.
class CustomTranslationProvider implements TranslationProvider {
  final String endpoint;
  final String? apiKey;
  final String? model;
  final http.Client _client;

  CustomTranslationProvider({
    required this.endpoint,
    this.apiKey,
    this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get displayName => 'Custom Endpoint';

  @override
  bool get requiresApiKey => false; // API key is optional for custom

  @override
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    // Normalize endpoint: strip trailing slash
    final baseUrl = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;

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
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model ?? 'default',
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
        'Custom API error (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['choices'][0]['message']['content'] as String;

    // Strip markdown code fences if any
    String cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    final translated = jsonDecode(cleaned) as Map<String, dynamic>;
    return translated.map((k, v) => MapEntry(k, v.toString()));
  }
}
