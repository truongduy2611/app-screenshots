import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';
import '../upload_payload.dart';
import 'jobs_command.dart';

class AscCommand extends Command<int> {
  @override
  String get name => 'asc';

  @override
  String get description => 'Upload screenshots to App Store Connect';

  AscCommand() {
    addSubcommand(_AscAppsCommand());
    addSubcommand(_AscCustomProductPagesCommand());
    addSubcommand(_AscUploadCommand());
  }
}

class _AscAppsCommand extends Command<int> {
  @override
  String get name => 'apps';

  @override
  String get description => 'List accessible App Store Connect apps';

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final result = await client.get(AscAction.apps.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _AscCustomProductPagesCommand extends Command<int> {
  @override
  String get name => 'custom-product-pages';

  @override
  String get description => 'List Custom Product Pages for an app';

  _AscCustomProductPagesCommand() {
    argParser.addOption('app-id',
        help: 'App Store Connect app ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final result = await client.post(
      AscAction.customProductPages.path,
      {'appId': argResults!['app-id']},
    );
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _AscUploadCommand extends Command<int> {
  @override
  String get name => 'upload';

  @override
  String get description => 'Upload locale folders to an ASC version or CPP';

  _AscUploadCommand() {
    argParser
      ..addOption('app-id', help: 'App Store Connect app ID', mandatory: true)
      ..addOption(
        'source',
        abbr: 's',
        help: 'Directory containing locale subdirectories',
        mandatory: true,
      )
      ..addOption(
        'display-type',
        abbr: 'd',
        help: 'ASC screenshot display type',
        defaultsTo: 'APP_IPHONE_67',
      )
      ..addOption('platform', help: 'ASC platform, such as IOS or MAC_OS')
      ..addOption('custom-product-page-id', help: 'Target CPP ID')
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
      'appId': argResults!['app-id'],
      'screenshots': screenshots,
      'displayType': argResults!['display-type'],
      'deleteExisting': argResults!['delete-existing'],
      if (argResults!['platform'] != null) 'platform': argResults!['platform'],
      if (argResults!['custom-product-page-id'] != null)
        'customProductPageId': argResults!['custom-product-page-id'],
      if (locales.isNotEmpty) 'locales': locales,
    };
    var result = await client.post(
      AscAction.upload.path,
      body,
      const Duration(minutes: 5),
    );
    if (argResults!['wait'] == true) result = await waitForJob(client, result);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
