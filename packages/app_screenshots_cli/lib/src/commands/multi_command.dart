import 'dart:convert';
import 'dart:io';

import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import '../app_client.dart';
import '../output.dart';
import 'package:args/command_runner.dart';

/// `appshots multi` — subcommands for multi-design management.
class MultiCommand extends Command<int> {
  @override
  String get name => 'multi';

  @override
  String get description => 'Manage multi-screenshot designs';

  MultiCommand() {
    addSubcommand(_MultiOpenCommand());
    addSubcommand(_MultiStateCommand());
    addSubcommand(_MultiSwitchCommand());
    addSubcommand(_MultiAddCommand());
    addSubcommand(_MultiRemoveCommand());
    addSubcommand(_MultiDuplicateCommand());
    addSubcommand(_MultiReorderCommand());
    addSubcommand(_MultiApplyPresetCommand());
    addSubcommand(_MultiBatchCommand());
    addSubcommand(_MultiSetImageCommand());
    addSubcommand(_MultiSaveDesignCommand());
  }
}

class _MultiOpenCommand extends Command<int> {
  @override
  String get name => 'open';
  @override
  String get description =>
      'Open the multi-screenshot editor for a device type';

  _MultiOpenCommand() {
    argParser.addOption(
      'display-type',
      abbr: 'd',
      help: 'ASC display type (e.g. APP_IPHONE_67, APP_IPAD_PRO_3GEN_129)',
      defaultsTo: 'APP_IPHONE_67',
    );
  }

  @override
  Future<int> run() async {
    final displayType = argResults!['display-type'] as String;
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.open.path, {
      'displayType': displayType,
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiStateCommand extends Command<int> {
  @override
  String get name => 'state';
  @override
  String get description => 'Get multi-editor state with all designs';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(MultiAction.state.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiSwitchCommand extends Command<int> {
  @override
  String get name => 'switch';
  @override
  String get description => 'Switch active design by index';

  _MultiSwitchCommand() {
    argParser.addOption('index',
        abbr: 'i', help: 'Design index (0-based)', mandatory: true);
  }

  @override
  Future<int> run() async {
    final index = int.parse(argResults!['index']);
    final client = await AppClient.discover();
    final result =
        await client.post(MultiAction.switchDesign.path, {'index': index});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiAddCommand extends Command<int> {
  @override
  String get name => 'add';
  @override
  String get description => 'Add a new design slot';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.addDesign.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiRemoveCommand extends Command<int> {
  @override
  String get name => 'remove';
  @override
  String get description => 'Remove a design (default: active)';

  _MultiRemoveCommand() {
    argParser.addOption('index', abbr: 'i', help: 'Design index');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    final index = argResults?['index'] as String?;
    if (index != null) body['index'] = int.parse(index);
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.removeDesign.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiDuplicateCommand extends Command<int> {
  @override
  String get name => 'duplicate';
  @override
  String get description => 'Duplicate a design';

  _MultiDuplicateCommand() {
    argParser.addOption('index', abbr: 'i', help: 'Design index');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    final index = argResults?['index'] as String?;
    if (index != null) body['index'] = int.parse(index);
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.duplicateDesign.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiReorderCommand extends Command<int> {
  @override
  String get name => 'reorder';
  @override
  String get description => 'Reorder designs';

  _MultiReorderCommand() {
    argParser.addOption('from', help: 'Source index', mandatory: true);
    argParser.addOption('to', help: 'Target index', mandatory: true);
  }

  @override
  Future<int> run() async {
    final from = int.parse(argResults!['from']);
    final to = int.parse(argResults!['to']);
    final client = await AppClient.discover();
    final result =
        await client.post(MultiAction.reorder.path, {'from': from, 'to': to});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiApplyPresetCommand extends Command<int> {
  @override
  String get name => 'apply-preset';
  @override
  String get description => 'Apply preset to all designs';

  _MultiApplyPresetCommand() {
    argParser.addOption('id', help: 'Preset ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client
        .post(MultiAction.applyPreset.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiBatchCommand extends Command<int> {
  @override
  String get name => 'batch';
  @override
  String get description => 'Apply same change to all designs';

  _MultiBatchCommand() {
    argParser.addOption('action',
        abbr: 'a',
        help: 'Batch action (set-background, set-padding, set-corner-radius)',
        mandatory: true);
    argParser.addOption('color', help: 'Color for set-background (hex)');
    argParser.addOption('value',
        abbr: 'v', help: 'Value for set-padding or set-corner-radius');
  }

  @override
  Future<int> run() async {
    final action = argResults!['action'] as String;
    final body = <String, dynamic>{'action': action};
    final color = argResults?['color'] as String?;
    if (color != null) body['color'] = color;
    final value = argResults?['value'] as String?;
    if (value != null) {
      body[action == 'set-padding' ? 'padding' : 'radius'] =
          double.parse(value);
    }
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.batch.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiSetImageCommand extends Command<int> {
  @override
  String get name => 'set-image';
  @override
  String get description => 'Upload/set image for a specific design slot';

  _MultiSetImageCommand() {
    argParser.addOption('file',
        abbr: 'f', help: 'Path to image file', mandatory: true);
    argParser.addOption('index',
        abbr: 'i', help: 'Design index (default: active)');
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
    final body = <String, dynamic>{'data': base64Data};
    final index = argResults?['index'] as String?;
    if (index != null) body['index'] = int.parse(index);
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.setImage.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _MultiSaveDesignCommand extends Command<int> {
  @override
  String get name => 'save-design';
  @override
  String get description => 'Save multi-design project to library';

  _MultiSaveDesignCommand() {
    argParser.addOption('name', abbr: 'n', help: 'Project name');
    argParser.addFlag('override',
        help: 'Override existing saved design instead of creating a new one',
        defaultsTo: false);
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{};
    if (argResults?['name'] != null) body['name'] = argResults!['name'];
    if (argResults!['override'] == true) body['override'] = true;
    final client = await AppClient.discover();
    final result = await client.post(MultiAction.saveDesign.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
