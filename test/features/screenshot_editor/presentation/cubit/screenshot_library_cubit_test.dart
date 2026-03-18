import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPersistenceService extends Mock
    implements ScreenshotPersistenceService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPersistenceService mockService;

  setUp(() {
    mockService = MockPersistenceService();
  });

  ScreenshotLibraryCubit buildCubit() {
    return ScreenshotLibraryCubit(
      persistenceService: mockService,
    );
  }

  final testDesigns = [
    SavedDesign(
      id: '1',
      name: 'Design 1',
      lastModified: DateTime(2026),
      thumbnailPath: '/thumb1.png',
      design: const ScreenshotDesign(),
    ),
    SavedDesign(
      id: '2',
      name: 'Design 2',
      lastModified: DateTime(2026),
      thumbnailPath: '/thumb2.png',
      folderId: 'folder-1',
      design: const ScreenshotDesign(),
    ),
  ];

  final testFolders = [
    DesignFolder(
      id: 'folder-1',
      name: 'Test Folder',
      createdAt: DateTime(2026),
    ),
  ];

  /// Helper: stubs both getAllDesigns and getAllFolders with test data.
  void stubLoadAll() {
    when(() => mockService.getAllDesigns())
        .thenAnswer((_) async => testDesigns);
    when(() => mockService.getAllFolders())
        .thenAnswer((_) async => testFolders);
  }

  /// Helper: stubs getAllDesigns and getAllFolders with empty lists.
  void stubLoadEmpty() {
    when(() => mockService.getAllDesigns()).thenAnswer((_) async => []);
    when(() => mockService.getAllFolders()).thenAnswer((_) async => []);
  }

  group('ScreenshotLibraryCubit', () {
    test('initial state is ScreenshotLibraryInitial', () {
      final cubit = buildCubit();
      expect(cubit.state, isA<ScreenshotLibraryInitial>());
      cubit.close();
    });

    group('loadDesigns', () {
      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'emits Loading then Loaded with root-level designs',
        build: () {
          stubLoadAll();
          return buildCubit();
        },
        act: (cubit) => cubit.loadDesigns(),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryLoaded>()
              .having(
                (s) => s.designs.length,
                'root designs (no folderId)',
                1, // Design 1 has no folderId
              )
              .having((s) => s.folders.length, 'root folders (no parentId)', 1)
              .having((s) => s.currentFolderId, 'currentFolderId', isNull),
        ],
      );

      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'emits Error when service throws',
        build: () {
          when(
            () => mockService.getAllDesigns(),
          ).thenThrow(Exception('disk error'));
          when(() => mockService.getAllFolders()).thenAnswer((_) async => []);
          return buildCubit();
        },
        act: (cubit) => cubit.loadDesigns(),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryError>(),
        ],
      );
    });

    group('folder navigation', () {
      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'openFolder filters designs by folderId',
        build: () {
          stubLoadAll();
          return buildCubit();
        },
        seed: () {
          // Pre-seed with loaded state so _refilterCurrentData can work
          stubLoadAll();
          return ScreenshotLibraryLoaded(
            designs: testDesigns.where((d) => d.folderId == null).toList(),
            folders: testFolders,
            allDesigns: testDesigns,
            allFolders: testFolders,
          );
        },
        act: (cubit) => cubit.openFolder('folder-1'),
        expect: () => [
          isA<ScreenshotLibraryLoaded>()
              .having(
                (s) => s.designs.length,
                'folder designs',
                1, // Design 2 is in folder-1
              )
              .having((s) => s.currentFolderId, 'currentFolderId', 'folder-1'),
        ],
      );

      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'navigateBack resets to root',
        build: () {
          stubLoadAll();
          return buildCubit();
        },
        seed: () {
          stubLoadAll();
          return ScreenshotLibraryLoaded(
            designs: testDesigns.where((d) => d.folderId == null).toList(),
            folders: testFolders,
            allDesigns: testDesigns,
            allFolders: testFolders,
          );
        },
        act: (cubit) async {
          await cubit.openFolder('folder-1');
          await cubit.navigateBack();
        },
        expect: () => [
          // openFolder — refilters to folder-1
          isA<ScreenshotLibraryLoaded>().having(
            (s) => s.currentFolderId,
            'in folder',
            'folder-1',
          ),
          // navigateBack — refilters to root
          isA<ScreenshotLibraryLoaded>().having(
            (s) => s.currentFolderId,
            'back to root',
            isNull,
          ),
        ],
      );
    });

    group('folder CRUD', () {
      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'createFolder calls service and reloads',
        build: () {
          when(
            () => mockService.createFolder(
              any(),
              parentId: any(named: 'parentId'),
            ),
          ).thenAnswer(
            (_) async => DesignFolder(
              id: 'new-folder',
              name: 'New Folder',
              createdAt: DateTime(2026),
            ),
          );
          stubLoadEmpty();
          return buildCubit();
        },
        act: (cubit) => cubit.createFolder('New Folder'),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryLoaded>(),
        ],
        verify: (_) {
          verify(
            () => mockService.createFolder('New Folder', parentId: null),
          ).called(1);
        },
      );

      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'deleteFolder calls service and reloads',
        build: () {
          when(() => mockService.deleteFolder(any())).thenAnswer((_) async {});
          stubLoadEmpty();
          return buildCubit();
        },
        act: (cubit) => cubit.deleteFolder('folder-1'),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryLoaded>(),
        ],
        verify: (_) {
          verify(() => mockService.deleteFolder('folder-1')).called(1);
        },
      );

      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'renameFolder calls service and reloads',
        build: () {
          when(
            () => mockService.renameFolder(any(), any()),
          ).thenAnswer((_) async {});
          stubLoadEmpty();
          return buildCubit();
        },
        act: (cubit) => cubit.renameFolder('folder-1', 'Renamed'),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryLoaded>(),
        ],
        verify: (_) {
          verify(
            () => mockService.renameFolder('folder-1', 'Renamed'),
          ).called(1);
        },
      );
    });

    group('design operations', () {
      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'deleteDesign calls service and reloads',
        build: () {
          when(() => mockService.deleteDesign(any())).thenAnswer((_) async {});
          stubLoadEmpty();
          return buildCubit();
        },
        act: (cubit) => cubit.deleteDesign('1'),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryLoaded>(),
        ],
        verify: (_) {
          verify(() => mockService.deleteDesign('1')).called(1);
        },
      );

      blocTest<ScreenshotLibraryCubit, ScreenshotLibraryState>(
        'moveDesignToFolder calls service and reloads',
        build: () {
          when(
            () => mockService.moveDesignToFolder(any(), any()),
          ).thenAnswer((_) async {});
          stubLoadEmpty();
          return buildCubit();
        },
        act: (cubit) => cubit.moveDesignToFolder('1', 'folder-1'),
        expect: () => [
          isA<ScreenshotLibraryLoading>(),
          isA<ScreenshotLibraryLoaded>(),
        ],
        verify: (_) {
          verify(
            () => mockService.moveDesignToFolder('1', 'folder-1'),
          ).called(1);
        },
      );
    });
  });
}
