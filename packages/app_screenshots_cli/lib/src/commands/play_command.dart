import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';
import '../upload_payload.dart';
import 'jobs_command.dart';

class PlayCommand extends Command<int> {
  @override
  String get name => 'play';

  @override
  String get description =>
      'Upload screenshots to the Google Play main listing';

  PlayCommand() {
    addSubcommand(_PlayUploadCommand());
  }
}

class _PlayUploadCommand extends Command<int> {
  @override
  String get name => 'upload';

  @override
  String get description => 'Upload locale folders to Google Play';

  _PlayUploadCommand() {
    argParser
      ..addOption('package', help: 'Android package name', mandatory: true)
      ..addOption(
        'source',
        abbr: 's',
        help: 'Directory containing locale subdirectories',
        mandatory: true,
      )
      ..addOption(
        'image-type',
        help: 'Google Play screenshot image type',
        defaultsTo: 'phoneScreenshots',
        allowed: const [
          'phoneScreenshots',
          'sevenInchScreenshots',
          'tenInchScreenshots',
          'tvScreenshots',
          'wearScreenshots',
        ],
      )
      ..addMultiOption(
        'locale',
        abbr: 'l',
        help: 'Locales to upload; defaults to every locale folder',
        splitCommas: true,
      )
      ..addFlag(
        'delete-existing',
        help: 'Replace existing screenshots',
        defaultsTo: true,
      )
      ..addFlag(
        'draft',
        help: 'Keep changes from being sent for review automatically',
        defaultsTo: true,
      )
      ..addFlag(
        'wait',
        help: 'Wait for the background upload to finish',
        defaultsTo: true,
      );
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final locales = argResults!['locale'] as List<String>;
    final screenshots = await encodeLocaleScreenshots(
      argResults!['source'] as String,
      selectedLocales: locales,
    );
    if (screenshots.isEmpty) {
      Output.print({
        'ok': false,
        'error': 'No screenshots found in the selected locale folders',
      }, json: Output.isJson(globalResults));
      client.close();
      return 1;
    }
    final body = <String, dynamic>{
      'packageName': argResults!['package'],
      'screenshots': screenshots,
      'imageType': argResults!['image-type'],
      'deleteExisting': argResults!['delete-existing'],
      'changesNotSentForReview': argResults!['draft'],
      if (locales.isNotEmpty) 'locales': locales,
    };
    var result = await client.post(
      PlayAction.upload.path,
      body,
      const Duration(minutes: 5),
    );
    if (argResults!['wait'] == true) result = await waitForJob(client, result);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
