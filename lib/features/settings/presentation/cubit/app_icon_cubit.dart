import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/app_icon_service.dart';
import '../../domain/repositories/settings_repository.dart';

part 'app_icon_state.dart';

class AppIconCubit extends Cubit<AppIconState> {
  final SettingsRepository _repository;
  final AppIconService _service;

  AppIconCubit(this._repository, this._service) : super(const AppIconState());

  /// Loads the persisted icon and re-applies it (needed on app launch since
  /// macOS resets the dock icon on restart).
  /// On iOS we skip re-applying because the OS persists the alternate icon
  /// and calling setAlternateIconName would show a system alert on every launch.
  Future<void> load() async {
    final iconName = await _repository.getAppIcon();
    if (!Platform.isIOS) {
      await _service.setIcon(iconName);
    }
    emit(AppIconState(iconName: iconName));
  }

  /// Switches to [iconName] (`"default"` or `"alternative"`).
  Future<void> setIcon(String iconName) async {
    await _repository.setAppIcon(iconName);
    await _service.setIcon(iconName);
    emit(AppIconState(iconName: iconName));
  }
}
