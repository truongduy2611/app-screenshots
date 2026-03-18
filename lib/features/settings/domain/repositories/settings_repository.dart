import 'package:app_screenshots/features/settings/domain/entities/asc_credentials.dart';
import 'package:flutter/material.dart';

/// Repository interface for app settings persistence.
abstract class SettingsRepository {
  /// Returns the stored [ThemeMode]. Defaults to [ThemeMode.system].
  Future<ThemeMode> getThemeMode();

  /// Persists the selected [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode);

  /// Returns the stored app icon name. Defaults to `"default"`.
  Future<String> getAppIcon();

  /// Persists the selected app icon name.
  Future<void> setAppIcon(String iconName);

  /// Returns the stored ASC API credentials, or `null` if not configured.
  Future<AscCredentials?> getAscCredentials();

  /// Persists ASC API credentials to secure storage.
  Future<void> saveAscCredentials(AscCredentials credentials);

  /// Clears stored ASC API credentials.
  Future<void> clearAscCredentials();
}
