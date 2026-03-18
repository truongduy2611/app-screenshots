import 'package:flutter/material.dart';

/// Shared responsive breakpoint utilities.
///
/// Use these helpers to avoid duplicating width checks across the codebase.
/// Breakpoints:
///   phone  : width < 600
///   tablet : 600 ≤ width < 1024
///   desktop: width ≥ 1024
class ResponsiveUtils {
  ResponsiveUtils._();

  static const double phoneBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// True on phone-class screens (< 600 logical px).
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phoneBreakpoint;

  /// True on tablet-class screens (600–1024 logical px).
  static bool isMediumScreen(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= phoneBreakpoint && w < tabletBreakpoint;
  }

  /// True on desktop-class screens (≥ 1024 logical px).
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Returns a value appropriate for the current screen class.
  static T adaptive<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    required T desktop,
  }) {
    if (isSmallScreen(context)) return phone;
    if (isMediumScreen(context)) return tablet ?? desktop;
    return desktop;
  }

  /// Returns dialog constraints that fit the current screen.
  ///
  /// On phones the dialog fills the width (minus 32 px margin).
  /// On larger screens it caps at [desktopMaxWidth].
  static BoxConstraints adaptiveDialogConstraints(
    BuildContext context, {
    double desktopMaxWidth = 480,
    double desktopMaxHeight = 640,
  }) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < phoneBreakpoint) {
      return BoxConstraints(
        maxWidth: size.width - 32,
        maxHeight: size.height * 0.85,
      );
    }
    return BoxConstraints(
      maxWidth: desktopMaxWidth,
      maxHeight: desktopMaxHeight,
    );
  }

  /// Whether a dialog should be shown as a full-page route (phones)
  /// or a floating dialog (larger screens).
  static bool shouldUseFullPageDialog(BuildContext context) =>
      isSmallScreen(context);
}
