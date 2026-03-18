import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_token.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:http/http.dart';

abstract class AppStoreConnectUri {
  static Uri v1([String? resource]) {
    return Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/${resource ?? ''}',
    );
  }
}

class AppStoreConnectCredentials {
  final String keyId;
  final String issuerId;
  final String? keyFile;
  final String? keyContent;

  const AppStoreConnectCredentials({
    required this.keyId,
    required this.issuerId,
    this.keyFile,
    this.keyContent,
  });
}

class AppStoreConnectClient {
  final AppStoreConnectCredentials _credentials;
  final Client _client = Client();

  AppStoreConnectToken? _token;

  AppStoreConnectClient(this._credentials);

  Future<ApiResponse> get(GetRequest request) async {
    return _handle(_client.get(request.toUri(), headers: await _getHeaders()));
  }

  Future<ApiResponse> post(Uri uri, Map<String, dynamic> body) async {
    return _handle(
      _client.post(uri, headers: await _getHeaders(), body: jsonEncode(body)),
    );
  }

  Future<T> postModel<T extends Model>(
    Uri baseUri,
    String type, {
    ModelAttributes? attributes,
    Map<String, ModelRelationship>? relationships,
  }) async {
    final data = {
      'data': {
        'type': type,
        if (attributes != null)
          'attributes': attributes.toMap()
            ..removeWhere((_, value) => value == null),
        if (relationships != null)
          'relationships': relationships.map(
            (key, value) => MapEntry(key, {'data': value.toJson()}),
          ),
      },
    };
    final response = await post(Uri.parse('$baseUri$type'), data);
    return response.as<T>();
  }

  Future<ApiResponse> putBinary(
    Uri uri,
    Object bytes,
    Map<String, String> header,
  ) async {
    return _handle(
      _client.put(
        uri,
        headers: {...(await _getHeaders()), ...header},
        body: bytes,
      ),
    );
  }

  Future<ApiResponse> patch(Uri uri, Map<String, dynamic> data) async {
    return _handle(
      _client.patch(uri, headers: await _getHeaders(), body: jsonEncode(data)),
    );
  }

  Future<T> patchModel<T extends Model>(
    Uri baseUri,
    String type,
    String id, {
    ModelAttributes? attributes,
    Map<String, ModelRelationship>? relationships,
  }) async {
    final response = await patch(Uri.parse('$baseUri$type/$id'), {
      'data': {
        'type': type,
        'id': id,
        if (attributes != null)
          'attributes': attributes.toMap()
            ..removeWhere((_, value) => value == null),
        if (relationships != null)
          'relationships': relationships.map(
            (key, value) => MapEntry(key, {'data': value.toJson()}),
          ),
      },
    });
    return response.as<T>();
  }

  /// Fetches a single resource by its full URI.
  Future<T> getModel<T extends Model>(Uri uri) async {
    final response = await get(GetRequest(uri));
    return response.as<T>();
  }

  /// Deletes a resource at the given URI.
  Future<void> deleteResource(Uri uri) async {
    await _handle(_client.delete(uri, headers: await _getHeaders()));
  }

  /// Replaces the ordering of a to-many relationship.
  ///
  /// Used to set screenshot ordering via:
  /// PATCH appScreenshotSets/{id}/relationships/appScreenshots
  Future<void> replaceRelationshipOrder(
    Uri uri,
    String relatedType,
    List<String> orderedIds,
  ) async {
    await patch(uri, {
      'data': orderedIds.map((id) => {'type': relatedType, 'id': id}).toList(),
    });
  }

  Future<void> delete(Uri uri) async {
    await _handle(_client.delete(uri, headers: await _getHeaders()));
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    };
  }

  Future<AppStoreConnectToken> _getToken() async {
    if (_token != null) return _token!;

    if (_credentials.keyContent != null) {
      return _token = AppStoreConnectToken(
        keyId: _credentials.keyId,
        issuerId: _credentials.issuerId,
        key: _credentials.keyContent!,
      );
    } else if (_credentials.keyFile != null) {
      return _token = await AppStoreConnectToken.fromFile(
        keyId: _credentials.keyId,
        issuerId: _credentials.issuerId,
        path: _credentials.keyFile!,
      );
    } else {
      throw Exception('Credentials must have either keyFile or keyContent');
    }
  }

  Future<ApiResponse> _handle(Future<Response> operation) async {
    final response = await operation;
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return ApiResponse(this, response);
    } else {
      final request = response.request;
      if (request != null) {
        // ignore: avoid_print
        print(
          'failed [${request.method.toUpperCase()}] ${request.url}:\n${response.body}',
        );
      }
      throw ApiException.fromResponse(response);
    }
  }

  void dispose() {
    _client.close();
  }
}

class GetRequest {
  final Uri _uri;
  final Map<String, dynamic> _filters = {};
  final Set<String> _includes = {};
  final Map<String, String> _fields = {};
  final Map<String, int> _limits = {};
  int? _limit;

  GetRequest(this._uri);

  void filter(String field, dynamic value) {
    _filters[field] = value is Iterable
        ? value.map((item) => item.toString()).join(',')
        : value;
  }

  void include(String type, {List<String>? fields, int? limit}) {
    _includes.add(type);
    if (fields != null) {
      _fields[type] = fields.join(',');
    }
    if (limit != null) {
      _limits[type] = limit;
    }
  }

  void limit(int limit) {
    _limit = limit;
  }

  Uri toUri() {
    final params = <String, dynamic>{
      for (final filter in _filters.entries)
        'filter[${filter.key}]': filter.value,
      if (_includes.isNotEmpty) 'include': _includes.join(','),
      for (final fields in _fields.entries)
        'fields[${fields.key}]': fields.value,
      for (final limit in _limits.entries)
        'limit[${limit.key}]': limit.value.toString(),
      if (_limit != null) 'limit': _limit.toString(),
    };

    return (_uri).replace(queryParameters: params);
  }
}

class ApiResponse {
  final AppStoreConnectClient _client;
  final Response _response;

  ApiResponse(this._client, this._response);

  int get status => _response.statusCode;
  Map<String, dynamic> get json => jsonDecode(utf8.decode(_response.bodyBytes));

  List<T> asList<T extends Model>() => ModelParser.parseList<T>(_client, json);
  T as<T extends Model>() => ModelParser.parse<T>(_client, json);
}

class ApiException {
  final int statusCode;
  final List<ApiError> errors;

  ApiException.fromResponse(Response response)
    : this.fromJson(response.statusCode, jsonDecode(response.body));
  ApiException.fromJson(this.statusCode, Map<String, dynamic> json)
    : errors = (json['errors'] as List)
          .map((item) => ApiError.fromJson(item))
          .toList();

  @override
  String toString() => '$statusCode: ${errors.first}';
}

class ApiError {
  final String id;
  final int status;
  final String code;
  final String title;
  final String? detail;

  ApiError.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      status = int.parse(json['status']),
      code = json['code'],
      title = json['title'],
      detail = json['detail'];

  @override
  String toString() => '$code ${detail ?? title}';
}
