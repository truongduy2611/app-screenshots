part of 'command_server.dart';

// =============================================================================
// Preset routes — list / show screenshot presets
// =============================================================================

extension _PresetRoutes on CommandServer {
  Future<Map<String, dynamic>> handlePreset(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final presetAction = PresetAction.fromActionName(action);
    if (presetAction == null) {
      return ServerResponse.error('Unknown preset action: $action');
    }

    switch (presetAction) {
      case PresetAction.list:
        return ServerResponse.ok(
          ScreenshotPresets.all
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'description': p.description,
                  'designCount': p.designs.length,
                },
              )
              .toList(),
        );

      case PresetAction.show:
        final body = await _readBody(request);
        final id = body['id'] as String? ?? request.uri.queryParameters['id'];
        if (id == null) return ServerResponse.error('Missing "id"');
        final preset = ScreenshotPresets.all
            .where((p) => p.id == id)
            .firstOrNull;
        if (preset == null)
          return ServerResponse.error('Preset not found: $id');
        return ServerResponse.ok(preset.toJson());
    }
  }
}
