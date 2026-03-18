import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:http/http.dart' as http;

/// HTTP client that communicates with the running App Screenshots server.
class AppClient {
  final String host;
  final int port;
  final http.Client _client;

  AppClient({this.host = 'localhost', this.port = AppConstants.defaultPort})
      : _client = http.Client();

  String get _baseUrl => 'http://$host:$port';

  /// Auto-discover the server port from the port file.
  static Future<AppClient> discover() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    final portFile = File('$home/${AppConstants.configDirName}/${AppConstants.portFileName}');
    if (await portFile.exists()) {
      final portStr = (await portFile.readAsString()).trim();
      final port = int.tryParse(portStr);
      if (port != null) return AppClient(port: port);
    }
    return AppClient(); // Default port
  }

  /// GET request — returns parsed JSON response.
  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$path'))
          .timeout(const Duration(seconds: 5));
      return _parseResponse(response);
    } catch (e) {
      return {'ok': false, 'error': _connectionError(e)};
    }
  }

  /// POST request with JSON body — returns parsed JSON response.
  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : '{}',
          )
          .timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } catch (e) {
      return {'ok': false, 'error': _connectionError(e)};
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return {
        'ok': false,
        'error':
            'Server returned empty response (HTTP ${response.statusCode}). '
            'Is App Screenshots running on port $port?',
      };
    }
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      return {
        'ok': false,
        'error':
            'Server returned non-JSON response (HTTP ${response.statusCode}). '
            'Another service may be running on port $port.',
      };
    }
  }

  String _connectionError(Object e) {
    if (e is SocketException || e is http.ClientException) {
      return 'Cannot connect to App Screenshots on port $port. '
          'Is the app running?';
    }
    if (e is TimeoutException) {
      return 'Connection to App Screenshots timed out on port $port.';
    }
    if (e is FormatException) {
      return 'Server returned invalid response. '
          'Another service may be running on port $port.';
    }
    return e.toString();
  }

  void close() => _client.close();
}
