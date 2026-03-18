import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:equatable/equatable.dart';

/// Status of the AI assistant.
enum AiAssistantStatus { idle, processing, error }

/// Role of a message in the chat.
enum AiMessageRole { user, assistant }

/// A single message in the AI assistant chat.
class AiMessage extends Equatable {
  final String content;
  final AiMessageRole role;
  final DateTime timestamp;

  const AiMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [content, role, timestamp];
}

/// State for the AI assistant cubit.
class AiAssistantState extends Equatable {
  final List<AiMessage> messages;
  final AiAssistantStatus status;
  final String? errorMessage;

  /// Snapshot of the design before the last AI change, for undo.
  final ScreenshotDesign? designBeforeAi;

  /// Snapshot of ALL designs before the last bulk AI change, for undo-all.
  final List<ScreenshotDesign>? designsBeforeAi;

  const AiAssistantState({
    this.messages = const [],
    this.status = AiAssistantStatus.idle,
    this.errorMessage,
    this.designBeforeAi,
    this.designsBeforeAi,
  });

  bool get canUndo => designBeforeAi != null || designsBeforeAi != null;

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    AiAssistantStatus? status,
    String? errorMessage,
    ScreenshotDesign? designBeforeAi,
    List<ScreenshotDesign>? designsBeforeAi,
    bool clearDesignBeforeAi = false,
    bool clearError = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      designBeforeAi: clearDesignBeforeAi
          ? null
          : (designBeforeAi ?? this.designBeforeAi),
      designsBeforeAi: clearDesignBeforeAi
          ? null
          : (designsBeforeAi ?? this.designsBeforeAi),
    );
  }

  @override
  List<Object?> get props => [
    messages,
    status,
    errorMessage,
    designBeforeAi,
    designsBeforeAi,
  ];
}
