import 'dart:io';

import 'package:app_screenshots_cli/src/cli_runner.dart';

Future<void> main(List<String> args) async {
  final runner = CliRunner();
  final exitCode = await runner.run(args);
  exit(exitCode);
}
