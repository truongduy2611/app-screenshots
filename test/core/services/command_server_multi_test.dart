import 'dart:convert';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/data/screenshot_presets.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'dart:typed_data';

class MockScreenshotPersistenceService extends Mock implements ScreenshotPersistenceService {}
class MockDesignFileService extends Mock implements DesignFileService {}
class MockMultiScreenshotCubit extends Mock implements MultiScreenshotCubit {}
class MockScreenshotEditorCubit extends Mock implements ScreenshotEditorCubit {}

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
    late http.Client httpClient;

    setUp(() async {
      mockPersistence = MockScreenshotPersistenceService();
      mockMultiCubit = MockMultiScreenshotCubit();
      mockEditorCubit = MockScreenshotEditorCubit();
      
      when(() => mockMultiCubit.state).thenReturn(const MultiScreenshotState(
        designs: [ScreenshotDesign()],
        activeIndex: 0,
      ));

      server = CommandServer(
        persistenceService: mockPersistence,
        designFileService: MockDesignFileService(),
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
      final res = await httpClient.get(Uri.parse('http://localhost:${server.port}$path'));
      return jsonDecode(res.body);
    }

    Future<Map<String, dynamic>> postApi(String path, Map<String, dynamic> body) async {
      final res = await httpClient.post(
        Uri.parse('http://localhost:${server.port}$path'),
        headers: {'Content-Type': 'application/json'},
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
      when(() => mockMultiCubit.saveDesign(any(), any(), override: any(named: 'override'), ascAppConfig: any(named: 'ascAppConfig')))
          .thenAnswer((_) async {});

      final json = await postApi('/api/multi/save-design', {'name': 'Test Design', 'override': true});
      expect(json['ok'], isTrue);
      verify(() => mockMultiCubit.saveDesign('Test Design', any(), override: true, ascAppConfig: any(named: 'ascAppConfig'))).called(1);
    });

    test('multi batch operations require editorCubit and perform updates', () async {
      // Setup the cubit to allow state updates
      when(() => mockMultiCubit.updateDesignForSlot(any(), any())).thenAnswer((_) {});
      
      final json = await postApi('/api/multi/batch', {
        'action': 'set-padding',
        'padding': 50
      });
      expect(json['ok'], isTrue);
      expect(json['data']['results'].length, 1);
      expect(json['data']['results'][0]['ok'], isTrue);
      verify(() => mockMultiCubit.setActiveIndex(any())).called(2); // once to switch to 0, once to restore original index
      verify(() => mockMultiCubit.updateDesignForSlot(0, any())).called(1);
    });
    
    test('multi batch returns error if editorCubit is null', () async {
      server.unregisterEditor(mockEditorCubit);
      
      final json = await postApi('/api/multi/batch', {
        'action': 'set-padding',
        'padding': 50
      });
      expect(json['ok'], isFalse);
      expect(json['error'], 'No active editor for batch operations. Open a design first.');
    });
  });
}
