import 'dart:async';

import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';

class JobsCommand extends Command<int> {
  @override
  String get name => 'jobs';

  @override
  String get description => 'Inspect background upload jobs';

  JobsCommand() {
    addSubcommand(_JobsListCommand());
    addSubcommand(_JobsStatusCommand());
  }
}

class _JobsListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description => 'List recent jobs';

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final result = await client.get(JobAction.list.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _JobsStatusCommand extends Command<int> {
  @override
  String get name => 'status';

  @override
  String get description => 'Show a job status';

  _JobsStatusCommand() {
    argParser.addOption('id', help: 'Job ID', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final id = Uri.encodeQueryComponent(argResults!['id'] as String);
    final result = await client.get('${JobAction.status.path}?id=$id');
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

Future<Map<String, dynamic>> waitForJob(
  AppClient client,
  Map<String, dynamic> startResult, {
  Duration timeout = const Duration(minutes: 30),
}) async {
  if (startResult['ok'] != true) return startResult;
  final startData = startResult['data'];
  if (startData is! Map || startData['id'] is! String) return startResult;
  final id = startData['id'] as String;
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    final encodedId = Uri.encodeQueryComponent(id);
    final response = await client.get('${JobAction.status.path}?id=$encodedId');
    if (response['ok'] != true) return response;
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      if (data['status'] == 'completed') {
        final result = data['result'];
        if (result is Map && (result['failureCount'] as int? ?? 0) > 0) {
          return {
            'ok': false,
            'error':
                'Upload completed with ${result['failureCount']} failure(s)',
            'data': data,
          };
        }
        return response;
      }
      if (data['status'] == 'failed') {
        return {
          'ok': false,
          'error': data['error'] ?? 'Background job failed',
          'data': data,
        };
      }
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  return {'ok': false, 'error': 'Timed out waiting for job $id'};
}
