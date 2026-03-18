import 'dart:io';

import 'package:args/command_runner.dart';

import 'app_client.dart';
import 'commands/status_command.dart';
import 'commands/editor_command.dart';
import 'commands/library_command.dart';
import 'commands/translate_command.dart';
import 'commands/preset_command.dart';
import 'commands/multi_command.dart';

/// Main CLI runner that parses args and dispatches to subcommands.
class CliRunner {
  Future<int> run(List<String> args) async {
    // If no args → enter REPL mode
    if (args.isEmpty) {
      return _runRepl();
    }

    final runner = CommandRunner<int>(
      'appshots',
      '🖼️  App Screenshots CLI — remote-control your screenshot editor',
    )
      ..argParser.addFlag('json', help: 'Output raw JSON', defaultsTo: false)
      ..argParser
          .addOption('port', help: 'Server port override', defaultsTo: null)
      ..addCommand(StatusCommand())
      ..addCommand(EditorCommand())
      ..addCommand(LibraryCommand())
      ..addCommand(TranslateCommand())
      ..addCommand(PresetCommand())
      ..addCommand(MultiCommand());

    try {
      final result = await runner.run(args);
      return result ?? 0;
    } on UsageException catch (e) {
      stderr.writeln(e);
      return 64;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  Future<int> _runRepl() async {
    final client = await AppClient.discover();

    // Check connection
    final status = await client.get('/api/status');
    if (status['ok'] != true) {
      stderr
          .writeln('❌ Cannot connect to App Screenshots. Is the app running?');
      return 1;
    }

    stdout.writeln('🖼️  App Screenshots CLI v1.0.0');
    stdout.writeln('Connected to localhost:${client.port}');
    stdout.writeln('Type "help" for commands, "exit" to quit.\n');

    while (true) {
      stdout.write('appshots> ');
      final line = stdin.readLineSync()?.trim();
      if (line == null || line == 'exit' || line == 'quit') {
        stdout.writeln('Bye! 👋');
        break;
      }
      if (line.isEmpty) continue;
      if (line == 'help') {
        _printReplHelp();
        continue;
      }

      // Parse the line as args and run through the normal runner
      final replArgs = _splitArgs(line);
      final replRunner = CommandRunner<int>(
        'appshots',
        'App Screenshots CLI',
      )
        ..argParser.addFlag('json', help: 'JSON output', defaultsTo: false)
        ..argParser.addOption('port', help: 'Port', defaultsTo: null)
        ..addCommand(StatusCommand())
        ..addCommand(EditorCommand())
        ..addCommand(LibraryCommand())
        ..addCommand(TranslateCommand())
        ..addCommand(PresetCommand())
        ..addCommand(MultiCommand());

      try {
        await replRunner.run(replArgs);
      } on UsageException catch (e) {
        stderr.writeln(e);
      } catch (e) {
        stderr.writeln('Error: $e');
      }
    }

    client.close();
    return 0;
  }

  void _printReplHelp() {
    stdout.writeln('''
Commands:
  status                           Check connection
  editor state                     Show current design
  editor set-background "#FF5733"  Set background color
  editor add-text --text "Hello"   Add text overlay
  editor list-overlays             List all overlays
  editor apply-preset --id ID      Apply a preset
  editor add-icon --codePoint N    Add icon overlay
  editor add-magnifier             Add magnifier overlay
  editor set-display-type --type   Change display type
  editor undo / redo               Undo/redo
  multi state                      Show multi-editor state
  multi switch --index N           Switch active design
  multi apply-preset --id ID       Apply preset to all
  multi batch --action set-background --color "#FFF"  Batch operations
  library list                     List saved designs
  library folders                  List folders
  translate --from en --to ja,ko   Translate overlays
  preset list                      List presets
  exit                             Quit REPL
''');
  }

  /// Split a line into args, respecting quoted strings.
  List<String> _splitArgs(String line) {
    final args = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    String? quoteChar;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuote) {
        if (c == quoteChar) {
          inQuote = false;
        } else {
          buffer.write(c);
        }
      } else if (c == '"' || c == "'") {
        inQuote = true;
        quoteChar = c;
      } else if (c == ' ') {
        if (buffer.isNotEmpty) {
          args.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(c);
      }
    }
    if (buffer.isNotEmpty) args.add(buffer.toString());
    return args;
  }
}
