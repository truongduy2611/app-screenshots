import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_screenshot.dart';

class AppScreenshotSet extends CallableModel {
  static const type = 'appScreenshotSets';

  final String screenshotDisplayType;
  final List<AppScreenshot> appScreenshots;

  AppScreenshotSet(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    Map<String, dynamic> relations,
  ) : screenshotDisplayType = attributes['screenshotDisplayType'] ?? '',
      appScreenshots = (relations['appScreenshots'] as List? ?? [])
          .cast<AppScreenshot>(),
      super(type, id, client);
}

class AppScreenshotSetAttributes implements ModelAttributes {
  final String screenshotDisplayType;

  AppScreenshotSetAttributes({required this.screenshotDisplayType});

  @override
  Map<String, dynamic> toMap() {
    return {'screenshotDisplayType': screenshotDisplayType};
  }
}
