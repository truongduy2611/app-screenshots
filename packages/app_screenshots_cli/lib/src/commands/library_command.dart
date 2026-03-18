import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';
import '../app_client.dart';
import '../output.dart';

/// `appshots library` — manage saved designs and folders.
class LibraryCommand extends Command<int> {
  @override
  String get name => 'library';

  @override
  String get description => 'Manage saved designs and folders';

  LibraryCommand() {
    addSubcommand(_LibraryListCommand());
    addSubcommand(_LibraryFoldersCommand());
    addSubcommand(_LibraryGetCommand());
    addSubcommand(_LibraryDeleteCommand());
    addSubcommand(_LibraryRenameCommand());
    addSubcommand(_LibraryCreateFolderCommand());
    addSubcommand(_LibraryImportCommand());
    addSubcommand(_LibraryExportCommand());
    addSubcommand(_LibraryMoveCommand());
    addSubcommand(_LibrarySearchCommand());
    addSubcommand(_LibraryDeleteFolderCommand());
  }
}

class _LibraryListCommand extends Command<int> {
  @override String get name => 'list';
  @override String get description => 'List all saved designs';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(LibraryAction.list.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryFoldersCommand extends Command<int> {
  @override String get name => 'folders';
  @override String get description => 'List all folders';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(LibraryAction.folders.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryGetCommand extends Command<int> {
  @override String get name => 'get';
  @override String get description => 'Get a design by ID';

  _LibraryGetCommand() {
    argParser.addOption('id', help: 'Design ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.get.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryDeleteCommand extends Command<int> {
  @override String get name => 'delete';
  @override String get description => 'Delete a design by ID';

  _LibraryDeleteCommand() {
    argParser.addOption('id', help: 'Design ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.delete.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryRenameCommand extends Command<int> {
  @override String get name => 'rename';
  @override String get description => 'Rename a design';

  _LibraryRenameCommand() {
    argParser.addOption('id', help: 'Design ID', mandatory: true);
    argParser.addOption('name', abbr: 'n', help: 'New name', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.rename.path, {
      'id': argResults!['id'],
      'name': argResults!['name'],
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryCreateFolderCommand extends Command<int> {
  @override String get name => 'create-folder';
  @override String get description => 'Create a new folder';

  _LibraryCreateFolderCommand() {
    argParser.addOption('name', abbr: 'n', help: 'Folder name', mandatory: true);
    argParser.addOption('parent', help: 'Parent folder ID');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{'name': argResults!['name']};
    if (argResults?['parent'] != null) body['parentId'] = argResults!['parent'];
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.createFolder.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryImportCommand extends Command<int> {
  @override String get name => 'import';
  @override String get description => 'Import a .appshots design file';

  _LibraryImportCommand() {
    argParser.addOption('file', abbr: 'f', help: 'Path to .appshots file', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.import_.path, {'file': argResults!['file']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryExportCommand extends Command<int> {
  @override String get name => 'export';
  @override String get description => 'Export a design to .appshots file';

  _LibraryExportCommand() {
    argParser.addOption('id', help: 'Design ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.export_.path, {'id': argResults!['id']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryMoveCommand extends Command<int> {
  @override String get name => 'move';
  @override String get description => 'Move a design to a folder';

  _LibraryMoveCommand() {
    argParser.addOption('design', help: 'Design ID', mandatory: true);
    argParser.addOption('folder', help: 'Target folder ID (omit to move to root)');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.move.path, {
      'designId': argResults!['design'],
      'folderId': argResults?['folder'],
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibrarySearchCommand extends Command<int> {
  @override String get name => 'search';
  @override String get description => 'Search designs by name';

  _LibrarySearchCommand() {
    argParser.addOption('query', abbr: 'q', help: 'Search query', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.search.path, {'query': argResults!['query']});
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _LibraryDeleteFolderCommand extends Command<int> {
  @override String get name => 'delete-folder';
  @override String get description => 'Delete a folder';

  _LibraryDeleteFolderCommand() {
    argParser.addOption('id', help: 'Folder ID', mandatory: true);
    argParser.addFlag('with-designs', help: 'Also delete designs inside the folder');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{
      'id': argResults!['id'],
      'withDesigns': argResults!['with-designs'],
    };
    final client = await AppClient.discover();
    final result = await client.post(LibraryAction.deleteFolder.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
