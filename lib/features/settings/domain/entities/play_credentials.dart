import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Google Play service-account credentials, parsed from the API key JSON file
/// downloaded from Google Cloud Console (the same file fastlane's `supply`
/// uses via `json_key`).
class PlayCredentials extends Equatable {
  /// Service-account email, e.g. `xxx@yyy.iam.gserviceaccount.com`.
  final String clientEmail;

  /// PEM-encoded RSA private key (with real newlines).
  final String privateKey;

  /// OAuth2 token endpoint. Defaults to Google's standard endpoint.
  final String tokenUri;

  /// GCP project id (informational; not required for uploads).
  final String? projectId;

  /// The original JSON contents, kept so the file can be re-parsed / re-stored.
  final String rawJson;

  const PlayCredentials({
    required this.clientEmail,
    required this.privateKey,
    required this.rawJson,
    this.tokenUri = 'https://oauth2.googleapis.com/token',
    this.projectId,
  });

  bool get isValid => clientEmail.isNotEmpty && privateKey.isNotEmpty;

  /// Parses a Google service-account JSON key file.
  ///
  /// Throws [FormatException] if the JSON is malformed or missing the required
  /// `client_email` / `private_key` fields.
  factory PlayCredentials.fromServiceAccountJson(String jsonStr) {
    final dynamic decoded = json.decode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Service account file is not a JSON object');
    }

    final type = decoded['type'] as String?;
    final clientEmail = decoded['client_email'] as String?;
    final privateKey = decoded['private_key'] as String?;

    if (clientEmail == null || clientEmail.isEmpty) {
      throw const FormatException('Missing "client_email" in service account');
    }
    if (privateKey == null || privateKey.isEmpty) {
      throw const FormatException('Missing "private_key" in service account');
    }
    if (type != null && type != 'service_account') {
      throw FormatException(
        'Expected a service account key (type "service_account"), got "$type"',
      );
    }

    return PlayCredentials(
      clientEmail: clientEmail,
      privateKey: privateKey,
      rawJson: jsonStr,
      tokenUri:
          (decoded['token_uri'] as String?) ??
          'https://oauth2.googleapis.com/token',
      projectId: decoded['project_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [clientEmail, privateKey, tokenUri, projectId];
}
