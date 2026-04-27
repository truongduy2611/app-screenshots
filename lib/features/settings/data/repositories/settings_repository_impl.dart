import 'package:app_screenshots/features/settings/domain/entities/asc_credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _themeModeKey = 'theme_mode';
  static const _appIconKey = 'app_icon';
  static const _ascKeyIdKey = 'asc_key_id';
  static const _ascIssuerIdKey = 'asc_issuer_id';
  static const _ascPrivateKeyKey = 'asc_private_key_content';
  static const _cliServerEnabledKey = 'cli_server_enabled';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  SettingsRepositoryImpl(this._prefs, this._secureStorage);

  @override
  Future<ThemeMode> getThemeMode() async {
    final value = _prefs.getString(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }

  @override
  Future<String> getAppIcon() async {
    return _prefs.getString(_appIconKey) ?? 'default';
  }

  @override
  Future<void> setAppIcon(String iconName) async {
    await _prefs.setString(_appIconKey, iconName);
  }

  @override
  Future<AscCredentials?> getAscCredentials() async {
    final keyId = await _secureStorage.read(key: _ascKeyIdKey);
    final issuerId = await _secureStorage.read(key: _ascIssuerIdKey);
    final privateKey = await _secureStorage.read(key: _ascPrivateKeyKey);

    if (keyId != null && issuerId != null) {
      return AscCredentials(
        keyId: keyId,
        issuerId: issuerId,
        privateKeyContent: privateKey,
      );
    }
    return null;
  }

  @override
  Future<void> saveAscCredentials(AscCredentials credentials) async {
    await _secureStorage.write(key: _ascKeyIdKey, value: credentials.keyId);
    await _secureStorage.write(
      key: _ascIssuerIdKey,
      value: credentials.issuerId,
    );
    if (credentials.privateKeyContent != null) {
      await _secureStorage.write(
        key: _ascPrivateKeyKey,
        value: credentials.privateKeyContent!,
      );
    } else {
      await _secureStorage.delete(key: _ascPrivateKeyKey);
    }
  }

  @override
  Future<void> clearAscCredentials() async {
    await _secureStorage.delete(key: _ascKeyIdKey);
    await _secureStorage.delete(key: _ascIssuerIdKey);
    await _secureStorage.delete(key: _ascPrivateKeyKey);
  }

  @override
  Future<bool> isCliServerEnabled() async {
    return _prefs.getBool(_cliServerEnabledKey) ?? false;
  }

  @override
  Future<void> setCliServerEnabled(bool enabled) async {
    await _prefs.setBool(_cliServerEnabledKey, enabled);
  }
}
