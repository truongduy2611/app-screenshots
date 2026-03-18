import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:test/test.dart';

void main() {
  group('ApiRoute', () {
    group('fromPath', () {
      test('matches status route exactly', () {
        expect(ApiRoute.fromPath('/api/status'), ApiRoute.status);
      });

      test('matches editor prefix', () {
        expect(ApiRoute.fromPath('/api/editor/set-background'), ApiRoute.editor);
      });

      test('matches library prefix', () {
        expect(ApiRoute.fromPath('/api/library/list'), ApiRoute.library);
      });

      test('matches translate prefix', () {
        expect(
          ApiRoute.fromPath('/api/translate/apply'),
          ApiRoute.translate,
        );
      });

      test('matches preset prefix', () {
        expect(ApiRoute.fromPath('/api/preset/list'), ApiRoute.preset);
      });

      test('matches multi prefix', () {
        expect(ApiRoute.fromPath('/api/multi/state'), ApiRoute.multi);
      });

      test('returns null for unknown path', () {
        expect(ApiRoute.fromPath('/api/unknown/something'), isNull);
      });

      test('returns null for empty path', () {
        expect(ApiRoute.fromPath(''), isNull);
      });

      test('status does not match prefix — only exact match', () {
        // '/api/status' should match, but '/api/status/extra' should not
        // match status — it would be an unknown path
        expect(ApiRoute.fromPath('/api/status/extra'), isNull);
      });
    });

    group('actionFrom', () {
      test('extracts action suffix correctly', () {
        expect(
          ApiRoute.editor.actionFrom('/api/editor/set-background'),
          'set-background',
        );
      });

      test('extracts suffix from translate route', () {
        expect(
          ApiRoute.translate.actionFrom('/api/translate/apply-all'),
          'apply-all',
        );
      });

      test('extracts empty suffix when path equals prefix', () {
        expect(
          ApiRoute.editor.actionFrom('/api/editor/'),
          '',
        );
      });
    });

    group('prefixes', () {
      test('each route has the expected prefix', () {
        expect(ApiRoute.status.prefix, '/api/status');
        expect(ApiRoute.editor.prefix, '/api/editor/');
        expect(ApiRoute.library.prefix, '/api/library/');
        expect(ApiRoute.translate.prefix, '/api/translate/');
        expect(ApiRoute.preset.prefix, '/api/preset/');
        expect(ApiRoute.multi.prefix, '/api/multi/');
      });
    });
  });

  group('AppConstants', () {
    test('defaultPort is 19222', () {
      expect(AppConstants.defaultPort, 19222);
    });

    test('configDirName is correct', () {
      expect(AppConstants.configDirName, '.config/app-screenshots');
    });

    test('portFileName is correct', () {
      expect(AppConstants.portFileName, 'server.port');
    });
  });
}
