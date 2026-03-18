import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';
import '../app_client.dart';
import '../output.dart';

/// `appshots status` — check if the app is running and connected.
class StatusCommand extends Command<int> {
  @override
  String get name => 'status';

  @override
  String get description => 'Check connection to the running App Screenshots app';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(ApiRoute.status.prefix);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
