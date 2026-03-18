import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_build.dart';

class App extends Model {
  static const type = 'apps';

  final Map<String, dynamic> _relations;

  final String name;
  final String bundleId;
  final String sku;
  final String primaryLocale;

  App(String id, Map<String, dynamic> attributes, [this._relations = const {}])
    : name = attributes['name'],
      bundleId = attributes['bundleId'],
      sku = attributes['sku'] ?? '',
      primaryLocale = attributes['primaryLocale'] ?? 'en-US',
      super(type, id);

  List<Build> get builds => _relations['builds']?.cast<Build>() ?? const [];

  /// Returns the app icon URL from the latest build's icon asset token,
  /// or null if no build or icon is available.
  String? get iconUrl {
    for (final build in builds) {
      if (build.iconAssetToken != null) {
        return build.iconAssetToken!.templateUrl
            .replaceAll('{w}', '120')
            .replaceAll('{h}', '120')
            .replaceAll('{f}', 'png');
      }
    }
    return null;
  }

  @override
  String toString() => '$name ($bundleId)';
}
