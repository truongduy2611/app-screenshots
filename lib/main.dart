import 'dart:io';

import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots/app.dart';
import 'package:app_screenshots/l10n/filtering_flutter_binding.dart';
import 'package:flutter/material.dart';

void main() async {
  if (Platform.isIOS) {
    try {
      FilteringFlutterBinding();
    } catch (_) {
      // Binding already exists (e.g., during integration tests)
      WidgetsFlutterBinding.ensureInitialized();
    }
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  await initServiceLocator();

  // Start the CLI command server on desktop only if enabled.
  if (!Platform.isIOS) {
    final settingsRepo = sl<SettingsRepository>();
    final isCliEnabled = await settingsRepo.isCliServerEnabled();
    if (isCliEnabled) {
      sl<CommandServer>().start().catchError((_) {
        // Server failed to start — app continues normally without CLI support.
      });
    }
  }

  runApp(const App());
}
