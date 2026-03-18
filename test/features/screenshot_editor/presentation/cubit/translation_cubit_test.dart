import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTranslationService extends Mock implements TranslationService {}

class MockTranslationProvider extends Mock implements TranslationProvider {}

void main() {
  late MockTranslationService mockService;
  late MockTranslationProvider mockProvider;

  setUp(() {
    mockService = MockTranslationService();
    mockProvider = MockTranslationProvider();
  });

  TranslationCubit buildCubit() => TranslationCubit(mockService);

  group('TranslationCubit', () {
    test('initial state is empty', () {
      final cubit = buildCubit();
      expect(cubit.state.bundle, isNull);
      expect(cubit.state.previewLocale, isNull);
      expect(cubit.state.localeStatuses, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isTranslating, false);
      cubit.close();
    });

    blocTest<TranslationCubit, TranslationState>(
      'loadBundle emits state with bundle',
      build: buildCubit,
      act: (cubit) => cubit.loadBundle(
        const TranslationBundle(sourceLocale: 'en', targetLocales: ['ja']),
      ),
      expect: () => [
        isA<TranslationState>()
            .having((s) => s.bundle, 'bundle', isNotNull)
            .having((s) => s.bundle!.sourceLocale, 'sourceLocale', 'en'),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'loadBundle with null clears bundle',
      build: buildCubit,
      seed: () =>
          TranslationState(bundle: const TranslationBundle(sourceLocale: 'en')),
      act: (cubit) => cubit.loadBundle(null),
      expect: () => [
        isA<TranslationState>().having((s) => s.bundle, 'bundle', isNull),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'translateAll translates all target locales',
      build: () {
        when(
          () => mockService.getActiveProvider(),
        ).thenAnswer((_) async => mockProvider);
        when(
          () => mockProvider.translate(
            texts: any(named: 'texts'),
            from: any(named: 'from'),
            to: 'ja',
          ),
        ).thenAnswer((_) async => {'o1': 'テスト'});
        when(
          () => mockProvider.translate(
            texts: any(named: 'texts'),
            from: any(named: 'from'),
            to: 'de',
          ),
        ).thenAnswer((_) async => {'o1': 'Test'});
        return TranslationCubit(mockService);
      },
      act: (cubit) => cubit.translateAll(
        sourceTexts: {'o1': 'Test'},
        sourceLocale: 'en',
        targetLocales: ['ja', 'de'],
      ),
      verify: (cubit) {
        // After all translations, both locales should be done
        expect(cubit.state.localeStatuses['ja'], TranslationStatus.done);
        expect(cubit.state.localeStatuses['de'], TranslationStatus.done);
        // Bundle should contain translations
        expect(cubit.state.bundle!.getTranslation('ja', 'o1'), 'テスト');
        expect(cubit.state.bundle!.getTranslation('de', 'o1'), 'Test');
      },
    );

    blocTest<TranslationCubit, TranslationState>(
      'translateAll handles partial failure',
      build: () {
        when(
          () => mockService.getActiveProvider(),
        ).thenAnswer((_) async => mockProvider);
        when(
          () => mockProvider.translate(
            texts: any(named: 'texts'),
            from: any(named: 'from'),
            to: 'ja',
          ),
        ).thenAnswer((_) async => {'o1': 'テスト'});
        when(
          () => mockProvider.translate(
            texts: any(named: 'texts'),
            from: any(named: 'from'),
            to: 'de',
          ),
        ).thenThrow(Exception('API error'));
        return TranslationCubit(mockService);
      },
      act: (cubit) => cubit.translateAll(
        sourceTexts: {'o1': 'Original'},
        sourceLocale: 'en',
        targetLocales: ['ja', 'de'],
      ),
      verify: (cubit) {
        expect(cubit.state.localeStatuses['ja'], TranslationStatus.done);
        expect(cubit.state.localeStatuses['de'], TranslationStatus.error);
        expect(cubit.state.errorMessage, isNotNull);
        // ja translation should still be saved
        expect(cubit.state.bundle!.getTranslation('ja', 'o1'), 'テスト');
      },
    );

    blocTest<TranslationCubit, TranslationState>(
      'translateAll does nothing with empty inputs',
      build: buildCubit,
      act: (cubit) => cubit.translateAll(
        sourceTexts: {},
        sourceLocale: 'en',
        targetLocales: ['ja'],
      ),
      expect: () => [],
    );

    blocTest<TranslationCubit, TranslationState>(
      'updateTranslation updates a single overlay',
      build: buildCubit,
      seed: () => TranslationState(
        bundle: TranslationBundle(
          sourceLocale: 'en',
          targetLocales: ['ja'],
          translations: {
            'ja': {'o1': 'Old'},
          },
        ),
      ),
      act: (cubit) => cubit.updateTranslation('ja', 'o1', 'New'),
      verify: (cubit) {
        expect(cubit.state.bundle!.getTranslation('ja', 'o1'), 'New');
      },
    );

    blocTest<TranslationCubit, TranslationState>(
      'updateTranslation does nothing without bundle',
      build: buildCubit,
      act: (cubit) => cubit.updateTranslation('ja', 'o1', 'text'),
      expect: () => [],
    );

    blocTest<TranslationCubit, TranslationState>(
      'setPreviewLocale emits new preview locale',
      build: buildCubit,
      act: (cubit) => cubit.setPreviewLocale('ja'),
      expect: () => [
        isA<TranslationState>().having(
          (s) => s.previewLocale,
          'previewLocale',
          'ja',
        ),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'setPreviewLocale with null clears locale',
      build: buildCubit,
      seed: () => const TranslationState(previewLocale: 'ja'),
      act: (cubit) => cubit.setPreviewLocale(null),
      expect: () => [
        isA<TranslationState>().having(
          (s) => s.previewLocale,
          'previewLocale',
          isNull,
        ),
      ],
    );
  });

  group('TranslationState', () {
    test('isTranslating returns true when any locale is translating', () {
      const state = TranslationState(
        localeStatuses: {
          'ja': TranslationStatus.done,
          'de': TranslationStatus.translating,
        },
      );
      expect(state.isTranslating, true);
    });

    test('isTranslating returns false when no locale is translating', () {
      const state = TranslationState(
        localeStatuses: {
          'ja': TranslationStatus.done,
          'de': TranslationStatus.done,
        },
      );
      expect(state.isTranslating, false);
    });

    test('completedCount returns count of done locales', () {
      const state = TranslationState(
        localeStatuses: {
          'ja': TranslationStatus.done,
          'de': TranslationStatus.translating,
          'fr': TranslationStatus.done,
        },
      );
      expect(state.completedCount, 2);
    });
  });
}
