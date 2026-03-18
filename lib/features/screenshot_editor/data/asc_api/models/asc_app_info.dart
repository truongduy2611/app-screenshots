import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app_info_localization.dart';

/// Represents an `appInfos` resource from App Store Connect.
///
/// Contains app-level information including existing localizations.
class AppInfoModel extends Model {
  static const type = 'appInfos';

  final Map<String, dynamic> _relations;

  AppInfoModel(String id, Map<String, dynamic> attributes, this._relations)
    : super(type, id);

  List<AppInfoLocalization> get localizations =>
      _relations['appInfoLocalizations']?.cast<AppInfoLocalization>() ??
      const [];
}
