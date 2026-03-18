import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import '../app_client.dart';
import '../output.dart';

/// `appshots editor` — subcommands for editor manipulation.
class EditorCommand extends Command<int> {
  @override
  String get name => 'editor';

  @override
  String get description => 'Control the screenshot editor';

  EditorCommand() {
    addSubcommand(_EditorStateCommand());
    addSubcommand(_EditorSetBackgroundCommand());
    addSubcommand(_EditorSetFrameCommand());
    addSubcommand(_EditorListDevicesCommand());
    addSubcommand(_EditorSetPaddingCommand());
    addSubcommand(_EditorSetCornerRadiusCommand());
    addSubcommand(_EditorSetRotationCommand());
    addSubcommand(_EditorSetImageCommand());
    addSubcommand(_EditorAddTextCommand());
    addSubcommand(_EditorUpdateTextCommand());
    addSubcommand(_EditorAddImageCommand());
    addSubcommand(_EditorAddIconCommand());
    addSubcommand(_EditorAddMagnifierCommand());
    addSubcommand(_EditorDeleteOverlayCommand());
    addSubcommand(_EditorSelectOverlayCommand());
    addSubcommand(_EditorMoveOverlayCommand());
    addSubcommand(_EditorListOverlaysCommand());
    addSubcommand(_EditorApplyPresetCommand());
    addSubcommand(_EditorSetDisplayTypeCommand());
    addSubcommand(_EditorExportCommand());
    addSubcommand(_EditorExportAllCommand());
    addSubcommand(_EditorListFontsCommand());
    addSubcommand(_EditorListIconsCommand());
    addSubcommand(_EditorUploadImageCommand());
    addSubcommand(_EditorUndoCommand());
    addSubcommand(_EditorRedoCommand());
    addSubcommand(_EditorSetMeshGradientCommand());
    addSubcommand(_EditorSetDoodleCommand());
    addSubcommand(_EditorSetGridCommand());
    addSubcommand(_EditorUpdateIconCommand());
    addSubcommand(_EditorUpdateMagnifierCommand());
    addSubcommand(_EditorCopyOverlayCommand());
    addSubcommand(_EditorPasteOverlayCommand());
    addSubcommand(_EditorBringForwardCommand());
    addSubcommand(_EditorSendBackwardCommand());
    addSubcommand(_EditorSaveDesignCommand());
    addSubcommand(_EditorLoadDesignCommand());
    addSubcommand(_EditorSetOrientationCommand());
    addSubcommand(_EditorSetGradientCommand());
    addSubcommand(_EditorSetTransparentCommand());
    addSubcommand(_EditorSetImagePositionCommand());
    addSubcommand(_EditorUpdateImageCommand());
  }
}

// ─── Sub-commands ────────────────────────────────────────────────────────────

class _EditorStateCommand extends Command<int> {
  @override
  String get name => 'state';
  @override
  String get description => 'Get the current design state';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(EditorAction.state.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetBackgroundCommand extends Command<int> {
  @override
  String get name => 'set-background';
  @override
  String get description => 'Set background color (hex)';

  _EditorSetBackgroundCommand() {
    argParser.addOption('color', abbr: 'c', help: 'Hex color, e.g. "#FF5733"');
  }

  @override
  Future<int> run() async {
    final color =
        argResults?['color'] as String? ?? argResults?.rest.firstOrNull;
    if (color == null) {
      usageException('Provide a color: --color "#FF5733" or just "#FF5733"');
    }
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.setBackground.path, {'color': color});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetFrameCommand extends Command<int> {
  @override
  String get name => 'set-frame';
  @override
  String get description => 'Set device frame (e.g. "iPhone 16")';

  _EditorSetFrameCommand() {
    argParser.addOption('device', abbr: 'd', help: 'Device name');
  }

  @override
  Future<int> run() async {
    final device =
        argResults?['device'] as String? ?? argResults?.rest.firstOrNull;
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.setFrame.path, {'device': device});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorListDevicesCommand extends Command<int> {
  @override
  String get name => 'list-devices';
  @override
  String get description => 'List available device frames';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(EditorAction.listDevices.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetPaddingCommand extends Command<int> {
  @override
  String get name => 'set-padding';
  @override
  String get description => 'Set padding around the screenshot';

  _EditorSetPaddingCommand() {
    argParser.addOption('value', abbr: 'v', help: 'Padding value (number)');
  }

  @override
  Future<int> run() async {
    final value = double.tryParse(
        argResults?['value'] as String? ?? argResults?.rest.firstOrNull ?? '');
    if (value == null) usageException('Provide a number: --value 200');
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.setPadding.path, {'padding': value});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetCornerRadiusCommand extends Command<int> {
  @override
  String get name => 'set-corner-radius';
  @override
  String get description => 'Set corner radius';

  _EditorSetCornerRadiusCommand() {
    argParser.addOption('value', abbr: 'v', help: 'Radius value');
  }

  @override
  Future<int> run() async {
    final value = double.tryParse(
        argResults?['value'] as String? ?? argResults?.rest.firstOrNull ?? '');
    if (value == null) usageException('Provide a number: --value 20');
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.setCornerRadius.path, {'radius': value});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetRotationCommand extends Command<int> {
  @override
  String get name => 'set-rotation';
  @override
  String get description => 'Set 3D frame rotation';

  _EditorSetRotationCommand() {
    argParser.addOption('x', help: 'X rotation');
    argParser.addOption('y', help: 'Y rotation');
    argParser.addOption('z', help: 'Z rotation');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['z'] != null) body['z'] = double.parse(argResults!['z']);
    if (body.isEmpty) usageException('Provide at least one: --x, --y, --z');
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.setRotation.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetImageCommand extends Command<int> {
  @override
  String get name => 'set-image';
  @override
  String get description => 'Set the screenshot image file';

  _EditorSetImageCommand() {
    argParser.addOption('file', abbr: 'f', help: 'Path to image');
  }

  @override
  Future<int> run() async {
    final file = argResults?['file'] as String? ?? argResults?.rest.firstOrNull;
    if (file == null) usageException('Provide: --file /path/to/image.png');
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.setImage.path, {'file': file});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorAddTextCommand extends Command<int> {
  @override
  String get name => 'add-text';
  @override
  String get description => 'Add a text overlay';

  _EditorAddTextCommand() {
    argParser.addOption('text',
        abbr: 't', help: 'Text content', defaultsTo: 'New Text');
    argParser.addOption('font', help: 'Google Font name');
    argParser.addOption('size', help: 'Font size', defaultsTo: '40');
    argParser.addOption('color', abbr: 'c', help: 'Text color (hex)');
    argParser.addOption('x', help: 'X position');
    argParser.addOption('y', help: 'Y position');
    argParser.addOption('width',
        abbr: 'w', help: 'Text box width (needed for alignment)');
    argParser.addOption('align',
        help: 'Text alignment: left, center, right', defaultsTo: 'center');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{
      'text': (argResults!['text'] as String).replaceAll(r'\n', '\n'),
      'fontSize': double.parse(argResults!['size']),
    };
    if (argResults?['font'] != null) body['font'] = argResults!['font'];
    if (argResults?['color'] != null) body['color'] = argResults!['color'];
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['width'] != null)
      body['width'] = double.parse(argResults!['width']);
    if (argResults?['align'] != null) body['align'] = argResults!['align'];

    final client = await AppClient.discover();
    final result = await client.post(EditorAction.addText.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorUpdateTextCommand extends Command<int> {
  @override
  String get name => 'update-text';
  @override
  String get description => 'Update an existing text overlay';

  _EditorUpdateTextCommand() {
    argParser.addOption('id', help: 'Overlay ID (required)', mandatory: true);
    argParser.addOption('text', abbr: 't', help: 'New text');
    argParser.addOption('font', help: 'Google Font name');
    argParser.addOption('size', help: 'Font size');
    argParser.addOption('color', abbr: 'c', help: 'Color (hex)');
    argParser.addOption('width', abbr: 'w', help: 'Text box width');
    argParser.addOption('align', help: 'Text alignment: left, center, right');
    argParser.addOption('x', help: 'X position');
    argParser.addOption('y', help: 'Y position');
    argParser.addOption('scale', help: 'Scale factor');
    argParser.addOption('rotation', help: 'Rotation degrees');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{'id': argResults!['id']};
    if (argResults?['text'] != null)
      body['text'] = (argResults!['text'] as String).replaceAll(r'\n', '\n');
    if (argResults?['font'] != null) body['font'] = argResults!['font'];
    if (argResults?['size'] != null)
      body['fontSize'] = double.parse(argResults!['size']);
    if (argResults?['color'] != null) body['color'] = argResults!['color'];
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['scale'] != null)
      body['scale'] = double.parse(argResults!['scale']);
    if (argResults?['rotation'] != null)
      body['rotation'] = double.parse(argResults!['rotation']);
    if (argResults?['width'] != null)
      body['width'] = double.parse(argResults!['width']);
    if (argResults?['align'] != null) body['align'] = argResults!['align'];

    final client = await AppClient.discover();
    final result = await client.post(EditorAction.updateText.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorAddImageCommand extends Command<int> {
  @override
  String get name => 'add-image';
  @override
  String get description => 'Add an image overlay';

  _EditorAddImageCommand() {
    argParser.addOption('file',
        abbr: 'f', help: 'Path to image', mandatory: true);
    argParser.addOption('x', help: 'X position');
    argParser.addOption('y', help: 'Y position');
    argParser.addOption('width', help: 'Width');
    argParser.addOption('height', help: 'Height');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{'file': argResults!['file']};
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['width'] != null)
      body['width'] = double.parse(argResults!['width']);
    if (argResults?['height'] != null)
      body['height'] = double.parse(argResults!['height']);

    final client = await AppClient.discover();
    final result = await client.post(EditorAction.addImage.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorDeleteOverlayCommand extends Command<int> {
  @override
  String get name => 'delete-overlay';
  @override
  String get description => 'Delete an overlay by ID (or the selected one)';

  _EditorDeleteOverlayCommand() {
    argParser.addOption('id', help: 'Overlay ID');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['id'] != null) body['id'] = argResults!['id'];
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.deleteOverlay.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSelectOverlayCommand extends Command<int> {
  @override
  String get name => 'select-overlay';
  @override
  String get description => 'Select an overlay by ID';

  _EditorSelectOverlayCommand() {
    argParser.addOption('id', help: 'Overlay ID');
  }

  @override
  Future<int> run() async {
    final id = argResults?['id'] as String? ?? argResults?.rest.firstOrNull;
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.selectOverlay.path, {'id': id});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorMoveOverlayCommand extends Command<int> {
  @override
  String get name => 'move-overlay';
  @override
  String get description => 'Move selected overlay by delta';

  _EditorMoveOverlayCommand() {
    argParser.addOption('dx', help: 'X delta', defaultsTo: '0');
    argParser.addOption('dy', help: 'Y delta', defaultsTo: '0');
  }

  @override
  Future<int> run() async {
    final dx = double.parse(argResults!['dx']);
    final dy = double.parse(argResults!['dy']);
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.moveOverlay.path, {'dx': dx, 'dy': dy});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorListOverlaysCommand extends Command<int> {
  @override
  String get name => 'list-overlays';
  @override
  String get description => 'List all overlays in the current design';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(EditorAction.listOverlays.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorUndoCommand extends Command<int> {
  @override
  String get name => 'undo';
  @override
  String get description => 'Undo the last action';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.undo.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorRedoCommand extends Command<int> {
  @override
  String get name => 'redo';
  @override
  String get description => 'Redo the last undone action';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.redo.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorApplyPresetCommand extends Command<int> {
  @override
  String get name => 'apply-preset';
  @override
  String get description => 'Apply a preset template to the current design';

  _EditorApplyPresetCommand() {
    argParser.addOption('id',
        help: 'Preset ID (use "preset list" to see available)',
        mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client
        .post(EditorAction.applyPreset.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorAddIconCommand extends Command<int> {
  @override
  String get name => 'add-icon';
  @override
  String get description => 'Add an icon overlay';

  _EditorAddIconCommand() {
    argParser.addOption('codePoint',
        help: 'Icon Unicode code point (int)', mandatory: true);
    argParser.addOption('fontFamily',
        help: 'Font family', defaultsTo: 'MaterialIcons');
    argParser.addOption('fontPackage', help: 'Font package', defaultsTo: '');
    argParser.addOption('color', abbr: 'c', help: 'Icon color (hex)');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{
      'codePoint': int.parse(argResults!['codePoint']),
      'fontFamily': argResults!['fontFamily'],
      'fontPackage': argResults!['fontPackage'],
    };
    if (argResults?['color'] != null) body['color'] = argResults!['color'];
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.addIcon.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorAddMagnifierCommand extends Command<int> {
  @override
  String get name => 'add-magnifier';
  @override
  String get description => 'Add a magnifier overlay';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.addMagnifier.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetDisplayTypeCommand extends Command<int> {
  @override
  String get name => 'set-display-type';
  @override
  String get description => 'Change screenshot display type (dimensions)';

  _EditorSetDisplayTypeCommand() {
    argParser.addOption('type',
        abbr: 't',
        help: 'Display type (e.g. APP_IPHONE_69, APP_IPAD_PRO_3GEN_129)',
        mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(
        EditorAction.setDisplayType.path, {'displayType': argResults!['type']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorExportCommand extends Command<int> {
  @override
  String get name => 'export';
  @override
  String get description => 'Export current design as PNG screenshot';

  _EditorExportCommand() {
    argParser.addOption('path',
        abbr: 'p', help: 'Output file path (default: temp dir)');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['path'] != null) body['path'] = argResults!['path'];
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.export_.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorExportAllCommand extends Command<int> {
  @override
  String get name => 'export-all';
  @override
  String get description => 'Export all multi-designs as PNG screenshots';

  _EditorExportAllCommand() {
    argParser.addOption('dir',
        abbr: 'd', help: 'Output directory (default: temp dir)');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['dir'] != null) body['dir'] = argResults!['dir'];
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.exportAll.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorListFontsCommand extends Command<int> {
  @override
  String get name => 'list-fonts';
  @override
  String get description =>
      'List available Google Fonts (with optional search)';

  _EditorListFontsCommand() {
    argParser.addOption('query',
        abbr: 'q', help: 'Search fonts by name (case-insensitive)');
    argParser.addOption('limit',
        abbr: 'l', help: 'Max fonts to return (default 50)', defaultsTo: '50');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['query'] != null) body['query'] = argResults!['query'];
    body['limit'] = int.tryParse(argResults?['limit'] ?? '50') ?? 50;
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.listFonts.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorListIconsCommand extends Command<int> {
  @override
  String get name => 'list-icons';
  @override
  String get description =>
      'List available icons (Material Symbols + SF Symbols)';

  _EditorListIconsCommand() {
    argParser.addOption('query', abbr: 'q', help: 'Search icons by name');
    argParser.addOption('style',
        abbr: 's', help: 'Filter: material or sf', allowed: ['material', 'sf']);
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['query'] != null) body['query'] = argResults!['query'];
    if (argResults?['style'] != null) body['style'] = argResults!['style'];
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.listIcons.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorUploadImageCommand extends Command<int> {
  @override
  String get name => 'upload-image';
  @override
  String get description =>
      'Upload a screenshot image (sandbox-safe base64 transfer)';

  _EditorUploadImageCommand() {
    argParser.addOption('file',
        abbr: 'f', help: 'Path to image file', mandatory: true);
  }

  @override
  Future<int> run() async {
    final filePath = argResults!['file'] as String;
    final file = File(filePath);
    if (!file.existsSync()) {
      stderr.writeln('❌ File not found: $filePath');
      return 1;
    }
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.setImageBase64.path, {
      'data': base64Data,
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

// ─── New subcommands ─────────────────────────────────────────────────────────

class _EditorSetMeshGradientCommand extends Command<int> {
  @override
  String get name => 'set-mesh-gradient';
  @override
  String get description => 'Set mesh gradient background (JSON points)';

  _EditorSetMeshGradientCommand() {
    argParser.addOption('json', help: 'JSON mesh gradient settings');
    argParser.addFlag('clear', help: 'Remove mesh gradient');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    Map<String, dynamic> result;
    if (argResults!['clear'] == true) {
      result = await client.post(EditorAction.setMeshGradient.path, {});
    } else {
      final jsonStr = argResults?['json'] as String?;
      if (jsonStr == null) usageException('Provide --json or --clear');
      final mesh = jsonDecode(jsonStr);
      result =
          await client.post(EditorAction.setMeshGradient.path, {'mesh': mesh});
    }
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetDoodleCommand extends Command<int> {
  @override
  String get name => 'set-doodle';
  @override
  String get description => 'Set doodle pattern background';

  _EditorSetDoodleCommand() {
    argParser.addFlag('enabled',
        defaultsTo: true, help: 'Enable/disable doodle');
    argParser.addOption('icon-source',
        help: 'sfSymbols, materialSymbols, or emoji', defaultsTo: '0');
    argParser.addOption('icon-size', help: 'Icon size', defaultsTo: '40');
    argParser.addOption('spacing', help: 'Gap between icons', defaultsTo: '60');
    argParser.addOption('opacity',
        help: 'Icon opacity (0-1)', defaultsTo: '0.08');
    argParser.addOption('rotation', help: 'Rotation degrees', defaultsTo: '0');
    argParser.addOption('color', help: 'Icon color (hex)');
    argParser.addFlag('clear', help: 'Remove doodle');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    if (argResults!['clear'] == true) {
      final result =
          await client.post(EditorAction.setDoodle.path, {'enabled': false});
      Output.print(result, json: Output.isJson(globalResults));
      client.close();
      return result['ok'] == true ? 0 : 1;
    }
    final body = <String, dynamic>{
      'enabled': argResults!['enabled'],
      'iconSource': int.tryParse(argResults!['icon-source']) ?? 0,
      'iconSize': double.parse(argResults!['icon-size']),
      'spacing': double.parse(argResults!['spacing']),
      'iconOpacity': double.parse(argResults!['opacity']),
      'rotation': double.parse(argResults!['rotation']),
    };
    if (argResults?['color'] != null)
      body['iconColor'] = int.tryParse(argResults!['color']) ?? 0xFFFFFFFF;
    final result = await client.post(EditorAction.setDoodle.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetGridCommand extends Command<int> {
  @override
  String get name => 'set-grid';
  @override
  String get description => 'Configure alignment grid/guidelines';

  _EditorSetGridCommand() {
    argParser.addFlag('show', help: 'Show grid lines');
    argParser.addFlag('snap', help: 'Enable snap-to-grid');
    argParser.addFlag('dots', help: 'Use dot grid style');
    argParser.addFlag('center', help: 'Show center lines');
    argParser.addOption('size', help: 'Grid cell size', defaultsTo: '50');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{
      'showGrid': argResults!['show'],
      'snapToGrid': argResults!['snap'],
      'showDotGrid': argResults!['dots'],
      'showCenterLines': argResults!['center'],
      'gridSize': double.parse(argResults!['size']),
    };
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.setGrid.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorUpdateIconCommand extends Command<int> {
  @override
  String get name => 'update-icon';
  @override
  String get description => 'Update an existing icon overlay';

  _EditorUpdateIconCommand() {
    argParser.addOption('id', help: 'Icon overlay ID', mandatory: true);
    argParser.addOption('x', help: 'X position');
    argParser.addOption('y', help: 'Y position');
    argParser.addOption('size', help: 'Icon size');
    argParser.addOption('color', help: 'Color (hex)');
    argParser.addOption('rotation', help: 'Rotation');
    argParser.addOption('opacity', help: 'Opacity');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{'id': argResults!['id']};
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['size'] != null)
      body['size'] = double.parse(argResults!['size']);
    if (argResults?['color'] != null) body['color'] = argResults!['color'];
    if (argResults?['rotation'] != null)
      body['rotation'] = double.parse(argResults!['rotation']);
    if (argResults?['opacity'] != null)
      body['opacity'] = double.parse(argResults!['opacity']);
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.updateIcon.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorUpdateMagnifierCommand extends Command<int> {
  @override
  String get name => 'update-magnifier';
  @override
  String get description => 'Update an existing magnifier overlay';

  _EditorUpdateMagnifierCommand() {
    argParser.addOption('id', help: 'Magnifier overlay ID', mandatory: true);
    argParser.addOption('x', help: 'X position');
    argParser.addOption('y', help: 'Y position');
    argParser.addOption('width', help: 'Width');
    argParser.addOption('height', help: 'Height');
    argParser.addOption('zoom', help: 'Zoom level');
    argParser.addOption('corner-radius', help: 'Corner radius');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{'id': argResults!['id']};
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['width'] != null)
      body['width'] = double.parse(argResults!['width']);
    if (argResults?['height'] != null)
      body['height'] = double.parse(argResults!['height']);
    if (argResults?['zoom'] != null)
      body['zoomLevel'] = double.parse(argResults!['zoom']);
    if (argResults?['corner-radius'] != null)
      body['cornerRadius'] = double.parse(argResults!['corner-radius']);
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.updateMagnifier.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorCopyOverlayCommand extends Command<int> {
  @override
  String get name => 'copy-overlay';
  @override
  String get description => 'Copy the selected overlay to clipboard';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.copyOverlay.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorPasteOverlayCommand extends Command<int> {
  @override
  String get name => 'paste-overlay';
  @override
  String get description => 'Paste overlay from clipboard';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.pasteOverlay.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorBringForwardCommand extends Command<int> {
  @override
  String get name => 'bring-forward';
  @override
  String get description => 'Bring selected overlay one layer forward';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.bringForward.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSendBackwardCommand extends Command<int> {
  @override
  String get name => 'send-backward';
  @override
  String get description => 'Send selected overlay one layer backward';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.sendBackward.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSaveDesignCommand extends Command<int> {
  @override
  String get name => 'save-design';
  @override
  String get description => 'Save current design to library';

  _EditorSaveDesignCommand() {
    argParser.addOption('name', abbr: 'n', help: 'Design name');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['name'] != null) body['name'] = argResults!['name'];
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.saveDesign.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorLoadDesignCommand extends Command<int> {
  @override
  String get name => 'load-design';
  @override
  String get description => 'Load a saved design into the editor';

  _EditorLoadDesignCommand() {
    argParser.addOption('id', help: 'Design ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client
        .post(EditorAction.loadDesign.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetOrientationCommand extends Command<int> {
  @override
  String get name => 'set-orientation';
  @override
  String get description => 'Toggle orientation (portrait/landscape)';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.setOrientation.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetGradientCommand extends Command<int> {
  @override
  String get name => 'set-gradient';
  @override
  String get description => 'Set gradient background (linear/radial/sweep)';

  _EditorSetGradientCommand() {
    argParser.addOption('json', help: 'Gradient JSON (type, colors, stops)');
    argParser.addFlag('clear', help: 'Remove gradient');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    Map<String, dynamic> result;
    if (argResults!['clear'] == true) {
      result = await client.post(EditorAction.setGradient.path, {});
    } else {
      final jsonStr = argResults?['json'] as String?;
      if (jsonStr == null) usageException('Provide --json or --clear');
      final gradient = jsonDecode(jsonStr);
      result = await client
          .post(EditorAction.setGradient.path, {'gradient': gradient});
    }
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetTransparentCommand extends Command<int> {
  @override
  String get name => 'set-transparent';
  @override
  String get description => 'Toggle transparent background';

  _EditorSetTransparentCommand() {
    argParser.addFlag('value',
        defaultsTo: true, help: 'Transparent (true/false)');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.setTransparent.path,
        {'transparent': argResults!['value']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorSetImagePositionCommand extends Command<int> {
  @override
  String get name => 'set-image-position';
  @override
  String get description => 'Set screenshot image position offset';

  _EditorSetImagePositionCommand() {
    argParser.addOption('x', help: 'X offset', defaultsTo: '0');
    argParser.addOption('y', help: 'Y offset', defaultsTo: '0');
  }

  @override
  Future<int> run() async {
    final x = double.parse(argResults!['x']);
    final y = double.parse(argResults!['y']);
    final client = await AppClient.discover();
    final result =
        await client.post(EditorAction.setImagePosition.path, {'x': x, 'y': y});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _EditorUpdateImageCommand extends Command<int> {
  @override
  String get name => 'update-image';
  @override
  String get description => 'Update an existing image overlay';

  _EditorUpdateImageCommand() {
    argParser.addOption('id', help: 'Image overlay ID', mandatory: true);
    argParser.addOption('x', help: 'X position');
    argParser.addOption('y', help: 'Y position');
    argParser.addOption('width', help: 'Width');
    argParser.addOption('height', help: 'Height');
    argParser.addOption('scale', help: 'Scale factor');
    argParser.addOption('rotation', help: 'Rotation');
    argParser.addOption('opacity', help: 'Opacity');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{'id': argResults!['id']};
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['width'] != null)
      body['width'] = double.parse(argResults!['width']);
    if (argResults?['height'] != null)
      body['height'] = double.parse(argResults!['height']);
    if (argResults?['scale'] != null)
      body['scale'] = double.parse(argResults!['scale']);
    if (argResults?['rotation'] != null)
      body['rotation'] = double.parse(argResults!['rotation']);
    if (argResults?['opacity'] != null)
      body['opacity'] = double.parse(argResults!['opacity']);
    final client = await AppClient.discover();
    final result = await client.post(EditorAction.updateImage.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
