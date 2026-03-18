import 'dart:io';

import 'package:app_screenshots/core/di/service_locator.dart';
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
  runApp(const App());
}
