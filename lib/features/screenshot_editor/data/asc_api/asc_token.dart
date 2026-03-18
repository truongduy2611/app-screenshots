import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AppStoreConnectToken {
  static Future<AppStoreConnectToken> fromFile({
    required String keyId,
    required String issuerId,
    required String path,
  }) async {
    final key = await File(path).readAsString();
    return AppStoreConnectToken(keyId: keyId, issuerId: issuerId, key: key);
  }

  final String keyId;
  final String issuerId;
  final String key;
  final Duration duration;

  DateTime? _expiration;
  String? _value;

  AppStoreConnectToken({
    required this.keyId,
    required this.issuerId,
    required this.key,
    this.duration = const Duration(seconds: 1200),
  }) {
    refresh();
  }

  bool get expired => _expiration!.isBefore(DateTime.now().toUtc());
  String get value {
    if (expired) refresh();
    return _value!;
  }

  void refresh() {
    _expiration = DateTime.now().toUtc().add(duration);
    final token = _JsonWebToken(
      {
        'iss': issuerId,
        'exp': _secondsSinceEpoch(_expiration!),
        'aud': 'appstoreconnect-v1',
      },
      headers: {'kid': keyId},
    );

    _value = token.sign(ECPrivateKey(key), algorithm: JWTAlgorithm.ES256);
  }
}

final _jsonBase64 = json.fuse(utf8.fuse(base64Url));

String _base64Unpadded(String value) {
  if (value.endsWith('==')) return value.substring(0, value.length - 2);
  if (value.endsWith('=')) return value.substring(0, value.length - 1);
  return value;
}

int _secondsSinceEpoch(DateTime time) {
  return time.millisecondsSinceEpoch ~/ 1000;
}

class _JsonWebToken extends JWT {
  Map<String, String>? headers;

  _JsonWebToken(Map<String, dynamic> super.payload, {this.headers});

  @override
  String sign(
    JWTKey key, {
    JWTAlgorithm algorithm = JWTAlgorithm.HS256,
    Duration? expiresIn,
    Duration? notBefore,
    bool noIssueAt = false,
  }) {
    final headers = {'alg': algorithm.name, 'typ': 'JWT'};
    if (this.headers != null) {
      headers.addAll(this.headers!);
    }

    if (payload is Map<String, dynamic>) {
      payload = Map<String, dynamic>.from(payload);
    }

    final encodedHeaders = _base64Unpadded(_jsonBase64.encode(headers));
    final encodedPayload = _base64Unpadded(_jsonBase64.encode(payload));

    final body = '$encodedHeaders.$encodedPayload';
    final signature = _base64Unpadded(
      base64Url.encode(
        algorithm.sign(key, Uint8List.fromList(utf8.encode(body))),
      ),
    );

    return '$body.$signature';
  }
}
