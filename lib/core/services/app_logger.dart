import 'dart:developer';
import 'package:flutter/foundation.dart';

/// Lightweight structured logger.
///
/// All calls are no-ops in release mode (`kReleaseMode`).
/// Usage:
/// ```dart
/// AppLogger.d('Loading designs', tag: 'LibraryCubit');
/// AppLogger.error('Failed to save', error: e, stackTrace: st, tag: 'Persistence');
/// ```
class AppLogger {
  AppLogger._();

  static const _reset = '\x1B[0m';
  static const _cyan = '\x1B[36m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';

  /// Debug-level message.
  static void d(String message, {String? tag}) {
    _log(_cyan, 'D', message, tag: tag);
  }

  /// Info-level message.
  static void i(String message, {String? tag}) {
    _log(_green, 'I', message, tag: tag);
  }

  /// Warning-level message.
  static void w(String message, {String? tag}) {
    _log(_yellow, 'W', message, tag: tag);
  }

  /// Error-level message with optional error object and stack trace.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(_red, 'E', message, tag: tag);
    if (error != null) {
      _log(_red, 'E', '  ↳ $error', tag: tag);
    }
    if (stackTrace != null) {
      _log(_red, 'E', '  ↳ $stackTrace', tag: tag);
    }
  }

  static void _log(String color, String level, String message, {String? tag}) {
    if (kReleaseMode) return;
    final prefix = tag != null ? '[$tag] ' : '';
    log('$color[$level]$_reset $prefix$message');
  }
}
