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
  buffer.writeln('components:');
  buffer.writeln('  schemas:');
  buffer.writeln('    SuccessResponse:');
  buffer.writeln('      type: object');
  buffer.writeln('      properties:');
  buffer.writeln('        ok:');
  buffer.writeln('          type: boolean');
  buffer.writeln('          example: true');
  buffer.writeln('        data:');
  buffer.writeln('          type: object');
  buffer.writeln('    ErrorResponse:');
  buffer.writeln('      type: object');
  buffer.writeln('      properties:');
  buffer.writeln('        ok:');
  buffer.writeln('          type: boolean');
  buffer.writeln('          example: false');
  buffer.writeln('        error:');
  buffer.writeln('          type: string');
  buffer.writeln('          example: "Invalid parameter"');
  buffer.writeln('paths:');

  void writeAction(String tag, String path, String actionName, {Map<String, String>? schemaProps, List<String>? required}) {
    buffer.writeln('  $path:');
    buffer.writeln('    post:');
    buffer.writeln('      tags:');
    buffer.writeln('        - $tag');
    buffer.writeln('      summary: Execute $actionName');
    
    if (schemaProps != null && schemaProps.isNotEmpty) {
      buffer.writeln('      requestBody:');
      buffer.writeln('        required: true');
      buffer.writeln('        content:');
      buffer.writeln('          application/json:');
      buffer.writeln('            schema:');
      buffer.writeln('              type: object');
      if (required != null && required.isNotEmpty) {
        buffer.writeln('              required:');
        for (final req in required) {
          buffer.writeln('                - $req');
        }
      }
      buffer.writeln('              properties:');
      schemaProps.forEach((key, typeDesc) {
        buffer.writeln('                $key:');
        final lines = typeDesc.split('\\n');
        for (final line in lines) {
          buffer.writeln('                  $line');
        }
      });
    }
    
    buffer.writeln('      responses:');
    buffer.writeln('        "200":');
    buffer.writeln('          description: Successful execution');
    buffer.writeln('          content:');
    buffer.writeln('            application/json:');
    buffer.writeln('              schema:');
    buffer.writeln('                \$ref: "#/components/schemas/SuccessResponse"');
  }

  // --- Editor Core Schemas ---
  final Map<EditorAction, Map<String, dynamic>> editorSchemas = {
    EditorAction.setBackground: {
      'req': ['color'],
      'props': { 'color': 'type: string\\nexample: "#FF5733"\\ndescription: Hex color code' }
    },
    EditorAction.setFrame: {
      'req': ['device'],
      'props': { 'device': 'type: string\\nexample: "iPhone 16 Pro"\\ndescription: Device name string' }
    },
    EditorAction.setImage: {
      'req': ['file'],
      'props': { 'file': 'type: string\\nexample: "/path/to/image.png"\\ndescription: Absolute path to image' }
    },
    EditorAction.addText: {
      'req': ['text', 'fontSize'],
      'props': { 
        'text': 'type: string\\nexample: "Hello World"',
        'fontSize': 'type: number\\nexample: 40',
        'font': 'type: string\\nexample: "Inter"',
        'color': 'type: string\\nexample: "#FFFFFF"',
        'x': 'type: number',
        'y': 'type: number',
        'width': 'type: number',
        'align': 'type: string\\nenum: [left, center, right]'
      }
    },
    EditorAction.updateText: {
      'req': ['id'],
      'props': { 
        'id': 'type: string\\ndescription: Overlay ID',
        'text': 'type: string',
        'fontSize': 'type: number',
        'font': 'type: string',
        'color': 'type: string',
        'x': 'type: number',
        'y': 'type: number',
        'width': 'type: number',
        'align': 'type: string',
        'scale': 'type: number',
        'rotation': 'type: number'
      }
    },
    EditorAction.addImage: {
      'req': ['file'],
      'props': {
        'file': 'type: string\\ndescription: Absolute path to image',
        'x': 'type: number',
        'y': 'type: number',
        'width': 'type: number',
        'height': 'type: number'
      }
    },
    EditorAction.setMeshGradient: {
      'req': [],
      'props': {
        'mesh': 'type: object\\ndescription: JSON representing mesh gradient points'
      }
    },
    EditorAction.setDoodle: {
      'req': ['enabled'],
      'props': {
        'enabled': 'type: boolean',
        'iconSource': 'type: integer\\ndescription: 0=sf, 1=material, 2=emoji',
        'iconSize': 'type: number',
        'spacing': 'type: number',
        'iconOpacity': 'type: number',
        'rotation': 'type: number',
        'iconColor': 'type: integer'
      }
    },
    EditorAction.export_: {
      'req': [],
      'props': { 'path': 'type: string\\ndescription: Output file path (optional)' }
    },
    EditorAction.setPadding: {
      'req': ['padding'],
      'props': { 'padding': 'type: number' }
    },
    EditorAction.setCornerRadius: {
      'req': ['radius'],
      'props': { 'radius': 'type: number' }
    },
    EditorAction.setRotation: {
      'req': [],
      'props': { 'x': 'type: number', 'y': 'type: number', 'z': 'type: number' }
    },
  };

  // --- Translate Core Schemas ---
  final Map<TranslateAction, Map<String, dynamic>> translateSchemas = {
    TranslateAction.applyManual: {
      'req': ['locale', 'translations'],
      'props': {
        'locale': 'type: string\\nexample: "es"',
        'translations': 'type: object\\nadditionalProperties: true\\ndescription: Map of overlayId to text'
      }
    },
    TranslateAction.overrideOverlay: {
      'req': ['locale', 'id'],
      'props': {
        'locale': 'type: string',
        'id': 'type: string',
        'text': 'type: string',
        'fontSize': 'type: number',
        'font': 'type: string',
        'color': 'type: string',
        'x': 'type: number',
        'y': 'type: number',
        'width': 'type: number',
        'scale': 'type: number',
        'rotation': 'type: number'
      }
    },
    TranslateAction.setLocaleImage: {
      'req': ['locale', 'file'],
      'props': {
        'locale': 'type: string',
        'file': 'type: string'
      }
    }
  };

  // --- Multi Core Schemas ---
  final Map<MultiAction, Map<String, dynamic>> multiSchemas = {
    MultiAction.addDesign: {
      'req': ['displayType'],
      'props': { 'displayType': 'type: string\\nexample: "APP_IPHONE_69"' }
    },
    MultiAction.batch: {
      'req': ['action'],
      'props': {
        'action': 'type: string\\nexample: "set-background"',
        'value': 'type: string',
        'color': 'type: string',
        'file': 'type: string'
      }
    }
  };

  // Generate Editor
  for (final action in EditorAction.values) {
    final schema = editorSchemas[action];
    writeAction('Editor', action.path, action.actionName, 
      schemaProps: (schema?['props'] as Map?)?.cast<String, String>(),
      required: (schema?['req'] as List?)?.cast<String>(),
    );
  }
  
  // Generate Library
  for (final action in LibraryAction.values) {
    writeAction('Library', action.path, action.actionName);
  }
  
  // Generate Multi
  for (final action in MultiAction.values) {
    final schema = multiSchemas[action];
    writeAction('Multi', action.path, action.actionName,
      schemaProps: (schema?['props'] as Map?)?.cast<String, String>(),
      required: (schema?['req'] as List?)?.cast<String>(),
    );
  }
  
  // Generate Translate
  for (final action in TranslateAction.values) {
    final schema = translateSchemas[action];
    writeAction('Translate', action.path, action.actionName,
      schemaProps: (schema?['props'] as Map?)?.cast<String, String>(),
      required: (schema?['req'] as List?)?.cast<String>(),
    );
  }
  
  // Generate Preset
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
  buffer.writeln('          content:');
  buffer.writeln('            application/json:');
  buffer.writeln('              schema:');
  buffer.writeln('                \$ref: "#/components/schemas/SuccessResponse"');

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

const String _openApiYaml = r\"\"\"
\$yamlContent\"\"\";

const String _swaggerUiHtml = r\"\"\"
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
\"\"\";
''';
  dartFile.writeAsStringSync(dartContent);
  print('Generated lib/core/services/command_server_openapi.dart');
}
