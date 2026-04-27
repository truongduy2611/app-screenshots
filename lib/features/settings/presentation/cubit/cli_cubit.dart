import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CliCubit extends Cubit<bool> {
  final SettingsRepository _repository;

  CliCubit(this._repository) : super(false) {
    _init();
  }

  Future<void> _init() async {
    final isEnabled = await _repository.isCliServerEnabled();
    emit(isEnabled);
  }

  Future<void> toggle(bool enabled) async {
    await _repository.setCliServerEnabled(enabled);
    emit(enabled);

    if (enabled) {
      sl<CommandServer>().start().catchError((_) {});
    } else {
      sl<CommandServer>().stop().catchError((_) {});
    }
  }
}
