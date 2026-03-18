import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
  });

  group('ThemeCubit', () {
    test('initial state is ThemeState with ThemeMode.system', () {
      final cubit = ThemeCubit(mockRepository);
      expect(cubit.state, const ThemeState());
      expect(cubit.state.themeMode, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeState>(
      'loadTheme emits stored theme mode',
      build: () {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeMode.dark);
        return ThemeCubit(mockRepository);
      },
      act: (cubit) => cubit.loadTheme(),
      expect: () => [const ThemeState(themeMode: ThemeMode.dark)],
    );

    blocTest<ThemeCubit, ThemeState>(
      'setThemeMode persists and emits new theme mode',
      build: () {
        when(() => mockRepository.setThemeMode(any())).thenAnswer((_) async {});
        return ThemeCubit(mockRepository);
      },
      act: (cubit) => cubit.setThemeMode(ThemeMode.light),
      expect: () => [const ThemeState(themeMode: ThemeMode.light)],
      verify: (_) {
        verify(() => mockRepository.setThemeMode(ThemeMode.light)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'setThemeMode to dark persists and emits dark mode',
      build: () {
        when(() => mockRepository.setThemeMode(any())).thenAnswer((_) async {});
        return ThemeCubit(mockRepository);
      },
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      expect: () => [const ThemeState(themeMode: ThemeMode.dark)],
      verify: (_) {
        verify(() => mockRepository.setThemeMode(ThemeMode.dark)).called(1);
      },
    );
  });
}
