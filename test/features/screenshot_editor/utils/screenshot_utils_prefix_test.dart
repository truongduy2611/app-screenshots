import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenshotUtils.stripCreateModePrefix', () {
    test('strips every creation-mode prefix', () {
      expect(
        ScreenshotUtils.stripCreateModePrefix('multi:APP_IPHONE_69'),
        'APP_IPHONE_69',
      );
      expect(
        ScreenshotUtils.stripCreateModePrefix('board:APP_IPHONE_69'),
        'APP_IPHONE_69',
      );
    });

    test('leaves a bare display type untouched', () {
      expect(
        ScreenshotUtils.stripCreateModePrefix('APP_IPHONE_69'),
        'APP_IPHONE_69',
      );
    });

    test('a stripped key resolves to real dimensions, an unstripped one does not',
        () {
      // The dialog remembers its last mode, so a "clone to format" flow can
      // receive a prefixed value. getDimensions falls back silently for an
      // unknown key, which is why the prefix must be stripped first.
      const raw = 'board:APP_IPHONE_65';
      final fallback = ScreenshotUtils.getDimensions(raw, Orientation.portrait);
      final real = ScreenshotUtils.getDimensions(
        ScreenshotUtils.stripCreateModePrefix(raw),
        Orientation.portrait,
      );

      expect(real, const Size(1284, 2778));
      expect(fallback, isNot(real));
    });
  });
}
