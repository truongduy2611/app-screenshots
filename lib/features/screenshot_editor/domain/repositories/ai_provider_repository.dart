import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';

/// Repository interface for managing AI provider configuration.
abstract class AIProviderRepository {
  /// Retrieves the current AI provider configuration.
  Future<AIProviderConfig> getConfig();

  /// Saves the AI provider configuration.
  ///
  /// API keys are stored securely (keychain / encrypted storage).
  Future<void> saveConfig(AIProviderConfig config);

  /// Clears all AI provider configuration and stored keys.
  Future<void> clearConfig();
}
