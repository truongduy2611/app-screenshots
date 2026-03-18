import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of [AIProviderRepository].
///
/// Uses [SharedPreferences] for non-sensitive config (active provider type)
/// and [FlutterSecureStorage] for API keys.
class AIProviderRepositoryImpl implements AIProviderRepository {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const _providerKey = 'translation_active_provider';
  static const _apiKeyKey = 'translation_api_key';
  static const _customEndpointKey = 'translation_custom_endpoint';
  static const _customModelKey = 'translation_custom_model';

  AIProviderRepositoryImpl(this._prefs, this._secureStorage);

  @override
  Future<AIProviderConfig> getConfig() async {
    final providerName = _prefs.getString(_providerKey);
    final activeProvider = providerName != null
        ? AIProviderType.values.firstWhere(
            (e) => e.name == providerName,
            orElse: () => AIProviderType.appleFM,
          )
        : AIProviderType.appleFM;

    final apiKey = await _secureStorage.read(key: _apiKeyKey);
    final customEndpoint = _prefs.getString(_customEndpointKey);
    final customModel = _prefs.getString(_customModelKey);

    return AIProviderConfig(
      activeProvider: activeProvider,
      apiKey: apiKey,
      customEndpoint: customEndpoint,
      customModel: customModel,
    );
  }

  @override
  Future<void> saveConfig(AIProviderConfig config) async {
    await _prefs.setString(_providerKey, config.activeProvider.name);

    if (config.apiKey != null) {
      await _secureStorage.write(key: _apiKeyKey, value: config.apiKey);
    } else {
      await _secureStorage.delete(key: _apiKeyKey);
    }

    if (config.customEndpoint != null) {
      await _prefs.setString(_customEndpointKey, config.customEndpoint!);
    } else {
      await _prefs.remove(_customEndpointKey);
    }

    if (config.customModel != null) {
      await _prefs.setString(_customModelKey, config.customModel!);
    } else {
      await _prefs.remove(_customModelKey);
    }
  }

  @override
  Future<void> clearConfig() async {
    await _prefs.remove(_providerKey);
    await _prefs.remove(_customEndpointKey);
    await _prefs.remove(_customModelKey);
    await _secureStorage.delete(key: _apiKeyKey);
  }
}
