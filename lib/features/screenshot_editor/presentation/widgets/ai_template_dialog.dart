import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/ai_template_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A dialog that lets the user describe a screenshot style in free text
/// and generates a [ScreenshotPreset] using AI (Apple FM or Gemini).
class AiTemplateDialog extends StatelessWidget {
  final AIProviderRepository providerRepo;

  const AiTemplateDialog({super.key, required this.providerRepo});

  /// Show the AI template dialog. Returns the generated preset on success.
  static Future<ScreenshotPreset?> show(
    BuildContext context, {
    required AIProviderRepository providerRepo,
  }) {
    return showDialog<ScreenshotPreset>(
      context: context,
      builder: (_) => AiTemplateDialog(providerRepo: providerRepo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiTemplateCubit(providerRepo),
      child: const _DialogContent(),
    );
  }
}

// =============================================================================

class _DialogContent extends StatefulWidget {
  const _DialogContent();

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const _suggestions = [
    ('🖤', 'Dark & Elegant'),
    ('🎨', 'Playful & Colorful'),
    ('⚪', 'Minimal & Clean'),
    ('🌈', 'Vivid Gradient'),
    ('💼', 'Professional Blue'),
    ('🌅', 'Warm Sunset'),
  ];

  static const _descriptions = [
    'Dark elegant style for a fitness app',
    'Playful colorful theme for a kids game',
    'Minimal white design for productivity',
    'Vibrant gradient for a social media app',
    'Professional blue for a finance app',
    'Warm sunset palette for a travel app',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      context.read<AiTemplateCubit>().updateDescription(_controller.text);
    });
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AiTemplateCubit, AiTemplateState>(
      listenWhen: (prev, curr) => curr.status == AiTemplateStatus.success,
      listener: (context, state) {
        if (state.preset != null) Navigator.pop(context, state.preset);
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width < 600
                ? MediaQuery.sizeOf(context).width - 16
                : 440,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header with gradient accent ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.08),
                      const Color(0xFFA855F7).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Symbols.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.aiGenerate,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            l10n.aiGenerateSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.close_rounded, size: 18),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.onSurface.withValues(
                          alpha: isDark ? 0.12 : 0.06,
                        ),
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        minimumSize: const Size(30, 30),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // ── Text field ──
                    BlocBuilder<AiTemplateCubit, AiTemplateState>(
                      buildWhen: (prev, curr) =>
                          prev.isGenerating != curr.isGenerating,
                      builder: (context, state) => TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 2,
                        minLines: 2,
                        enabled: !state.isGenerating,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            context.read<AiTemplateCubit>().generate(),
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: l10n.aiTemplatePromptHint,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Suggestion chips ──
                    BlocBuilder<AiTemplateCubit, AiTemplateState>(
                      buildWhen: (prev, curr) =>
                          prev.isGenerating != curr.isGenerating,
                      builder: (context, state) {
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(_suggestions.length, (i) {
                            final (emoji, label) = _suggestions[i];
                            return _SuggestionChip(
                              emoji: emoji,
                              label: label,
                              enabled: !state.isGenerating,
                              onTap: () {
                                _controller.text = _descriptions[i];
                                _controller.selection = TextSelection.collapsed(
                                  offset: _descriptions[i].length,
                                );
                              },
                            );
                          }),
                        );
                      },
                    ),

                    // ── Error message ──
                    BlocBuilder<AiTemplateCubit, AiTemplateState>(
                      buildWhen: (prev, curr) =>
                          prev.errorMessage != curr.errorMessage,
                      builder: (context, state) {
                        if (state.errorMessage == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Symbols.error_rounded,
                                  size: 14,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Generate button ──
                    BlocBuilder<AiTemplateCubit, AiTemplateState>(
                      builder: (context, state) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: FilledButton(
                            onPressed: state.canGenerate
                                ? () =>
                                      context.read<AiTemplateCubit>().generate()
                                : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF6366F1),
                              disabledBackgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.12),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: state.isGenerating
                                  ? Row(
                                      key: const ValueKey('loading'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.aiTemplateGenerating,
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      key: const ValueKey('generate'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Symbols.auto_awesome_rounded,
                                          size: 18,
                                          color: state.canGenerate
                                              ? Colors.white
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.generate,
                                          style: TextStyle(
                                            color: state.canGenerate
                                                ? Colors.white
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================

class _SuggestionChip extends StatefulWidget {
  final String emoji;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.emoji,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFF6366F1).withValues(alpha: 0.08))
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.15)),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: _hovered ? 0.8 : 0.6,
                  ),
                  fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
