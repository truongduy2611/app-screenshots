import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';

class CollaborationCommand extends Command<int> {
  @override
  String get name => 'collaboration';

  @override
  String get description => 'Share and save iCloud collaboration documents';

  CollaborationCommand() {
    addSubcommand(_CollaborationShareCommand());
    addSubcommand(_CollaborationSaveCommand());
  }
}

class _CollaborationShareCommand extends Command<int> {
  @override
  String get name => 'share';

  @override
  String get description => 'Present the iCloud collaboration share sheet';

  _CollaborationShareCommand() {
    argParser
      ..addOption('file', abbr: 'f', help: '.appshots file', mandatory: true)
      ..addOption('name', help: 'Shared file name override');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final result = await client.post(
      CollaborationAction.share.path,
      {
        'file': argResults!['file'],
        if (argResults!['name'] != null) 'fileName': argResults!['name'],
      },
      null,
    );
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _CollaborationSaveCommand extends Command<int> {
  @override
  String get name => 'save';

  @override
  String get description => 'Save a working copy back to its opened document';

  _CollaborationSaveCommand() {
    argParser
      ..addOption('original',
          help: 'Original local document path', mandatory: true)
      ..addOption('working', help: 'Edited working-copy path', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final result = await client.post(CollaborationAction.save.path, {
      'localPath': argResults!['original'],
      'workingPath': argResults!['working'],
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
