import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/screenshot_presets.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/icon_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

part 'command_server_utils.dart';
part 'command_server_editor.dart';
part 'command_server_library.dart';
part 'command_server_translate.dart';
part 'command_server_preset.dart';
part 'command_server_multi.dart';

/// Embedded HTTP server that exposes the app's editor API for CLI/agent control.
///
/// Binds to `localhost` only. The CLI discovers the port via a port file at
/// `~/.config/app-screenshots/server.port`.
///
/// Route handlers are split across part files:
/// - [_EditorRoutes]       → `command_server_editor.dart`
/// - [_LibraryRoutes]      → `command_server_library.dart`
/// - [_TranslationRoutes]  → `command_server_translate.dart`
/// - [_PresetRoutes]       → `command_server_preset.dart`
/// - [_MultiRoutes]        → `command_server_multi.dart`
/// - [ApiRoute], [ServerResponse] → `command_server_utils.dart`
class CommandServer {
  static const _tag = 'CommandServer';
  static const int defaultPort = AppConstants.defaultPort;

  HttpServer? _server;
  int? _port;

  // ── Registered cubits ──

  /// Currently active editor cubit — set by the editor page when it mounts.
  ScreenshotEditorCubit? _editorCubit;

  /// Multi-screenshot cubit — set when multi-editor is open.
  MultiScreenshotCubit? _multiCubit;

  /// Library cubit — set once at startup.
  ScreenshotLibraryCubit? _libraryCubit;

  /// Translation cubit — set by the editor page.
  TranslationCubit? _translationCubit;

  // ── Callbacks ──

  /// Capture callback — registered by the page that holds the ScreenshotController.
  Future<Uint8List?> Function()? _captureCallback;

  /// Sync callback — tells the page to sync editor changes back to multi state.
  void Function()? _syncCallback;

  /// Navigate-to-multi callback — registered by the studio page to open a
  /// multi-screenshot editor with the given display type. Returns a Future
  /// that completes once the editor is ready and cubits are registered.
  Future<void> Function(String displayType)? _navigateToMultiCallback;

  // ── Services ──

  /// Persistence service for direct design I/O.
  final ScreenshotPersistenceService _persistenceService;

  /// Design file service for import/export.
  final DesignFileService _designFileService;

  CommandServer({
    required ScreenshotPersistenceService persistenceService,
    DesignFileService? designFileService,
  }) : _persistenceService = persistenceService,
       _designFileService = designFileService ?? DesignFileService();

  int? get port => _port;
  bool get isRunning => _server != null;

  // ═══════════════════════════════════════════════════════════════════════════
  // Cubit registration
  // ═══════════════════════════════════════════════════════════════════════════

  void registerEditor(ScreenshotEditorCubit cubit) {
    _editorCubit = cubit;
    if (isRunning) AppLogger.d('Editor cubit registered', tag: _tag);
  }

  void unregisterEditor(ScreenshotEditorCubit cubit) {
    if (_editorCubit == cubit) {
      _editorCubit = null;
      if (isRunning) AppLogger.d('Editor cubit unregistered', tag: _tag);
    }
  }

  void registerMulti(MultiScreenshotCubit cubit) {
    _multiCubit = cubit;
    if (isRunning) AppLogger.d('Multi cubit registered', tag: _tag);
  }

  void unregisterMulti(MultiScreenshotCubit cubit) {
    if (_multiCubit == cubit) {
      _multiCubit = null;
      if (isRunning) AppLogger.d('Multi cubit unregistered', tag: _tag);
    }
  }

  void registerLibrary(ScreenshotLibraryCubit cubit) {
    _libraryCubit = cubit;
    if (isRunning) AppLogger.d('Library cubit registered', tag: _tag);
  }

  void registerTranslation(TranslationCubit cubit) {
    _translationCubit = cubit;
    if (isRunning) AppLogger.d('Translation cubit registered', tag: _tag);
  }

  void unregisterTranslation(TranslationCubit cubit) {
    if (_translationCubit == cubit) {
      _translationCubit = null;
      if (isRunning) AppLogger.d('Translation cubit unregistered', tag: _tag);
    }
  }

  /// Register capture callback from the page that holds the ScreenshotController.
  void registerCapture({
    required Future<Uint8List?> Function() captureImage,
    required void Function() syncChanges,
  }) {
    _captureCallback = captureImage;
    _syncCallback = syncChanges;
    if (isRunning) AppLogger.d('Capture callback registered', tag: _tag);
  }

  void unregisterCapture() {
    _captureCallback = null;
    _syncCallback = null;
    if (isRunning) AppLogger.d('Capture callback unregistered', tag: _tag);
  }

  /// Register navigation callback from the studio page so CLI can open editors.
  void registerNavigation({
    required Future<void> Function(String displayType) openMulti,
  }) {
    _navigateToMultiCallback = openMulti;
    if (isRunning) AppLogger.d('Navigation callback registered', tag: _tag);
  }

  void unregisterNavigation() {
    _navigateToMultiCallback = null;
    if (isRunning) AppLogger.d('Navigation callback unregistered', tag: _tag);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> start() async {
    int port = defaultPort;
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
        _port = port;
        break;
      } on SocketException {
        port++;
      }
    }

    if (_server == null) {
      AppLogger.error('Failed to start command server', tag: _tag);
      return;
    }

    AppLogger.i('Command server started on localhost:$_port', tag: _tag);
    await _writePortFile();
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
    await _removePortFile();
    AppLogger.i('Command server stopped', tag: _tag);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Port file management
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> get _configDir async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    final dir = '$home/.config/app-screenshots';
    await Directory(dir).create(recursive: true);
    return dir;
  }

  Future<void> _writePortFile() async {
    final dir = await _configDir;
    await File('$dir/server.port').writeAsString('$_port');
  }

  Future<void> _removePortFile() async {
    final dir = await _configDir;
    final file = File('$dir/server.port');
    if (await file.exists()) await file.delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP layer
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type')
      ..set('Content-Type', 'application/json');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    try {
      final result = await _route(request.method, path, request);
      _sendJson(request.response, result);
    } catch (e, st) {
      AppLogger.error(
        'Request error: $path',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _sendError(request.response, e.toString(), statusCode: 500);
    }
  }

  void _sendJson(
    HttpResponse response,
    Map<String, dynamic> data, {
    int statusCode = 200,
  }) {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    response.close();
  }

  void _sendError(
    HttpResponse response,
    String message, {
    int statusCode = 400,
  }) {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'ok': false, 'error': message}));
    response.close();
  }

  Future<Map<String, dynamic>> _readBody(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Route dispatcher — uses [ApiRoute] enum for type-safe matching
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _route(
    String method,
    String path,
    HttpRequest request,
  ) async {
    final route = ApiRoute.fromPath(path);
    if (route == null) return ServerResponse.error('Unknown route: $path');

    switch (route) {
      case ApiRoute.status:
        return ServerResponse.ok({
          'version': '1.0.0',
          'hasEditor': _editorCubit != null,
          'hasMulti': _multiCubit != null,
          'hasLibrary': true,
          'hasTranslation': _translationCubit != null,
        });
      case ApiRoute.editor:
        return handleEditor(route.actionFrom(path), method, request);
      case ApiRoute.library:
        return handleLibrary(route.actionFrom(path), method, request);
      case ApiRoute.translate:
        return handleTranslation(route.actionFrom(path), method, request);
      case ApiRoute.preset:
        return handlePreset(route.actionFrom(path), method, request);
      case ApiRoute.multi:
        return handleMulti(route.actionFrom(path), method, request);
    }
  }
}
