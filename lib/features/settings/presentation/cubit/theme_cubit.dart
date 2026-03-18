import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsRepository _repository;

  ThemeCubit(this._repository) : super(const ThemeState());

  Future<void> loadTheme() async {
    final themeMode = await _repository.getThemeMode();
    emit(ThemeState(themeMode: themeMode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    emit(ThemeState(themeMode: mode));
  }
}
