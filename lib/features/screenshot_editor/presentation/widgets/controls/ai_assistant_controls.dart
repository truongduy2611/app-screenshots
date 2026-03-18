import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/ai_design_service.dart';
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/ai_assistant_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/ai_assistant_state.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// AI Design Assistant sidebar tab.
///
/// Provides a chat-like interface where users describe design changes in
/// natural language and the AI applies them to the current screenshot design.
class AiAssistantControls extends StatefulWidget {
  const AiAssistantControls({super.key});

  @override
  State<AiAssistantControls> createState() => _AiAssistantControlsState();
}

class _AiAssistantControlsState extends State<AiAssistantControls> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  AiAssistantCubit? _cubit;
  bool _applyToAll = false;

  /// Build contextual suggestions based on the current design state.
  List<String> _buildContextualSuggestions(
    ScreenshotDesign design,
    BuildContext context,
  ) {
    final l10n = context.l10n;
    final suggestions = <String>[];

    // Background suggestions
    if (design.backgroundGradient == null && design.meshGradient == null) {
      suggestions.add(l10n.aiSuggestionAddGradient);
    }
    final r = (design.backgroundColor.r * 255).round();
    final g = (design.backgroundColor.g * 255).round();
    final b = (design.backgroundColor.b * 255).round();
    final isDark = (0.299 * r + 0.587 * g + 0.114 * b) < 128;
    suggestions.add(
      isDark ? l10n.aiSuggestionLightMode : l10n.aiSuggestionDarkMode,
    );

    // Doodle suggestions
    if (design.doodleSettings == null || !design.doodleSettings!.enabled) {
      suggestions.add(l10n.aiSuggestionAddDoodle);
    } else if (design.doodleSettings!.iconSource != DoodleIconSource.emoji) {
      suggestions.add(l10n.aiSuggestionEmojiDoodle);
    }

    // Text suggestions
    if (design.overlays.isEmpty) {
      suggestions.add(l10n.aiSuggestionAddHeadline);
    } else {
      final title = design.overlays.first;
      if ((title.style.fontSize ?? 70) < 80) {
        suggestions.add(l10n.aiSuggestionBiggerTitle);
      }
      if (design.overlays.length < 2) {
        suggestions.add(l10n.aiSuggestionAddSubtitle);
      }
    }

    // Frame suggestions
    if (design.frameRotation == 0) {
      suggestions.add(l10n.aiSuggestionTiltFrame);
    }
    if (design.cornerRadius == 0) {
      suggestions.add(l10n.aiSuggestionRoundCorners);
    }

    // 3D tilt suggestion
    if (design.frameRotationX == 0 && design.frameRotationY == 0) {
      suggestions.add(l10n.aiSuggestionAdd3DTilt);
    }

    // Transparent background suggestion
    if (!design.transparentBackground) {
      suggestions.add(l10n.aiSuggestionTransparentBg);
    }

    // Orientation suggestion
    if (design.orientation == Orientation.portrait) {
      suggestions.add(l10n.aiSuggestionLandscapeMode);
    }

    // Always include copywriting
    suggestions.add(l10n.aiSuggestionWriteHeadline);
    suggestions.add(l10n.aiSuggestionColorPalette);

    return suggestions;
  }

  @override
  void initState() {
    super.initState();
    _initCubit();
  }

  void _initCubit() {
    final editorCubit = context.read<ScreenshotEditorCubit>();
    final providerRepo = sl<AIProviderRepository>();

    // Try to access MultiScreenshotCubit for multi-mode
    MultiScreenshotCubit? multiCubit;
    try {
      multiCubit = context.read<MultiScreenshotCubit>();
    } catch (_) {
      // Not in multi-screenshot mode
    }

    _cubit = AiAssistantCubit(
      designService: AiDesignService(providerRepo),
      applyDesign: (design) => editorCubit.replaceDesign(design),
      getCurrentDesign: () => editorCubit.state.design,
      getAllDesigns: multiCubit != null
          ? () => multiCubit!.state.designs
          : null,
      applyDesignToSlot: multiCubit != null
          ? (index, design) => multiCubit!.updateDesignForSlot(index, design)
          : null,
    );

    // Enable debug dialog for manual copy/paste testing
    if (kDebugMode) {
      AiDesignService.debugContext = context;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _cubit?.close();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    if (_applyToAll && (_cubit?.hasMultiMode ?? false)) {
      _cubit?.sendMessageToAll(text.trim());
    } else {
      _cubit?.sendMessage(text.trim());
    }

    // Re-focus the text field after sending
    _focusNode.requestFocus();

    // Scroll to bottom after a frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cubit == null) return const SizedBox.shrink();
    final editorCubit = context.watch<ScreenshotEditorCubit>();
    final currentDesign = editorCubit.state.design;

    return BlocProvider.value(
      value: _cubit!,
      child: BlocBuilder<AiAssistantCubit, AiAssistantState>(
        builder: (context, state) {
          return Column(
            children: [
              // Clear chat header (visible when messages exist)
              if (state.messages.isNotEmpty) _buildChatHeader(context),

              // Messages + suggestions area
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState(context, currentDesign)
                    : _buildMessageList(context, state),
              ),

              // Error banner
              if (state.status == AiAssistantStatus.error &&
                  state.errorMessage != null)
                _buildErrorBanner(context, state.errorMessage!),

              // Undo bar
              if (state.canUndo && state.status == AiAssistantStatus.idle)
                _buildUndoBar(context),

              // Input bar
              _buildInputBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.auto_awesome_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.aiAssistant,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () => _cubit?.clearChat(),
              icon: Icon(
                Symbols.delete_sweep_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: context.l10n.aiAssistantClearChat,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ScreenshotDesign design) {
    final theme = Theme.of(context);
    final suggestions = _buildContextualSuggestions(design, context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.auto_awesome_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              context.l10n.aiAssistant,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              context.l10n.aiAssistantSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.aiAssistantSuggestions,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((s) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage(s),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, AiAssistantState state) {
    final theme = Theme.of(context);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount:
          state.messages.length +
          (state.status == AiAssistantStatus.processing ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator
        if (index >= state.messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.aiAssistantThinking,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        final message = state.messages[index];
        final isUser = message.role == AiMessageRole.user;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 6),
                  child: Icon(
                    Symbols.auto_awesome_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    message.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Symbols.error_rounded, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUndoBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton.icon(
                onPressed: () => _cubit?.undoLastChange(),
                icon: const Icon(Symbols.undo_rounded, size: 16),
                label: Text(context.l10n.aiAssistantUndo),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  textStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AiAssistantState state) {
    final theme = Theme.of(context);
    final isProcessing = state.status == AiAssistantStatus.processing;
    final showMultiToggle = _cubit?.hasMultiMode ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Apply to all screenshots toggle
        if (showMultiToggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: Checkbox(
                    value: _applyToAll,
                    onChanged: (v) => setState(() => _applyToAll = v ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _applyToAll = !_applyToAll),
                  child: Text(
                    context.l10n.aiAssistantApplyToAll,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FocusScope(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !isProcessing,
                      style: theme.textTheme.bodySmall,
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: isProcessing ? null : _sendMessage,
                      decoration: InputDecoration(
                        hintText: context.l10n.aiAssistantHint,
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: MouseRegion(
                  cursor: isProcessing
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isProcessing
                          ? Colors.transparent
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: isProcessing
                          ? null
                          : () => _sendMessage(_textController.text),
                      icon: isProcessing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Symbols.arrow_upward_rounded,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
