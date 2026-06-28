import 'dart:convert';
import 'dart:typed_data';

import 'package:app_screenshots/features/screenshot_editor/data/play_api/play_token.dart';
import 'package:http/http.dart' as http;

/// Thrown when an Android Publisher API request fails.
class PlayApiException implements Exception {
  final int statusCode;
  final String message;

  PlayApiException(this.statusCode, this.message);

  /// `true` when the failure is a missing store listing for a language.
  bool get isListingMissing =>
      statusCode == 404 ||
      message.toLowerCase().contains('listing') &&
          message.toLowerCase().contains('not');

  /// `true` when Google rejected the request because the locale isn't a
  /// supported Play listing language (e.g. "The requested language is not
  /// currently supported: pl."). Treated as a per-locale failure, not fatal.
  bool get isLanguageUnsupported =>
      statusCode == 400 &&
      message.toLowerCase().contains('language is not currently supported');

  /// `true` when Google refuses to auto-submit the changes for review
  /// ("Changes cannot be sent for review automatically. Please set the query
  /// parameter changesNotSentForReview to true."). The fix is to retry the
  /// commit with changesNotSentForReview=true.
  bool get isReviewRequired {
    final lower = message.toLowerCase();
    return statusCode == 400 &&
        (lower.contains('changesnotsentforreview') ||
            lower.contains('cannot be sent for review'));
  }

  /// `true` when Google rejected a commit because the edit's baseline went
  /// stale ("A change was made to the application outside of this Edit, please
  /// create a new edit."). The fix is to retry the whole edit from scratch.
  bool get isEditConflict {
    final lower = message.toLowerCase();
    return statusCode == 400 &&
        (lower.contains('create a new edit') ||
            lower.contains('outside of this edit'));
  }

  @override
  String toString() => 'PlayApiException($statusCode): $message';
}

/// Minimal client for the Google Play Android Publisher API v3, scoped to the
/// screenshot/image endpoints used for upload.
///
/// The API is transactional: open an *edit*, mutate images, then *commit*.
/// Nothing is applied to the live listing until the edit is committed.
class GooglePlayClient {
  static const _base =
      'https://androidpublisher.googleapis.com/androidpublisher/v3';
  static const _uploadBase =
      'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';

  final GooglePlayToken _token;
  final http.Client _httpClient;

  GooglePlayClient(this._token, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _token.getValue();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Never _fail(http.Response r) {
    String message = r.body;
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map && decoded['error'] is Map) {
        message = (decoded['error']['message'] as String?) ?? r.body;
      }
    } catch (_) {
      // Keep raw body.
    }
    throw PlayApiException(r.statusCode, message);
  }

  /// Opens a new edit transaction and returns its id.
  Future<String> insertEdit(String packageName) async {
    final uri = Uri.parse('$_base/applications/$packageName/edits');
    final r = await _httpClient.post(uri, headers: await _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) _fail(r);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final id = body['id'] as String?;
    if (id == null) {
      throw PlayApiException(r.statusCode, 'Edit response missing id: ${r.body}');
    }
    return id;
  }

  /// Commits an edit, applying all staged image changes to the listing.
  ///
  /// [changesNotSentForReview] stages the changes as a draft ("Changes not
  /// sent for review") instead of automatically submitting the whole store
  /// listing for review — the safe default for an asset-only tool. The user
  /// then publishes from the Play Console.
  Future<void> commitEdit(
    String packageName,
    String editId, {
    bool changesNotSentForReview = true,
  }) async {
    final uri = Uri.parse(
      '$_base/applications/$packageName/edits/$editId:commit',
    ).replace(
      queryParameters: {
        'changesNotSentForReview': changesNotSentForReview.toString(),
      },
    );
    final r = await _httpClient.post(uri, headers: await _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) _fail(r);
  }

  /// Abandons an edit, discarding all staged changes. Best-effort.
  Future<void> deleteEdit(String packageName, String editId) async {
    final uri = Uri.parse('$_base/applications/$packageName/edits/$editId');
    try {
      await _httpClient.delete(uri, headers: await _headers());
    } catch (_) {
      // Abandoning is best-effort; ignore failures.
    }
  }

  /// Lists image ids for a given language + image type.
  Future<List<String>> listImages(
    String packageName,
    String editId,
    String language,
    String imageType,
  ) async {
    final uri = Uri.parse(
      '$_base/applications/$packageName/edits/$editId/listings/$language/$imageType',
    );
    final r = await _httpClient.get(uri, headers: await _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) _fail(r);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final images = (body['images'] as List?) ?? const [];
    return images
        .map((e) => (e as Map<String, dynamic>)['id'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Deletes all images of the given type for a language (the `deleteall`
  /// operation).
  Future<void> deleteAllImages(
    String packageName,
    String editId,
    String language,
    String imageType,
  ) async {
    final uri = Uri.parse(
      '$_base/applications/$packageName/edits/$editId/listings/$language/$imageType',
    );
    final r = await _httpClient.delete(uri, headers: await _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) _fail(r);
  }

  /// Uploads a single image and returns the new image id (if returned).
  Future<String?> uploadImage({
    required String packageName,
    required String editId,
    required String language,
    required String imageType,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final uri = Uri.parse(
      '$_uploadBase/applications/$packageName/edits/$editId/listings/$language/$imageType',
    ).replace(queryParameters: {'uploadType': 'media'});

    final token = await _token.getValue();
    final r = await _httpClient.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': contentType},
      body: bytes,
    );
    if (r.statusCode < 200 || r.statusCode >= 300) _fail(r);
    try {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final image = body['image'] as Map<String, dynamic>?;
      return image?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
    _token.dispose();
  }
}
