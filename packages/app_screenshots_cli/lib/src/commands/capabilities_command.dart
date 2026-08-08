import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';

class CapabilitiesCommand extends Command<int> {
  @override
  String get name => 'capabilities';

  @override
  String get description => 'Show local API and publishing capabilities';

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final result = await client.get(ApiRoute.capabilities.prefix);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
