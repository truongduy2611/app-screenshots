import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:http/http.dart' as http;

/// Translation provider using the Google Gemini API.
///
/// Requires a user-provided API key. Uses gemini-2.0-flash by default
/// with `responseMimeType: application/json` for reliable JSON output.
class GeminiTranslationProvider implements TranslationProvider {
  final String apiKey;
  final String model;
  final http.Client _client;

  GeminiTranslationProvider({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get displayName => 'Google Gemini';

  @override
  bool get requiresApiKey => true;

  @override
  Future<Map<String, String>> translate({
    required Map<String, String> texts,
    required String from,
    required String to,
    String? context,
  }) async {
    final promptBuffer = StringBuffer(
      'You are a professional App Store copywriter. '
      'Translate the following marketing texts from $from to $to. '
      'Return ONLY a valid JSON object mapping each key to its '
      'translation. Keep translations concise — they appear as '
      'headline text on App Store screenshots. '
      'Preserve any emoji. Do not add explanations.',
    );
    if (context != null && context.isNotEmpty) {
      promptBuffer.write(' App context: $context');
    }
    promptBuffer.write('\n\n${jsonEncode(texts)}');
    final response = await _client.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta'
        '/models/$model:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': promptBuffer.toString()},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List;
    if (candidates.isEmpty) {
      throw Exception('Gemini returned no candidates');
    }

    final content = candidates[0]['content']['parts'][0]['text'] as String;

    // The model returns structured JSON thanks to responseMimeType.
    final translated = jsonDecode(content) as Map<String, dynamic>;
    return translated.map((k, v) => MapEntry(k, v.toString()));
  }
}
