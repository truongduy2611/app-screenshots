import 'dart:convert';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Debug-only dialog for manual copy/paste AI design assist.
///
/// Step 1: Shows the full prompt — user copies it to an external AI.
/// Step 2: User pastes the AI's JSON response back.
///
/// Returns the raw JSON string (or null on cancel).
class ManualDesignAssistDialog extends StatefulWidget {
  const ManualDesignAssistDialog({
    required this.prompt,
    required this.providerLabel,
    super.key,
  });

  /// The full prompt that would be sent to the AI.
  final String prompt;

  /// Label for the provider, e.g. "Apple FM", "Gemini", "OpenAI".
  final String providerLabel;

  /// Show the dialog and return the raw JSON response string (or null).
  static Future<String?> show({
    required BuildContext context,
    required Rect sourceRect,
    required String prompt,
    required String providerLabel,
  }) {
    return showGenieDialog<String>(
      context: context,
      sourceRect: sourceRect,
      barrierDismissible: true,
      builder: (_) => ManualDesignAssistDialog(
        prompt: prompt,
        providerLabel: providerLabel,
      ),
    );
  }

  @override
  State<ManualDesignAssistDialog> createState() =>
      _ManualDesignAssistDialogState();
}

class _ManualDesignAssistDialogState extends State<ManualDesignAssistDialog> {
  final _responseController = TextEditingController();
  bool _copied = false;
  String? _parseError;

  /// Try to extract valid JSON from pasted text.
  String? _tryParse(String raw) {
    var cleaned = raw.trim();

    // Strip markdown code fences if present.
    final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final fenceMatch = fenceRegex.firstMatch(cleaned);
    if (fenceMatch != null) {
      cleaned = fenceMatch.group(1)!.trim();
    }

    // Find the JSON object boundaries.
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1 || lastBrace <= firstBrace) {
      return null;
    }
    cleaned = cleaned.substring(firstBrace, lastBrace + 1);

    try {
      // Validate it's valid JSON
      jsonDecode(cleaned);
      return cleaned;
    } catch (_) {
      return null;
    }
  }

  void _apply() {
    final result = _tryParse(_responseController.text);
    if (result == null) {
      setState(() => _parseError = 'Could not parse valid JSON from response.');
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 580,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Icon(Symbols.bug_report_rounded, size: 20, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debug: ${widget.providerLabel} Design Assist',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Step 1: Copy Prompt ──
                _SectionHeader(
                  icon: Symbols.content_copy_rounded,
                  label: 'Step 1: Copy Prompt',
                  color: cs.primary,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.prompt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.prompt.length} chars',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.primary(
                    label: _copied ? 'Copied!' : 'Copy Prompt',
                    icon: _copied
                        ? Icons.check_rounded
                        : Symbols.content_copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.prompt),
                      );
                      setState(() => _copied = true);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 1500),
                      );
                      if (mounted) setState(() => _copied = false);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Step 2: Paste Response ──
                _SectionHeader(
                  icon: Symbols.chat_paste_go_rounded,
                  label: 'Step 2: Paste AI Response',
                  color: cs.tertiary,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _responseController,
                  maxLines: 10,
                  onChanged: (_) {
                    if (_parseError != null) {
                      setState(() => _parseError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText:
                        '{\n'
                        '  "changes": { "backgroundColor": "#0000FF" },\n'
                        '  "explanation": "Changed to blue"\n'
                        '}',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    errorText: _parseError,
                    errorMaxLines: 3,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Paste the JSON response from any AI here',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton.secondary(
                      label: 'Paste',
                      icon: Symbols.content_paste_go_rounded,
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null && mounted) {
                          _responseController.text = data!.text!;
                          setState(() => _parseError = null);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Actions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.text(
                      label: context.l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    AppButton.text(
                      label: 'Skip (use real AI)',
                      onPressed: () => Navigator.of(context).pop('__SKIP__'),
                    ),
                    const SizedBox(width: 8),
                    AppButton.primary(
                      label: 'Apply Response',
                      icon: Symbols.check_rounded,
                      onPressed: _apply,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
