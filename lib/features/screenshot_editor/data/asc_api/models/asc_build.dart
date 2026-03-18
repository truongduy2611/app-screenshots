import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';

class ImageAsset {
  final String templateUrl;
  final int width;
  final int height;

  ImageAsset(Map<String, dynamic> attributes)
    : templateUrl = attributes['templateUrl'],
      width = attributes['width'],
      height = attributes['height'];
}

class Build extends Model {
  static const type = 'builds';

  final String version;
  final ImageAsset? iconAssetToken;

  Build(String id, Map<String, dynamic> attributes)
    : version = attributes['version'] ?? '',
      iconAssetToken = attributes['iconAssetToken'] != null
          ? ImageAsset(attributes['iconAssetToken'])
          : null,
      super(type, id);
}
