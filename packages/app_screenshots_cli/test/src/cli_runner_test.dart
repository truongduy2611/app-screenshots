import 'package:app_screenshots_cli/src/cli_runner.dart';
import 'package:test/test.dart';

void main() {
  group('CliRunner', () {
    late CliRunner runner;

    setUp(() {
      runner = CliRunner();
    });

    test('returns 0 when asking for help', () async {
      final code = await runner.run(['--help']);
      expect(code, equals(0));
    });

    test('returns 64 (UsageException) on invalid argument', () async {
      final code = await runner.run(['--invalid-flag']);
      expect(code, equals(64));
    });

    test('returns 64 (UsageException) on unknown command', () async {
      final code = await runner.run(['unknown_command']);
      expect(code, equals(64));
    });
  });
}
