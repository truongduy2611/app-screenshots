import 'dart:convert';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A dialog for the manual copy-paste translation workflow.
///
/// Generates a single prompt covering **all** target locales and expects
/// a nested JSON response:
/// ```json
/// {
///   "es": { "overlay_1": "...", "overlay_2": "..." },
///   "fr": { "overlay_1": "...", "overlay_2": "..." }
/// }
/// ```
///
/// Returns `Map<String, Map<String, String>>?` — locale → (key → text),
/// or `null` on cancel.
class ManualTranslationDialog extends StatefulWidget {
  const ManualTranslationDialog({
    required this.sourceTexts,
    required this.sourceLocale,
    required this.targetLocales,
    this.customPrompt,
    super.key,
  });

  final Map<String, String> sourceTexts;
  final String sourceLocale;
  final List<String> targetLocales;
  final String? customPrompt;

  /// Show the dialog for all target locales and return translations (or null).
  static Future<Map<String, Map<String, String>>?> show({
    required BuildContext context,
    required Rect sourceRect,
    required Map<String, String> sourceTexts,
    required String sourceLocale,
    required List<String> targetLocales,
    String? customPrompt,
  }) {
    return showGenieDialog<Map<String, Map<String, String>>>(
      context: context,
      sourceRect: sourceRect,
      barrierDismissible: true,
      builder: (_) => ManualTranslationDialog(
        sourceTexts: sourceTexts,
        sourceLocale: sourceLocale,
        targetLocales: targetLocales,
        customPrompt: customPrompt,
      ),
    );
  }

  @override
  State<ManualTranslationDialog> createState() =>
      _ManualTranslationDialogState();
}

class _ManualTranslationDialogState extends State<ManualTranslationDialog> {
  final _responseController = TextEditingController();
  bool _copied = false;
  String? _parseError;

  String get _localeList =>
      widget.targetLocales.map((l) => l.toUpperCase()).join(', ');

  /// Build a single prompt that asks for translations into all target locales.
  String get _prompt {
    final locales = widget.targetLocales.join(', ');

    final buf = StringBuffer()
      ..writeln(
        'You are a professional App Store copywriter. '
        'Translate the following marketing texts from '
        '${widget.sourceLocale} to these locales: $locales.',
      )
      ..writeln()
      ..writeln(
        'Return ONLY a valid JSON object where each top-level key is a '
        'locale code and its value is an object mapping each text key '
        'to its translation. Keep translations concise — they appear as '
        'headline text on App Store screenshots. '
        'Preserve any emoji. Do not add explanations.',
      )
      ..writeln()
      ..writeln('Example response format:')
      ..writeln('{')
      ..writeln('  "${widget.targetLocales.first}": {')
      ..writeln('    "key_1": "translated text",')
      ..writeln('    "key_2": "translated text"')
      ..writeln('  }');
    if (widget.targetLocales.length > 1) {
      buf.writeln('  // ... repeat for each locale');
    }
    buf.writeln('}');

    if (widget.customPrompt?.isNotEmpty == true) {
      buf.writeln();
      buf.writeln('App context: ${widget.customPrompt}');
    }

    buf.writeln();
    buf.writeln('Here are the texts:');
    buf.writeln(const JsonEncoder.withIndent('  ').convert(widget.sourceTexts));

    return buf.toString();
  }

  /// Try to extract a nested JSON map from the pasted text.
  ///
  /// Expected shape: `{ "locale": { "key": "value", ... }, ... }`
  ///
  /// Handles raw JSON, markdown code fences, and leading/trailing whitespace.
  Map<String, Map<String, String>>? _tryParse(String raw) {
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
      final parsed = jsonDecode(cleaned);
      if (parsed is Map) {
        final result = <String, Map<String, String>>{};
        for (final entry in parsed.entries) {
          final locale = entry.key.toString();
          final translations = entry.value;
          if (translations is Map) {
            result[locale] = translations.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            );
          }
        }
        if (result.isNotEmpty) return result;
      }
    } catch (_) {
      // Fall through
    }
    return null;
  }

  void _apply() {
    final result = _tryParse(_responseController.text);
    if (result == null || result.isEmpty) {
      setState(() => _parseError = context.l10n.couldNotParseJson);
      return;
    }

    // Validate that every requested locale is present.
    final missingLocales = widget.targetLocales
        .where((l) => !result.containsKey(l))
        .toList();
    if (missingLocales.isNotEmpty) {
      setState(
        () => _parseError = context.l10n.missingLocalesError(
          missingLocales.map((l) => l.toUpperCase()).join(', '),
        ),
      );
      return;
    }

    // Validate that every locale has all the expected keys.
    for (final locale in widget.targetLocales) {
      final translations = result[locale]!;
      final missingKeys = widget.sourceTexts.keys
          .where((k) => !translations.containsKey(k))
          .toList();
      if (missingKeys.isNotEmpty) {
        setState(
          () => _parseError = context.l10n.localeMissingKeysError(
            locale.toUpperCase(),
            missingKeys.join(', '),
          ),
        );
        return;
      }
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
          width: 520,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
                    Icon(
                      Icons.content_paste_rounded,
                      size: 20,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.manualTranslateTitle(_localeList),
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
                  label: context.l10n.step1CopyPrompt,
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
                      _prompt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.primary(
                    label: _copied
                        ? context.l10n.copied
                        : context.l10n.copyPrompt,
                    icon: _copied
                        ? Icons.check_rounded
                        : Symbols.content_copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _prompt));
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
                  label: context.l10n.step2PasteResponse,
                  color: cs.tertiary,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _responseController,
                  maxLines: 8,
                  onChanged: (_) {
                    if (_parseError != null) {
                      setState(() => _parseError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText:
                        '{\n'
                        '  "${widget.targetLocales.first}": {\n'
                        '    "overlay_1": "Translated text..."\n'
                        '  }\n'
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
                        context.l10n.pasteJsonHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton.secondary(
                      label: context.l10n.paste,
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
                    AppButton.primary(
                      label: context.l10n.applyTranslations,
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
