import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:flutter/services.dart';

/// Thin wrapper around the native `app_icon` method channel.
class AppIconService {
  static const _channel = MethodChannel('app_icon');

  /// Sets the app icon on macOS (dock) or iOS (home screen).
  ///
  /// [iconName] should be `"default"` or `"alternative"`.
  Future<void> setIcon(String iconName) async {
    try {
      await _channel.invokeMethod('setIcon', iconName);
    } on MissingPluginException {
      // Platform doesn't implement the channel – ignore silently.
      AppLogger.w('setIcon not supported on this platform', tag: 'AppIcon');
    } on PlatformException catch (e) {
      AppLogger.w('Failed to set icon: ${e.message}', tag: 'AppIcon');
    }
  }
}
