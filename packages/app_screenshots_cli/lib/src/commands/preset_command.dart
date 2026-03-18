import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';
import '../app_client.dart';
import '../output.dart';

/// `appshots preset` — list and inspect design presets.
class PresetCommand extends Command<int> {
  @override
  String get name => 'preset';

  @override
  String get description => 'Browse and inspect design presets';

  PresetCommand() {
    addSubcommand(_PresetListCommand());
    addSubcommand(_PresetShowCommand());
  }
}

class _PresetListCommand extends Command<int> {
  @override
  String get name => 'list';
  @override
  String get description => 'List all available presets';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(PresetAction.list.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _PresetShowCommand extends Command<int> {
  @override
  String get name => 'show';
  @override
  String get description => 'Show details of a specific preset';

  _PresetShowCommand() {
    argParser.addOption('id', help: 'Preset ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result =
        await client.post(PresetAction.show.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
