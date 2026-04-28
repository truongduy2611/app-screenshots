import 'dart:io';
import 'package:app_screenshots_shared/app_screenshots_shared.dart';

void main() {
  final buffer = StringBuffer();
  buffer.writeln('openapi: 3.0.0');
  buffer.writeln('info:');
  buffer.writeln('  title: App Screenshots API');
  buffer.writeln('  description: Local API for controlling the App Screenshots editor.');
  buffer.writeln('  version: 1.0.0');
  buffer.writeln('servers:');
  buffer.writeln('  - url: http://localhost:19222');
  buffer.writeln('paths:');

  void writeAction(String tag, String path, String actionName) {
    buffer.writeln('  $path:');
    buffer.writeln('    post:');
    buffer.writeln('      tags:');
    buffer.writeln('        - $tag');
    buffer.writeln('      summary: Execute $actionName');
    buffer.writeln('      requestBody:');
    buffer.writeln('        required: false');
    buffer.writeln('        content:');
    buffer.writeln('          application/json:');
    buffer.writeln('            schema:');
    buffer.writeln('              type: object');
    buffer.writeln('      responses:');
    buffer.writeln('        "200":');
    buffer.writeln('          description: Successful execution');
    buffer.writeln('          content:');
    buffer.writeln('            application/json:');
    buffer.writeln('              schema:');
    buffer.writeln('                type: object');
  }

  // Generate for each action
  for (final action in EditorAction.values) {
    writeAction('Editor', action.path, action.actionName);
  }
  for (final action in LibraryAction.values) {
    writeAction('Library', action.path, action.actionName);
  }
  for (final action in MultiAction.values) {
    writeAction('Multi', action.path, action.actionName);
  }
  for (final action in TranslateAction.values) {
    writeAction('Translate', action.path, action.actionName);
  }
  for (final action in PresetAction.values) {
    writeAction('Preset', action.path, action.actionName);
  }

  // Status route
  buffer.writeln('  /api/status:');
  buffer.writeln('    get:');
  buffer.writeln('      tags:');
  buffer.writeln('        - Server');
  buffer.writeln('      summary: Get server status');
  buffer.writeln('      responses:');
  buffer.writeln('        "200":');
  buffer.writeln('          description: Successful execution');

  final yamlContent = buffer.toString();
  
  final dir = Directory('docs/api');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  File('docs/api/openapi.yaml').writeAsStringSync(yamlContent);
  print('Generated docs/api/openapi.yaml');

  final dartFile = File('lib/core/services/command_server_openapi.dart');
  final dartContent = '''
// GENERATED FILE - DO NOT EDIT MANUALLY
// Run `dart run scripts/generate_openapi.dart` to update

part of 'command_server.dart';

const String _openApiYaml = r\'\'\'
$yamlContent\'\'\';

const String _swaggerUiHtml = r\'\'\'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>App Screenshots API Docs</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />
  <style>
    body { margin: 0; padding: 0; }
    .swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
<div id="swagger-ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"></script>
<script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js"></script>
<script>
window.onload = () => {
  window.ui = SwaggerUIBundle({
    url: '/api/docs/openapi.yaml',
    dom_id: '#swagger-ui',
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    layout: "StandaloneLayout"
  });
};
</script>
</body>
</html>
\'\'\';
''';
  dartFile.writeAsStringSync(dartContent);
  print('Generated lib/core/services/command_server_openapi.dart');
}
