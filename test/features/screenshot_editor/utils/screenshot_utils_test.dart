import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenshotUtils', () {
    group('getDimensions', () {
      test('returns correct iPhone 6.7" dimensions in portrait', () {
        final size = ScreenshotUtils.getDimensions(
          'APP_IPHONE_67',
          Orientation.portrait,
        );
        expect(size, const Size(1290, 2796));
      });

      test('returns swapped dimensions in landscape', () {
        final size = ScreenshotUtils.getDimensions(
          'APP_IPHONE_67',
          Orientation.landscape,
        );
        expect(size, const Size(2796, 1290));
      });

      test('returns iPad Pro 12.9" dimensions', () {
        final size = ScreenshotUtils.getDimensions(
          'APP_IPAD_PRO_3GEN_129',
          Orientation.portrait,
        );
        expect(size, const Size(2048, 2732));
      });

      test('returns default dimensions for unknown display type', () {
        final size = ScreenshotUtils.getDimensions(
          'UNKNOWN_DISPLAY',
          Orientation.portrait,
        );
        expect(size, const Size(1290, 2796));
      });

      test('returns Mac dimensions', () {
        final size = ScreenshotUtils.getDimensions(
          'APP_DESKTOP',
          Orientation.portrait,
        );
        expect(size, const Size(2880, 1800));
      });

      test('returns Watch dimensions', () {
        final size = ScreenshotUtils.getDimensions(
          'APP_WATCH_ULTRA',
          Orientation.portrait,
        );
        expect(size, const Size(410, 502));
      });
    });

    group('getDeviceCategory', () {
      test('returns iphone for iPhone display types', () {
        expect(
          ScreenshotUtils.getDeviceCategory('APP_IPHONE_67'),
          DeviceCategory.iphone,
        );
        expect(
          ScreenshotUtils.getDeviceCategory('APP_IPHONE_55'),
          DeviceCategory.iphone,
        );
      });

      test('returns ipad for iPad display types', () {
        expect(
          ScreenshotUtils.getDeviceCategory('APP_IPAD_PRO_3GEN_129'),
          DeviceCategory.ipad,
        );
      });

      test('returns watch for Watch display types', () {
        expect(
          ScreenshotUtils.getDeviceCategory('APP_WATCH_ULTRA'),
          DeviceCategory.watch,
        );
      });

      test('returns mac for Desktop display types', () {
        expect(
          ScreenshotUtils.getDeviceCategory('APP_DESKTOP'),
          DeviceCategory.mac,
        );
      });

      test('returns tv for Apple TV display types', () {
        expect(
          ScreenshotUtils.getDeviceCategory('APP_APPLE_TV'),
          DeviceCategory.tv,
        );
      });

      test('returns iphone for unknown display types', () {
        expect(
          ScreenshotUtils.getDeviceCategory('UNKNOWN'),
          DeviceCategory.iphone,
        );
      });
    });

    group('getSupportedDimensions', () {
      test('returns multiple dimensions for types with variants', () {
        final dims = ScreenshotUtils.getSupportedDimensions('APP_IPHONE_65');
        expect(dims.length, 2);
        expect(dims[0], const Size(1284, 2778));
        expect(dims[1], const Size(1242, 2688));
      });

      test('returns single dimension for simple types', () {
        final dims = ScreenshotUtils.getSupportedDimensions('APP_IPHONE_67');
        expect(dims.length, 1);
      });

      test('returns default for unknown type', () {
        final dims = ScreenshotUtils.getSupportedDimensions('UNKNOWN');
        expect(dims.length, 1);
        expect(dims[0], const Size(1290, 2796));
      });
    });
  });
}
