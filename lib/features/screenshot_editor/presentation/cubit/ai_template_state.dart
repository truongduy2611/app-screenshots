part of 'ai_template_cubit.dart';

/// Generation lifecycle status.
enum AiTemplateStatus { idle, generating, success, error }

/// State for the AI template generation cubit.
class AiTemplateState extends Equatable {
  /// The user's style description text.
  final String description;

  /// Current generation status.
  final AiTemplateStatus status;

  /// The generated preset (non-null when [status] is [AiTemplateStatus.success]).
  final ScreenshotPreset? preset;

  /// Error message (non-null when [status] is [AiTemplateStatus.error]).
  final String? errorMessage;

  const AiTemplateState({
    this.description = '',
    this.status = AiTemplateStatus.idle,
    this.preset,
    this.errorMessage,
  });

  /// Whether the description is non-empty and ready to generate.
  bool get canGenerate =>
      description.trim().isNotEmpty && status != AiTemplateStatus.generating;

  /// Whether the cubit is currently generating.
  bool get isGenerating => status == AiTemplateStatus.generating;

  AiTemplateState copyWith({
    String? description,
    AiTemplateStatus? status,
    ScreenshotPreset? preset,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiTemplateState(
      description: description ?? this.description,
      status: status ?? this.status,
      preset: preset ?? this.preset,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [description, status, preset, errorMessage];
}
