import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';

/// Represents an `appInfoLocalizations` resource from App Store Connect.
///
/// Used to add new languages to an app at the app-info level, which is
/// required before creating version-level localizations.
class AppInfoLocalization extends Model {
  static const type = 'appInfoLocalizations';

  final String locale;

  AppInfoLocalization(String id, Map<String, dynamic> attributes)
    : locale = attributes['locale'] ?? '',
      super(type, id);
}

/// Create attributes for adding a new app-level locale.
class AppInfoLocalizationCreateAttributes implements ModelAttributes {
  final Map<String, dynamic> _attributes;

  AppInfoLocalizationCreateAttributes({required String locale})
    : _attributes = {'locale': locale};

  @override
  Map<String, dynamic> toMap() => _attributes;
}
