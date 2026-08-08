import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_screenshot_set.dart';

/// Represents an App Store Connect Custom Product Page (CPP).
class AppCustomProductPage extends CallableModel {
  static const type = 'appCustomProductPages';

  final String name;
  final String? url;
  final bool visible;
  final Map<String, dynamic> _relations;

  AppCustomProductPage(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    this._relations,
  ) : name = attributes['name'] ?? '',
      url = attributes['url'],
      visible = attributes['visible'] ?? true,
      super(type, id, client);

  List<AppCustomProductPageVersion> get versions =>
      _relations['appCustomProductPageVersions']
          ?.cast<AppCustomProductPageVersion>() ??
      const [];

  Future<List<AppCustomProductPageVersion>> getVersions() async {
    final request = GetRequest(
      AppStoreConnectUri.v1(
        'appCustomProductPages/$id/appCustomProductPageVersions',
      ),
    );
    final response = await client.get(request);
    return response.asList<AppCustomProductPageVersion>();
  }

  @override
  String toString() => '$name ($id)';
}

/// Represents a version of a Custom Product Page.
class AppCustomProductPageVersion extends CallableModel {
  static const type = 'appCustomProductPageVersions';

  final String state;
  final Map<String, dynamic> _relations;

  AppCustomProductPageVersion(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    this._relations,
  ) : state = attributes['state'] ?? attributes['versionState'] ?? '',
      super(type, id, client);

  /// State indicates whether this CPP version is editable (e.g. PREPARE_FOR_SUBMISSION, DRAFT, REJECTED).
  bool get editable {
    final s = state.toUpperCase();
    return s == 'PREPARE_FOR_SUBMISSION' ||
        s == 'DRAFT' ||
        s == 'REJECTED' ||
        s == 'DEVELOPER_REJECTED' ||
        s == 'METADATA_REJECTED';
  }

  List<AppCustomProductPageLocalization> get localizations =>
      _relations['appCustomProductPageLocalizations']
          ?.cast<AppCustomProductPageLocalization>() ??
      const [];

  Future<List<AppCustomProductPageLocalization>> getLocalizations() async {
    final request = GetRequest(
      AppStoreConnectUri.v1(
        'appCustomProductPageVersions/$id/appCustomProductPageLocalizations',
      ),
    );
    final response = await client.get(request);
    return response.asList<AppCustomProductPageLocalization>();
  }

  @override
  String toString() => 'CPP Version $id ($state)';
}

/// Represents a localization of a Custom Product Page.
class AppCustomProductPageLocalization extends CallableModel {
  static const type = 'appCustomProductPageLocalizations';

  final String locale;
  final String? promotionalText;

  AppCustomProductPageLocalization(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
  ) : locale = attributes['locale'] ?? '',
      promotionalText = attributes['promotionalText'],
      super(type, id, client);

  Future<List<AppScreenshotSet>> getScreenshotSets() async {
    final request = GetRequest(
      AppStoreConnectUri.v1(
        'appCustomProductPageLocalizations/$id/appScreenshotSets',
      ),
    );
    request.include('appScreenshots');
    final response = await client.get(request);
    return response.asList<AppScreenshotSet>();
  }

  @override
  String toString() => '$locale ($id)';
}

class AppCustomProductPageLocalizationCreateAttributes
    implements ModelAttributes {
  final Map<String, dynamic> _attributes;

  AppCustomProductPageLocalizationCreateAttributes({required String locale})
    : _attributes = {'locale': locale};

  @override
  Map<String, dynamic> toMap() => _attributes;
}
