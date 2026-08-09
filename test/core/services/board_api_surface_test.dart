import 'dart:io';

import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board API is spread across four places that must agree: the action enum,
/// the route prefix, the server's switch, and the OpenAPI spec. Nothing in the
/// compiler links them, so drift here is silent — a new action simply 404s, or
/// is undocumented.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('BoardAction', () {
    test('every action round-trips through its kebab-case name', () {
      for (final action in BoardAction.values) {
        expect(
          BoardAction.fromActionName(action.actionName),
          action,
          reason: '${action.name} did not round-trip',
        );
      }
    });

    test('action names are unique and kebab-case', () {
      final names = BoardAction.values.map((a) => a.actionName).toList();
      expect(names.toSet(), hasLength(names.length), reason: 'duplicate names');
      for (final name in names) {
        expect(
          name,
          matches(RegExp(r'^[a-z]+(-[a-z]+)*$')),
          reason: '"$name" is not kebab-case',
        );
      }
    });

    test('paths sit under the board route prefix', () {
      for (final action in BoardAction.values) {
        expect(action.path, startsWith(ApiRoute.board.prefix));
        // The dispatcher strips the prefix and matches the remainder, so the
        // two have to line up exactly.
        expect(ApiRoute.fromPath(action.path), ApiRoute.board);
        expect(ApiRoute.board.actionFrom(action.path), action.actionName);
      }
    });

    test('the trailing-underscore action maps to a clean path', () {
      // `export_` exists only because `export` is awkward next to Dart's
      // keywords; the wire name must not leak the underscore.
      expect(BoardAction.export_.actionName, 'export');
      expect(BoardAction.export_.path, '/api/board/export');
    });
  });

  group('server wiring', () {
    test('every action is handled by the board route', () {
      final handler = read('lib/core/services/command_server_board.dart');
      for (final action in BoardAction.values) {
        expect(
          handler,
          contains('BoardAction.${action.name}'),
          reason: '${action.name} has no case in the board handler',
        );
      }
    });

    test('the board route is dispatched by the server', () {
      final server = read('lib/core/services/command_server.dart');
      expect(server, contains('case ApiRoute.board:'));
      expect(server, contains('handleBoard('));
    });

    test('the board page registers and unregisters its cubit', () {
      // Without this the server has no active board and every call fails with
      // "no board editor", which is exactly how this shipped the first time.
      final page =
          read('lib/features/screenshot_editor/presentation/pages/board_page.dart');
      expect(page, contains('registerBoard('));
      expect(page, contains('unregisterBoard('));
      expect(page, contains('registerBoardExport('));
      expect(page, contains('unregisterBoardExport('));
    });
  });

  group('OpenAPI spec', () {
    test('documents every board action', () {
      final spec = read('lib/core/services/command_server_openapi.dart');
      for (final action in BoardAction.values) {
        expect(
          spec,
          contains('/api/board/${action.actionName}:'),
          reason: '${action.actionName} is missing from the OpenAPI spec',
        );
      }
    });

    test('has no keys left at column zero inside the document', () {
      // A single un-indented key makes the whole spec unparseable, which takes
      // the /api/docs page down with it — and nothing else catches that.
      final source = read('lib/core/services/command_server_openapi.dart');
      final match = RegExp(
        r'const String _openApiYaml = r"""(.*?)\n""";',
        dotAll: true,
      ).firstMatch(source);
      expect(match, isNotNull, reason: 'spec string not found');

      const topLevel = {
        'openapi',
        'info',
        'servers',
        'components',
        'paths',
        'tags',
        'security',
      };
      final offenders = <String>[];
      for (final line in match!.group(1)!.split('\n')) {
        if (line.isEmpty || line.startsWith(' ') || line.startsWith('#')) {
          continue;
        }
        final key = line.split(':').first.trim();
        if (!topLevel.contains(key)) offenders.add(line);
      }
      expect(offenders, isEmpty, reason: 'un-indented YAML keys');
    });
  });
}
