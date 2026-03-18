import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:flutter/material.dart';

/// Callback type for capturing all locale screenshots.
typedef CaptureAllLocaleScreenshots =
    Future<Map<String, List<File>>?> Function(BuildContext context);

/// Provides a [captureAllLocaleScreenshots] callback to descendants.
///
/// Placed in the widget tree by the multi-screenshot page so that
/// nested widgets (e.g., [TranslationControls]) can trigger
/// locale-aware screenshot capture without holding a reference
/// to the [ScreenshotController].
class ScreenshotCaptureProvider extends InheritedWidget {
  final CaptureAllLocaleScreenshots captureAllLocaleScreenshots;

  /// The current ASC app config saved in the design (may be null).
  final AscAppConfig? ascAppConfig;

  /// Called when the upload sheet selects / changes an app.
  final ValueChanged<AscAppConfig?>? onAscAppConfigChanged;

  const ScreenshotCaptureProvider({
    super.key,
    required this.captureAllLocaleScreenshots,
    this.ascAppConfig,
    this.onAscAppConfigChanged,
    required super.child,
  });

  static ScreenshotCaptureProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScreenshotCaptureProvider>();
  }

  @override
  bool updateShouldNotify(ScreenshotCaptureProvider oldWidget) {
    return captureAllLocaleScreenshots != oldWidget.captureAllLocaleScreenshots;
  }
}
