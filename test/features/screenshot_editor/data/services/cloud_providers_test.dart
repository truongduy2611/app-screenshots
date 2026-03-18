import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/services/custom_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/deepl_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/gemini_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/openai_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final sourceTexts = {'o1': 'Hello World', 'o2': 'Try it Free'};
  final translatedTexts = {'o1': 'Hallo Welt', 'o2': 'Jetzt testen'};

  group('OpenAITranslationProvider', () {
    test('returns translated texts on success', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'api.openai.com');
        expect(req.headers['Authorization'], 'Bearer test-key');

        final body = jsonDecode(req.body);
        expect(body['model'], 'gpt-4o-mini');
        expect(body['response_format']['type'], 'json_object');

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': jsonEncode(translatedTexts)},
              },
            ],
          }),
          200,
        );
      });

      final provider = OpenAITranslationProvider(
        apiKey: 'test-key',
        client: client,
      );

      final result = await provider.translate(
        texts: sourceTexts,
        from: 'en',
        to: 'de',
      );

      expect(result, translatedTexts);
      expect(provider.displayName, 'OpenAI');
      expect(provider.requiresApiKey, true);
    });

    test('throws on API error', () async {
      final client = MockClient((_) async {
        return http.Response('{"error": "invalid_api_key"}', 401);
      });

      final provider = OpenAITranslationProvider(
        apiKey: 'bad-key',
        client: client,
      );

      expect(
        () => provider.translate(texts: sourceTexts, from: 'en', to: 'de'),
        throwsException,
      );
    });
  });

  group('GeminiTranslationProvider', () {
    test('returns translated texts on success', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'generativelanguage.googleapis.com');
        expect(req.url.queryParameters['key'], 'test-key');

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(translatedTexts)},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = GeminiTranslationProvider(
        apiKey: 'test-key',
        client: client,
      );

      final result = await provider.translate(
        texts: sourceTexts,
        from: 'en',
        to: 'de',
      );

      expect(result, translatedTexts);
      expect(provider.displayName, 'Google Gemini');
      expect(provider.requiresApiKey, true);
    });

    test('throws on empty candidates', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'candidates': []}), 200);
      });

      final provider = GeminiTranslationProvider(
        apiKey: 'test-key',
        client: client,
      );

      expect(
        () => provider.translate(texts: sourceTexts, from: 'en', to: 'de'),
        throwsException,
      );
    });
  });

  group('DeepLTranslationProvider', () {
    test('returns translated texts on success', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'api-free.deepl.com');
        expect(req.headers['Authorization'], 'DeepL-Auth-Key test-key');

        final body = jsonDecode(req.body);
        expect(body['source_lang'], 'EN');
        expect(body['target_lang'], 'DE');
        expect(body['text'], ['Hello World', 'Try it Free']);

        return http.Response(
          jsonEncode({
            'translations': [
              {'text': 'Hallo Welt'},
              {'text': 'Jetzt testen'},
            ],
          }),
          200,
        );
      });

      final provider = DeepLTranslationProvider(
        apiKey: 'test-key',
        client: client,
      );

      final result = await provider.translate(
        texts: sourceTexts,
        from: 'en',
        to: 'de',
      );

      expect(result, translatedTexts);
      expect(provider.displayName, 'DeepL');
      expect(provider.requiresApiKey, true);
    });

    test('uses Pro URL when isPro is true', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'api.deepl.com');
        return http.Response(
          jsonEncode({
            'translations': [
              {'text': 'A'},
              {'text': 'B'},
            ],
          }),
          200,
        );
      });

      final provider = DeepLTranslationProvider(
        apiKey: 'test-key',
        isPro: true,
        client: client,
      );

      await provider.translate(texts: sourceTexts, from: 'en', to: 'de');
    });

    test('maps target locale correctly for zh → ZH-HANS', () async {
      final client = MockClient((req) async {
        final body = jsonDecode(req.body);
        expect(body['target_lang'], 'ZH-HANS');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'translations': [
                {'text': '你好世界'},
                {'text': '免费试用'},
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final provider = DeepLTranslationProvider(
        apiKey: 'test-key',
        client: client,
      );

      await provider.translate(texts: sourceTexts, from: 'en', to: 'zh');
    });
  });

  group('CustomTranslationProvider', () {
    test('returns translated texts on success', () async {
      final client = MockClient((req) async {
        expect(
          req.url.toString(),
          'http://localhost:11434/v1/chat/completions',
        );
        expect(req.headers['Authorization'], 'Bearer custom-key');

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': jsonEncode(translatedTexts)},
              },
            ],
          }),
          200,
        );
      });

      final provider = CustomTranslationProvider(
        endpoint: 'http://localhost:11434',
        apiKey: 'custom-key',
        model: 'llama3.2',
        client: client,
      );

      final result = await provider.translate(
        texts: sourceTexts,
        from: 'en',
        to: 'de',
      );

      expect(result, translatedTexts);
      expect(provider.displayName, 'Custom Endpoint');
      expect(provider.requiresApiKey, false);
    });

    test('strips markdown code fences from response', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '```json\n${jsonEncode(translatedTexts)}\n```',
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = CustomTranslationProvider(
        endpoint: 'http://localhost:11434',
        client: client,
      );

      final result = await provider.translate(
        texts: sourceTexts,
        from: 'en',
        to: 'de',
      );

      expect(result, translatedTexts);
    });

    test('works without API key', () async {
      final client = MockClient((req) async {
        expect(req.headers.containsKey('Authorization'), false);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': jsonEncode(translatedTexts)},
              },
            ],
          }),
          200,
        );
      });

      final provider = CustomTranslationProvider(
        endpoint: 'http://localhost:11434',
        client: client,
      );

      await provider.translate(texts: sourceTexts, from: 'en', to: 'de');
    });
  });
}
