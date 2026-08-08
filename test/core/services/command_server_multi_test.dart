import 'dart:convert';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/play_upload_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/data/screenshot_presets.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';

import 'dart:typed_data';
import 'dart:io';

class MockScreenshotPersistenceService extends Mock
    implements ScreenshotPersistenceService {}

class MockDesignFileService extends Mock implements DesignFileService {}

class MockMultiScreenshotCubit extends Mock implements MultiScreenshotCubit {}

class MockScreenshotEditorCubit extends Mock implements ScreenshotEditorCubit {}

class MockAscUploadService extends Mock implements AscUploadService {}

class MockPlayUploadService extends Mock implements PlayUploadService {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class FakeScreenshotPreset extends Fake implements ScreenshotPreset {}

class FakeAscAppConfig extends Fake implements AscAppConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(FakeScreenshotPreset());
    registerFallbackValue(const ScreenshotDesign());
    registerFallbackValue(FakeAscAppConfig());
  });

  group('CommandServer Multi Routes', () {
    late CommandServer server;
    late MockMultiScreenshotCubit mockMultiCubit;
    late MockScreenshotEditorCubit mockEditorCubit;
    late MockScreenshotPersistenceService mockPersistence;
    late MockAscUploadService mockAscUploadService;
    late MockPlayUploadService mockPlayUploadService;
    late MockSettingsRepository mockSettingsRepository;
    late http.Client httpClient;

    setUp(() async {
      mockPersistence = MockScreenshotPersistenceService();
      mockMultiCubit = MockMultiScreenshotCubit();
      mockEditorCubit = MockScreenshotEditorCubit();
      mockAscUploadService = MockAscUploadService();
      mockPlayUploadService = MockPlayUploadService();
      mockSettingsRepository = MockSettingsRepository();

      when(() => mockMultiCubit.state).thenReturn(
        const MultiScreenshotState(
          designs: [ScreenshotDesign()],
          activeIndex: 0,
        ),
      );

      server = CommandServer(
        persistenceService: mockPersistence,
        designFileService: MockDesignFileService(),
        settingsRepository: mockSettingsRepository,
        ascUploadService: mockAscUploadService,
        playUploadService: mockPlayUploadService,
      );

      server.registerMulti(mockMultiCubit);
      server.registerEditor(mockEditorCubit);

      await server.start();
      httpClient = http.Client();
    });

    tearDown(() async {
      httpClient.close();
      await server.stop();
    });

    Future<Map<String, dynamic>> getApi(String path) async {
      final res = await httpClient.get(
        Uri.parse('http://localhost:${server.port}$path'),
        headers: {'Authorization': 'Bearer ${server.sessionToken}'},
      );
      return jsonDecode(res.body);
    }

    Future<Map<String, dynamic>> postApi(
      String path,
      Map<String, dynamic> body,
    ) async {
      final res = await httpClient.post(
        Uri.parse('http://localhost:${server.port}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${server.sessionToken}',
        },
        body: jsonEncode(body),
      );
      return jsonDecode(res.body);
    }

    test('multi state returns valid state JSON', () async {
      final json = await getApi('/api/multi/state');
      expect(json['ok'], isTrue);
      expect(json['data']['activeIndex'], 0);
      expect(json['data']['designCount'], 1);
    });

    test('rejects requests without the session token', () async {
      final response = await httpClient.get(
        Uri.parse('http://localhost:${server.port}/api/status'),
      );
      expect(response.statusCode, HttpStatus.unauthorized);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['ok'], isFalse);
    });

    test('ASC upload runs as a background job', () async {
      String? stagedPath;

      when(
        () => mockAscUploadService.uploadAll(
          appId: any(named: 'appId'),
          localeScreenshots: any(named: 'localeScreenshots'),
          displayType: any(named: 'displayType'),
          onProgress: any(named: 'onProgress'),
          platform: any(named: 'platform'),
          deleteExisting: any(named: 'deleteExisting'),
          isCustomProductPage: any(named: 'isCustomProductPage'),
          customProductPageId: any(named: 'customProductPageId'),
        ),
      ).thenAnswer((invocation) async {
        final screenshots =
            invocation.namedArguments[#localeScreenshots]
                as Map<String, List<File>>;
        stagedPath = screenshots['en-US']!.single.path;
        expect(await screenshots['en-US']!.single.exists(), isTrue);
        final progress =
            invocation.namedArguments[#onProgress]
                as void Function(AscUploadProgress);
        progress(const AscUploadProgress(locale: 'done', current: 1, total: 1));
        return const AscUploadResult(
          successCount: 1,
          failureCount: 0,
          errors: [],
        );
      });

      final started = await postApi('/api/asc/upload', {
        'appId': '123',
        'displayType': 'APP_IPHONE_67',
        'screenshots': {
          'en-US': [
            {
              'name': '01.png',
              'data': base64Encode([1, 2, 3]),
            },
          ],
        },
      });
      expect(started['ok'], isTrue, reason: started.toString());
      final id = started['data']['id'] as String;

      Map<String, dynamic>? status;
      for (var i = 0; i < 20; i++) {
        status = await getApi('/api/jobs/status?id=$id');
        if (status['data']['status'] == 'completed') break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(status?['data']['status'], 'completed');
      expect(status?['data']['result']['successCount'], 1);
      expect(stagedPath, isNotNull);
      expect(await File(stagedPath!).exists(), isFalse);
    });

    test('Google Play upload runs as a background job', () async {
      final root = await Directory.systemTemp.createTemp('appshots_play_test_');
      addTearDown(() => root.delete(recursive: true));
      final localeDir = await Directory('${root.path}/en-US').create();
      await File('${localeDir.path}/01.png').writeAsBytes([1, 2, 3]);

      when(
        () => mockPlayUploadService.uploadAll(
          packageName: any(named: 'packageName'),
          localeScreenshots: any(named: 'localeScreenshots'),
          imageType: any(named: 'imageType'),
          onProgress: any(named: 'onProgress'),
          deleteExisting: any(named: 'deleteExisting'),
          changesNotSentForReview: any(named: 'changesNotSentForReview'),
        ),
      ).thenAnswer(
        (_) async =>
            const AscUploadResult(successCount: 1, failureCount: 0, errors: []),
      );

      final started = await postApi('/api/play/upload', {
        'packageName': 'com.example.app',
        'sourceDirectory': root.path,
        'imageType': 'phoneScreenshots',
      });
      expect(started['ok'], isTrue, reason: started.toString());
      final id = started['data']['id'] as String;

      Map<String, dynamic>? status;
      for (var i = 0; i < 20; i++) {
        status = await getApi('/api/jobs/status?id=$id');
        if (status['data']['status'] == 'completed') break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(status?['data']['status'], 'completed');
      expect(status?['data']['result']['successCount'], 1);
    });

    test('multi switchDesign calls cubit.setActiveIndex', () async {
      final json = await postApi('/api/multi/switch-design', {'index': 0});
      expect(json['ok'], isTrue, reason: json.toString());
      verify(() => mockMultiCubit.setActiveIndex(0)).called(1);
    });

    test('multi addDesign calls cubit.addDesign', () async {
      final json = await postApi('/api/multi/add-design', {});
      expect(json['ok'], isTrue);
      verify(() => mockMultiCubit.addDesign()).called(1);
    });

    test('multi removeDesign calls cubit.removeDesign', () async {
      final json = await postApi('/api/multi/remove-design', {'index': 0});
      expect(json['ok'], isTrue);
      verify(() => mockMultiCubit.removeDesign(0)).called(1);
    });

    test('multi applyPreset calls cubit.applyPreset', () async {
      final presetId = ScreenshotPresets.all.first.id;
      final json = await postApi('/api/multi/apply-preset', {'id': presetId});
      expect(json['ok'], isTrue);
      verify(() => mockMultiCubit.applyPreset(any())).called(1);
    });

    test('multi saveDesign calls cubit.saveDesign', () async {
      when(
        () => mockMultiCubit.saveDesign(
          any(),
          any(),
          override: any(named: 'override'),
          ascAppConfig: any(named: 'ascAppConfig'),
        ),
      ).thenAnswer((_) async {});

      final json = await postApi('/api/multi/save-design', {
        'name': 'Test Design',
        'override': true,
      });
      expect(json['ok'], isTrue);
      verify(
        () => mockMultiCubit.saveDesign(
          'Test Design',
          any(),
          override: true,
          ascAppConfig: any(named: 'ascAppConfig'),
        ),
      ).called(1);
    });

    test(
      'multi batch operations require editorCubit and perform updates',
      () async {
        // Setup the cubit to allow state updates
        when(
          () => mockMultiCubit.updateDesignForSlot(any(), any()),
        ).thenAnswer((_) {});

        final json = await postApi('/api/multi/batch', {
          'action': 'set-padding',
          'padding': 50,
        });
        expect(json['ok'], isTrue);
        expect(json['data']['results'].length, 1);
        expect(json['data']['results'][0]['ok'], isTrue);
        verify(
          () => mockMultiCubit.setActiveIndex(any()),
        ).called(2); // once to switch to 0, once to restore original index
        verify(() => mockMultiCubit.updateDesignForSlot(0, any())).called(1);
      },
    );

    test('multi batch returns error if editorCubit is null', () async {
      server.unregisterEditor(mockEditorCubit);

      final json = await postApi('/api/multi/batch', {
        'action': 'set-padding',
        'padding': 50,
      });
      expect(json['ok'], isFalse);
      expect(
        json['error'],
        'No active editor for batch operations. Open a design first.',
      );
    });
  });
}
