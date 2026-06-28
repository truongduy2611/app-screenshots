import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// Obtains and caches an OAuth2 access token for the Google Play
/// Android Publisher API using a service account (JWT bearer flow).
///
/// Mirrors fastlane's authentication: a self-signed RS256 JWT is exchanged
/// at the OAuth2 token endpoint for a short-lived access token.
class GooglePlayToken {
  /// OAuth scope required for the Android Publisher API.
  static const scope = 'https://www.googleapis.com/auth/androidpublisher';

  final String clientEmail;
  final String privateKey;
  final String tokenUri;
  final http.Client _httpClient;

  String? _accessToken;
  DateTime? _expiration;

  GooglePlayToken({
    required this.clientEmail,
    required this.privateKey,
    this.tokenUri = 'https://oauth2.googleapis.com/token',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  bool get _expired {
    final exp = _expiration;
    return exp == null || exp.isBefore(DateTime.now().toUtc());
  }

  /// Returns a valid access token, refreshing it if expired.
  Future<String> getValue() async {
    if (_accessToken != null && !_expired) return _accessToken!;
    return _refresh();
  }

  Future<String> _refresh() async {
    final now = DateTime.now().toUtc();
    final jwt = JWT({
      'iss': clientEmail,
      'scope': scope,
      'aud': tokenUri,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    });

    final assertion = jwt.sign(
      RSAPrivateKey(privateKey),
      algorithm: JWTAlgorithm.RS256,
    );

    final response = await _httpClient.post(
      Uri.parse(tokenUri),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to obtain Google access token '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['access_token'] as String?;
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
    if (token == null) {
      throw Exception('Token response missing access_token: ${response.body}');
    }

    _accessToken = token;
    // Refresh 60s early to avoid edge-of-expiry failures.
    _expiration = now.add(Duration(seconds: expiresIn - 60));
    return token;
  }

  void dispose() {
    _httpClient.close();
  }
}
