import 'package:app_screenshots/features/settings/domain/entities/asc_credentials.dart';
import 'package:app_screenshots/features/settings/domain/entities/play_credentials.dart';
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

  /// Returns the stored Google Play service-account credentials, or `null`
  /// if not configured.
  Future<PlayCredentials?> getPlayCredentials();

  /// Persists Google Play service-account credentials to secure storage.
  Future<void> savePlayCredentials(PlayCredentials credentials);

  /// Clears stored Google Play credentials.
  Future<void> clearPlayCredentials();

  /// Returns the last-used Google Play package name, or `null`.
  Future<String?> getPlayPackageName();

  /// Persists the last-used Google Play package name as the default.
  Future<void> setPlayPackageName(String packageName);

  /// Returns whether the CLI local server should be started.
  Future<bool> isCliServerEnabled();

  /// Persists the CLI server enabled state.
  Future<void> setCliServerEnabled(bool enabled);
}
