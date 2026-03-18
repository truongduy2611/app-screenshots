import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_screenshot_set.dart';

class VersionLocalization extends CallableModel {
  static const type = 'appStoreVersionLocalizations';

  final String locale;
  final String? description;
  final String? keywords;
  final String? whatsNew;

  VersionLocalization(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
  ) : locale = attributes['locale'],
      description = attributes['description'],
      keywords = attributes['keywords'],
      whatsNew = attributes['whatsNew'],
      super(type, id, client);

  Future<List<AppScreenshotSet>> getScreenshotSets() async {
    final request = GetRequest(
      AppStoreConnectUri.v1('versionLocalizations/$id/appScreenshotSets'),
    );
    request.include('appScreenshots');
    final response = await client.get(request);
    return response.asList<AppScreenshotSet>();
  }

  @override
  String toString() => '$locale ($id)';
}

class VersionLocalizationCreateAttributes implements ModelAttributes {
  final Map<String, dynamic> _attributes;

  VersionLocalizationCreateAttributes({required String locale})
    : _attributes = {'locale': locale};

  @override
  Map<String, dynamic> toMap() => _attributes;
}
