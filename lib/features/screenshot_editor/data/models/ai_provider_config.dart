import 'package:equatable/equatable.dart';

/// Available AI provider types.
enum AIProviderType {
  /// Apple Foundation Model — on-device, no API key needed (macOS only).
  appleFM,

  /// OpenAI Chat Completions API.
  openai,

  /// Google Gemini API.
  gemini,

  /// DeepL Translate API.
  deepl,

  /// Custom OpenAI-compatible endpoint (Ollama, Together, etc.).
  custom,

  /// Manual copy-paste — user copies prompt to external AI, pastes response.
  manual,
}

/// Configuration for the active AI provider.
class AIProviderConfig extends Equatable {
  final AIProviderType activeProvider;
  final String? apiKey;
  final String? customEndpoint;
  final String? customModel;

  const AIProviderConfig({
    this.activeProvider = AIProviderType.appleFM,
    this.apiKey,
    this.customEndpoint,
    this.customModel,
  });

  AIProviderConfig copyWith({
    AIProviderType? activeProvider,
    String? apiKey,
    String? customEndpoint,
    String? customModel,
  }) {
    return AIProviderConfig(
      activeProvider: activeProvider ?? this.activeProvider,
      apiKey: apiKey ?? this.apiKey,
      customEndpoint: customEndpoint ?? this.customEndpoint,
      customModel: customModel ?? this.customModel,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeProvider': activeProvider.name,
    if (apiKey != null) 'apiKey': apiKey,
    if (customEndpoint != null) 'customEndpoint': customEndpoint,
    if (customModel != null) 'customModel': customModel,
  };

  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      activeProvider: AIProviderType.values.firstWhere(
        (e) => e.name == json['activeProvider'],
        orElse: () => AIProviderType.appleFM,
      ),
      apiKey: json['apiKey'] as String?,
      customEndpoint: json['customEndpoint'] as String?,
      customModel: json['customModel'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    activeProvider,
    apiKey,
    customEndpoint,
    customModel,
  ];
}
