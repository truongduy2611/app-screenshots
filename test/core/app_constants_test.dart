import 'package:app_screenshots/core/app_constants.dart';
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  tearDown(() {
    sl.reset();
  });

  group('AppConstants.appVersion', () {
    test('returns fallback 1.4.0 when PackageInfo is not registered', () {
      expect(AppConstants.appVersion, '1.4.0');
    });

    test('returns PackageInfo version when registered', () {
      final mockInfo = PackageInfo(
        appName: 'App Screenshots',
        packageName: 'com.progressiostudio.appScreenshots',
        version: '1.4.0',
        buildNumber: '23',
        buildSignature: '',
      );
      sl.registerSingleton<PackageInfo>(mockInfo);

      expect(AppConstants.appVersion, '1.4.0');
    });
  });
}
