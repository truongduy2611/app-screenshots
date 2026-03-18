import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
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
  group('TranslationCubit', () {
    late MockTranslationService mockService;
    late MockTranslationProvider mockProvider;

    setUp(() {
      mockService = MockTranslationService();
      mockProvider = MockTranslationProvider();
      when(() => mockService.getActiveProvider()).thenAnswer((_) async => mockProvider);
    });

    test('initial state is correct', () {
      final cubit = TranslationCubit(mockService);
      expect(cubit.state.bundle, isNull);
      expect(cubit.state.localeStatuses, isEmpty);
      expect(cubit.state.previewLocale, isNull);
    });

    blocTest<TranslationCubit, TranslationState>(
      'loadBundle restores bundle and updates successful locale statuses',
      build: () => TranslationCubit(mockService),
      act: (cubit) {
        final bundle = const TranslationBundle(targetLocales: ['fr', 'es', 'de'])
            .setTranslation('fr', 'o1', 'Salut')
            .setTranslation('es', 'o1', 'Hola');
        cubit.loadBundle(bundle);
      },
      expect: () => [
        isA<TranslationState>()
            .having((s) => s.bundle?.targetLocales, 'targets', ['fr', 'es', 'de'])
            .having((s) => s.localeStatuses['fr'], 'fr status', TranslationStatus.done)
            .having((s) => s.localeStatuses['es'], 'es status', TranslationStatus.done)
            .having((s) => s.localeStatuses.containsKey('de'), 'de status', isFalse),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'loadBundle with null clears bundle',
      build: () {
        final cubit = TranslationCubit(mockService);
        cubit.loadBundle(const TranslationBundle());
        return cubit;
      },
      act: (cubit) => cubit.loadBundle(null),
      expect: () => [
        isA<TranslationState>().having((s) => s.bundle, 'bundle', isNull),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'translateAll sets translating, calls provider, and updates translations',
      build: () {
        when(() => mockProvider.translate(
              texts: any(named: 'texts'),
              from: any(named: 'from'),
              to: any(named: 'to'),
              context: any(named: 'context'),
            )).thenAnswer((_) async => {'o1': 'Bonjour'});
        return TranslationCubit(mockService);
      },
      act: (cubit) => cubit.translateAll(
        sourceTexts: {'o1': 'Hello'},
        sourceLocale: 'en',
        targetLocales: ['fr'],
      ),
      expect: () => [
        isA<TranslationState>().having((s) => s.bundle?.sourceLocale, 'sourceLocale', 'en'),
        isA<TranslationState>().having((s) => s.localeStatuses['fr'], 'fr status', TranslationStatus.translating),
        isA<TranslationState>().having((s) => s.bundle?.translations['fr']!['o1'], 'translated fr', 'Bonjour'),
        isA<TranslationState>().having((s) => s.localeStatuses['fr'], 'fr status', TranslationStatus.done),
      ],
      verify: (_) {
        verify(() => mockProvider.translate(
              texts: {'o1': 'Hello'},
              from: 'en',
              to: 'fr',
              context: null,
            )).called(1);
      },
    );

    blocTest<TranslationCubit, TranslationState>(
      'retryLocale translates just that one locale',
      build: () {
        when(() => mockProvider.translate(
              texts: any(named: 'texts'),
              from: any(named: 'from'),
              to: any(named: 'to'),
              context: any(named: 'context'),
            )).thenAnswer((_) async => {'o1': '¡Hola! retry'});
        final cubit = TranslationCubit(mockService);
        cubit.loadBundle(const TranslationBundle(sourceLocale: 'en', targetLocales: ['es']));
        return cubit;
      },
      act: (cubit) => cubit.retryLocale('es', {'o1': 'Hello retry'}),
      expect: () => [
        isA<TranslationState>().having((s) => s.localeStatuses['es'], 'translating', TranslationStatus.translating),
        isA<TranslationState>().having((s) => s.bundle?.translations['es']?['o1'], 'translated', '¡Hola! retry'),
        isA<TranslationState>().having((s) => s.localeStatuses['es'], 'done', TranslationStatus.done),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'updateTranslation modifies single overlay translation',
      build: () {
        final cubit = TranslationCubit(mockService);
        cubit.loadBundle(const TranslationBundle().setTranslation('ja', 'o1', 'old'));
        return cubit;
      },
      act: (cubit) => cubit.updateTranslation('ja', 'o1', 'new'),
      expect: () => [
        isA<TranslationState>().having((s) => s.bundle?.translations['ja']!['o1'], 'o1', 'new'),
      ],
    );

    blocTest<TranslationCubit, TranslationState>(
      'applyManualTranslation completely sets translations for locale and marks as done',
      build: () => TranslationCubit(mockService),
      act: (cubit) => cubit.applyManualTranslation('es', {'o1': 'Manuel'}),
      expect: () => [
        isA<TranslationState>().having((s) => s.bundle?.translations['es']!['o1'], 'o1', 'Manuel'),
        isA<TranslationState>().having((s) => s.localeStatuses['es'], 'status', TranslationStatus.done),
      ],
    );

    test('removeLocale cleans up status, clear bundle and clears preview locale if active', () {
      final cubit = TranslationCubit(mockService);
      cubit.loadBundle(const TranslationBundle().setTranslation('es', 'o1', 'Hola'));
      cubit.applyManualTranslation('es', {'o1': 'Hola'});
      cubit.setPreviewLocale('es');
      
      expect(cubit.state.localeStatuses['es'], TranslationStatus.done);
      expect(cubit.state.previewLocale, 'es');

      cubit.removeLocale('es');

      expect(cubit.state.bundle?.targetLocales, isEmpty);
      expect(cubit.state.localeStatuses.containsKey('es'), isFalse);
      expect(cubit.state.previewLocale, isNull);
    });

    test('updateOverlayOverride works correctly', () {
      final cubit = TranslationCubit(mockService);
      cubit.updateOverlayOverride('ja', 'o1', const OverlayOverride(position: Offset(10, 50)));
      
      expect(cubit.state.bundle?.getOverride('ja', 'o1')?.position?.dx, 10);
      expect(cubit.state.bundle?.getOverride('ja', 'o1')?.position?.dy, 50);
    });

    test('setCustomPrompt works correctly', () {
      final cubit = TranslationCubit(mockService);
      cubit.setCustomPrompt('Super App');
      expect(cubit.state.bundle?.customPrompt, 'Super App');
    });

    test('setLocaleImage and removeLocaleImage work correctly', () {
      final cubit = TranslationCubit(mockService);
      cubit.setLocaleImage('ko', '/path/to/img.png');
      expect(cubit.state.bundle?.getLocaleImage('ko'), '/path/to/img.png');
      cubit.removeLocaleImage('ko');
      expect(cubit.state.bundle?.getLocaleImage('ko'), isNull);
    });
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
