import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:flutter/services.dart';

/// Service that listens for `.appshots` file open events from the native
/// platform via the `file_open` method channel.
///
/// When a user taps or double-clicks a `.appshots` file in Files/Finder,
/// the native AppDelegate forwards the file path here. Consumers register
/// a callback via [onFileOpened] to handle the import.
class FileOpenService {
  static const _channel = MethodChannel('file_open');

  /// Files received before the callback was registered. These are flushed
  /// once [onFileOpened] is set.
  final List<File> _pendingFiles = [];

  /// Callback invoked when a `.appshots` file is opened by the system.
  void Function(File file)? _onFileOpened;

  set onFileOpened(void Function(File file)? callback) {
    _onFileOpened = callback;
    AppLogger.d(
      'Callback set (non-null: ${callback != null})',
      tag: 'FileOpen',
    );
    // Flush any files received before the callback was registered
    if (callback != null && _pendingFiles.isNotEmpty) {
      AppLogger.d(
        'Flushing ${_pendingFiles.length} pending files',
        tag: 'FileOpen',
      );
      for (final file in _pendingFiles) {
        callback(file);
      }
      _pendingFiles.clear();
    }
  }

  /// Starts listening for file open events and signals readiness to native.
  void init() {
    AppLogger.d('init — setting method call handler', tag: 'FileOpen');
    _channel.setMethodCallHandler(_handleMethodCall);

    // Tell native side we are ready to receive file open events.
    // This triggers flushing of any pending files queued during cold start.
    AppLogger.d('Sending ready signal to native', tag: 'FileOpen');
    _channel.invokeMethod<void>('ready');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    AppLogger.d('Received method call: ${call.method}', tag: 'FileOpen');
    AppLogger.d('Arguments: ${call.arguments}', tag: 'FileOpen');

    if (call.method == 'fileOpened') {
      final path = call.arguments as String?;
      AppLogger.d('File path: $path', tag: 'FileOpen');

      if (path != null && path.endsWith('.appshots')) {
        final file = File(path);
        final exists = await file.exists();
        AppLogger.d('File exists: $exists', tag: 'FileOpen');

        if (exists) {
          if (_onFileOpened != null) {
            AppLogger.d('Invoking callback', tag: 'FileOpen');
            _onFileOpened!.call(file);
          } else {
            AppLogger.d('No callback yet — buffering file', tag: 'FileOpen');
            _pendingFiles.add(file);
          }
        } else {
          AppLogger.w('File not found at $path', tag: 'FileOpen');
        }
      } else {
        AppLogger.d('Path is null or not .appshots', tag: 'FileOpen');
      }
    }
  }

  /// Stops listening for file open events.
  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
