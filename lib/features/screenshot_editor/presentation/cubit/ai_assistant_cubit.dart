import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/ai_design_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/ai_assistant_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages AI design assistant chat and applies design changes.
class AiAssistantCubit extends Cubit<AiAssistantState> {
  final AiDesignService _designService;

  /// Called when the AI produces an updated design that should be applied.
  final void Function(ScreenshotDesign design) _applyDesign;

  /// Returns the current design from the editor.
  final ScreenshotDesign Function() _getCurrentDesign;

  /// Returns all designs for multi-screenshot mode (null if single mode).
  final List<ScreenshotDesign> Function()? _getAllDesigns;

  /// Applies a design to a specific slot in multi-screenshot mode.
  final void Function(int index, ScreenshotDesign design)? _applyDesignToSlot;

  AiAssistantCubit({
    required AiDesignService designService,
    required void Function(ScreenshotDesign) applyDesign,
    required ScreenshotDesign Function() getCurrentDesign,
    List<ScreenshotDesign> Function()? getAllDesigns,
    void Function(int, ScreenshotDesign)? applyDesignToSlot,
  }) : _designService = designService,
       _applyDesign = applyDesign,
       _getCurrentDesign = getCurrentDesign,
       _getAllDesigns = getAllDesigns,
       _applyDesignToSlot = applyDesignToSlot,
       super(const AiAssistantState());

  /// Whether multi-screenshot mode is available.
  bool get hasMultiMode => _getAllDesigns != null && _applyDesignToSlot != null;

  /// Send a user message and process the AI response.
  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;

    final userMessage = AiMessage(
      content: prompt,
      role: AiMessageRole.user,
      timestamp: DateTime.now(),
    );

    // Save current design for undo
    final currentDesign = _getCurrentDesign();

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        status: AiAssistantStatus.processing,
        designBeforeAi: currentDesign,
        clearError: true,
      ),
    );

    try {
      final history = _buildHistory();

      final response = await _designService.processRequest(
        currentDesign,
        prompt,
        conversationHistory: history.isNotEmpty ? history : null,
      );

      // Apply the design changes
      _applyDesign(response.updatedDesign);

      final assistantMessage = AiMessage(
        content: response.explanation,
        role: AiMessageRole.assistant,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          messages: [...state.messages, assistantMessage],
          status: AiAssistantStatus.idle,
        ),
      );
    } on AiDesignException catch (e) {
      emit(
        state.copyWith(
          status: AiAssistantStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AiAssistantStatus.error,
          errorMessage: 'Unexpected error: $e',
        ),
      );
    }
  }

  /// Send a user message and apply the AI changes to ALL screenshots.
  Future<void> sendMessageToAll(String prompt) async {
    if (prompt.trim().isEmpty) return;
    if (_getAllDesigns == null || _applyDesignToSlot == null) {
      return sendMessage(prompt);
    }

    final userMessage = AiMessage(
      content: prompt,
      role: AiMessageRole.user,
      timestamp: DateTime.now(),
    );

    final allDesigns = _getAllDesigns();
    if (allDesigns.isEmpty) return;

    // Save ALL designs for undo-all
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        status: AiAssistantStatus.processing,
        designsBeforeAi: List<ScreenshotDesign>.from(allDesigns),
        clearError: true,
      ),
    );

    final history = _buildHistory();
    int applied = 0;
    int failed = 0;

    for (int i = 0; i < allDesigns.length; i++) {
      try {
        final response = await _designService.processRequest(
          allDesigns[i],
          prompt,
          conversationHistory: history.isNotEmpty ? history : null,
        );
        _applyDesignToSlot(i, response.updatedDesign);
        applied++;
      } catch (_) {
        failed++;
      }
    }

    if (applied == 0) {
      emit(
        state.copyWith(
          status: AiAssistantStatus.error,
          errorMessage: 'Failed to apply changes to any screenshots.',
        ),
      );
      return;
    }

    final String message;
    if (failed > 0) {
      message =
          'Applied to $applied/${allDesigns.length} screenshots. $failed failed.';
    } else {
      message = 'Applied changes to $applied screenshots.';
    }

    final assistantMessage = AiMessage(
      content: message,
      role: AiMessageRole.assistant,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, assistantMessage],
        status: AiAssistantStatus.idle,
      ),
    );
  }

  /// Undo the last AI change by restoring the saved design snapshot(s).
  void undoLastChange() {
    if (!state.canUndo) return;

    // Undo bulk operation (restore all designs)
    if (state.designsBeforeAi != null && _applyDesignToSlot != null) {
      for (int i = 0; i < state.designsBeforeAi!.length; i++) {
        _applyDesignToSlot(i, state.designsBeforeAi![i]);
      }
    } else if (state.designBeforeAi != null) {
      _applyDesign(state.designBeforeAi!);
    }

    // Remove the last exchange (user message + assistant reply)
    final messages = List<AiMessage>.from(state.messages);
    if (messages.isNotEmpty && messages.last.role == AiMessageRole.assistant) {
      messages.removeLast();
    }
    if (messages.isNotEmpty && messages.last.role == AiMessageRole.user) {
      messages.removeLast();
    }

    emit(
      state.copyWith(
        messages: messages,
        clearDesignBeforeAi: true,
        status: AiAssistantStatus.idle,
        clearError: true,
      ),
    );
  }

  /// Clear all messages and reset state.
  void clearChat() {
    emit(const AiAssistantState());
  }

  List<Map<String, String>> _buildHistory() {
    return state.messages
        .take(state.messages.length > 6 ? 6 : state.messages.length)
        .map(
          (m) => {
            'role': m.role == AiMessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }
}
