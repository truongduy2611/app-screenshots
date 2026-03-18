import 'dart:io';
import 'dart:typed_data';

import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPersistenceService extends Mock
    implements ScreenshotPersistenceService {}

void main() {
  late MockPersistenceService mockService;
  late SharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(const ScreenshotDesign());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() async {
    mockService = MockPersistenceService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ScreenshotEditorCubit buildCubit({
    SavedDesign? initialDesign,
    File? imageFile,
  }) {
    return ScreenshotEditorCubit(
      persistenceService: mockService,
      prefs: prefs,
      initialDesign: initialDesign,
      imageFile: imageFile,
    );
  }

  group('ScreenshotEditorCubit', () {
    test('initial state has default design', () {
      final cubit = buildCubit();
      expect(cubit.state.design, isA<ScreenshotDesign>());
      expect(cubit.state.selectedOverlayId, isNull);
      expect(cubit.state.savedDesignId, isNull);
      cubit.close();
    });

    group('background', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateBackgroundColor emits state with new color',
        build: buildCubit,
        act: (cubit) => cubit.updateBackgroundColor(Colors.red),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.backgroundColor,
            'backgroundColor',
            Colors.red,
          ),
        ],
      );

      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateBackgroundGradient emits state with gradient',
        build: buildCubit,
        act: (cubit) => cubit.updateBackgroundGradient(
          const LinearGradient(colors: [Colors.red, Colors.blue]),
        ),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.backgroundGradient,
            'backgroundGradient',
            isA<LinearGradient>(),
          ),
        ],
      );

      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateBackgroundGradient with null clears gradient',
        build: buildCubit,
        seed: () => ScreenshotEditorState(
          design: ScreenshotDesign(
            backgroundGradient: const LinearGradient(
              colors: [Colors.red, Colors.blue],
            ),
          ),
        ),
        act: (cubit) => cubit.updateBackgroundGradient(null),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.backgroundGradient,
            'backgroundGradient',
            isNull,
          ),
        ],
      );
    });

    group('device frame', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateDeviceFrame emits state with new frame',
        build: buildCubit,
        act: (cubit) => cubit.updateDeviceFrame(null),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.deviceFrame,
            'deviceFrame',
            isNull,
          ),
        ],
      );
    });

    group('padding & radius', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updatePadding emits state with new padding',
        build: buildCubit,
        act: (cubit) => cubit.updatePadding(32),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.padding,
            'padding',
            32.0,
          ),
        ],
      );

      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateCornerRadius emits state with new radius',
        build: buildCubit,
        act: (cubit) => cubit.updateCornerRadius(20),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.cornerRadius,
            'cornerRadius',
            20.0,
          ),
        ],
      );
    });

    group('orientation', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'toggleOrientation switches portrait to landscape',
        build: buildCubit,
        act: (cubit) => cubit.toggleOrientation(),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.orientation,
            'orientation',
            Orientation.landscape,
          ),
        ],
      );

      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'toggleOrientation switches landscape back to portrait',
        build: buildCubit,
        seed: () => ScreenshotEditorState(
          design: ScreenshotDesign(orientation: Orientation.landscape),
        ),
        act: (cubit) => cubit.toggleOrientation(),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.orientation,
            'orientation',
            Orientation.portrait,
          ),
        ],
      );
    });

    group('text overlays', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'addTextOverlay adds an overlay and selects it',
        build: buildCubit,
        act: (cubit) => cubit.addTextOverlay(),
        expect: () => [
          isA<ScreenshotEditorState>()
              .having((s) => s.design.overlays.length, 'overlays count', 1)
              .having(
                (s) => s.selectedOverlayId,
                'selectedOverlayId',
                isNotNull,
              ),
        ],
      );

      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'deleteTextOverlay removes overlay and clears selection',
        build: buildCubit,
        act: (cubit) {
          cubit.addTextOverlay();
          final id = cubit.state.design.overlays.first.id;
          cubit.deleteTextOverlay(id);
        },
        expect: () => [
          // After add
          isA<ScreenshotEditorState>().having(
            (s) => s.design.overlays.length,
            'overlays count',
            1,
          ),
          // After delete
          isA<ScreenshotEditorState>()
              .having((s) => s.design.overlays.length, 'overlays count', 0)
              .having((s) => s.selectedOverlayId, 'selectedOverlayId', isNull),
        ],
      );

      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'selectOverlay changes selection',
        build: buildCubit,
        act: (cubit) {
          cubit.addTextOverlay();
          cubit.selectOverlay(null);
        },
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.selectedOverlayId,
            'selected',
            isNotNull,
          ),
          isA<ScreenshotEditorState>().having(
            (s) => s.selectedOverlayId,
            'deselected',
            isNull,
          ),
        ],
      );
    });

    group('grid snapping', () {
      test('snapOffset returns position unchanged when snap disabled', () {
        final cubit = buildCubit();
        cubit.updateGridSettings(
          const GridSettings(snapToGrid: false, showCenterLines: false),
        );
        final result = cubit.snapOffset(
          const Offset(123, 456),
          const Size(400, 800),
        );
        expect(result, const Offset(123, 456));
        cubit.close();
      });

      test('snapOffset snaps to grid when close to grid line', () {
        final cubit = buildCubit();
        cubit.updateGridSettings(
          const GridSettings(snapToGrid: true, gridSize: 50),
        );
        // 48 is within 10 of 50
        final result = cubit.snapOffset(
          const Offset(48, 48),
          const Size(400, 800),
        );
        expect(result, const Offset(50, 50));
        cubit.close();
      });

      test('snapOffset snaps to center when showCenterLines enabled', () {
        final cubit = buildCubit();
        cubit.updateGridSettings(
          const GridSettings(snapToGrid: false, showCenterLines: true),
        );
        // 195 is within 10 of 200 (center of 400)
        final result = cubit.snapOffset(
          const Offset(195, 395),
          const Size(400, 800),
        );
        expect(result, const Offset(200, 400));
        cubit.close();
      });
    });

    group('persistence', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'saveDesign calls persistence service and updates state',
        build: () {
          when(
            () => mockService.saveDesign(
              design: any(named: 'design'),
              thumbnailBytes: any(named: 'thumbnailBytes'),
              name: any(named: 'name'),
              existingId: any(named: 'existingId'),
              originalImageFile: any(named: 'originalImageFile'),
              folderId: any(named: 'folderId'),
            ),
          ).thenAnswer(
            (_) async => SavedDesign(
              id: 'test-id',
              name: 'Test Design',
              lastModified: DateTime(2026),
              thumbnailPath: '/test.png',
              design: const ScreenshotDesign(),
            ),
          );
          return buildCubit();
        },
        act: (cubit) => cubit.saveDesign('Test Design', Uint8List(0)),
        expect: () => [
          isA<ScreenshotEditorState>()
              .having((s) => s.savedDesignId, 'savedDesignId', 'test-id')
              .having(
                (s) => s.savedDesignName,
                'savedDesignName',
                'Test Design',
              ),
        ],
      );

      test('loadDesignIntoEditor updates state with saved design', () {
        final cubit = buildCubit();
        final design = SavedDesign(
          id: 'loaded-id',
          name: 'Loaded Design',
          lastModified: DateTime(2026),
          thumbnailPath: '/thumb.png',
          design: ScreenshotDesign(padding: 50),
        );

        cubit.loadDesignIntoEditor(design);

        expect(cubit.state.savedDesignId, 'loaded-id');
        expect(cubit.state.savedDesignName, 'Loaded Design');
        expect(cubit.state.design.padding, 50);
        expect(cubit.state.selectedOverlayId, isNull);
        cubit.close();
      });
    });

    group('doodle settings', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateDoodleSettings with null clears doodle',
        build: buildCubit,
        act: (cubit) => cubit.updateDoodleSettings(null),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.doodleSettings,
            'doodleSettings',
            isNull,
          ),
        ],
      );
    });

    group('frame rotation', () {
      blocTest<ScreenshotEditorCubit, ScreenshotEditorState>(
        'updateFrameRotation emits new rotation value',
        build: buildCubit,
        act: (cubit) => cubit.updateFrameRotation(15),
        expect: () => [
          isA<ScreenshotEditorState>().having(
            (s) => s.design.frameRotation,
            'frameRotation',
            15.0,
          ),
        ],
      );
    });
  });
}
