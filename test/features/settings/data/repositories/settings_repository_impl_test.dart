import 'package:app_screenshots/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepositoryImpl repository;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = SettingsRepositoryImpl(prefs, const FlutterSecureStorage());
  });

  group('SettingsRepositoryImpl', () {
    group('getThemeMode', () {
      test('returns ThemeMode.system when no value is stored', () async {
        final result = await repository.getThemeMode();
        expect(result, ThemeMode.system);
      });

      test('returns ThemeMode.light when "light" is stored', () async {
        await prefs.setString('theme_mode', 'light');
        final result = await repository.getThemeMode();
        expect(result, ThemeMode.light);
      });

      test('returns ThemeMode.dark when "dark" is stored', () async {
        await prefs.setString('theme_mode', 'dark');
        final result = await repository.getThemeMode();
        expect(result, ThemeMode.dark);
      });

      test('returns ThemeMode.system for unknown stored value', () async {
        await prefs.setString('theme_mode', 'unknown');
        final result = await repository.getThemeMode();
        expect(result, ThemeMode.system);
      });
    });

    group('setThemeMode', () {
      test('stores "light" for ThemeMode.light', () async {
        await repository.setThemeMode(ThemeMode.light);
        expect(prefs.getString('theme_mode'), 'light');
      });

      test('stores "dark" for ThemeMode.dark', () async {
        await repository.setThemeMode(ThemeMode.dark);
        expect(prefs.getString('theme_mode'), 'dark');
      });

      test('stores "system" for ThemeMode.system', () async {
        await repository.setThemeMode(ThemeMode.system);
        expect(prefs.getString('theme_mode'), 'system');
      });
    });
  });
}
