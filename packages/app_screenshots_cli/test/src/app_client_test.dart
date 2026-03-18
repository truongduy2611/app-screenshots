import 'dart:convert';
import 'dart:io';

import 'package:app_screenshots_cli/src/app_client.dart';
import 'package:test/test.dart';

void main() {
  group('AppClient', () {
    late HttpServer server;
    late AppClient client;

    setUp(() async {
      // Bind to an ephemeral port
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = AppClient(port: server.port);
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test('get returns parsed JSON response on success', () async {
      server.listen((HttpRequest request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true, 'data': 'test_data'}))
          ..close();
      });

      final response = await client.get('/test');
      expect(response['ok'], isTrue);
      expect(response['data'], 'test_data');
    });

    test('get handles empty response', () async {
      server.listen((HttpRequest request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('')
          ..close();
      });

      final response = await client.get('/test');
      expect(response['ok'], isFalse);
      expect(response['error'], contains('Server returned empty response'));
    });

    test('get handles invalid JSON response', () async {
      server.listen((HttpRequest request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('not json')
          ..close();
      });

      final response = await client.get('/test');
      expect(response['ok'], isFalse);
      expect(response['error'], contains('Server returned non-JSON response'));
    });

    test('post sends body and returns parsed JSON', () async {
      server.listen((HttpRequest request) async {
        final bodyString = await utf8.decoder.bind(request).join();
        final body = jsonDecode(bodyString);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true, 'received': body}))
          ..close();
      });

      final response = await client.post('/test', {'foo': 'bar'});
      expect(response['ok'], isTrue);
      expect(response['received'], equals({'foo': 'bar'}));
    });

    test('returns connection error when server is not running', () async {
      final badClient = AppClient(port: 9999); // Unlikely to be used
      final response = await badClient.get('/test');
      expect(response['ok'], isFalse);
      expect(response['error'], contains('Cannot connect to App Screenshots'));
      badClient.close();
    });
  });
}
