import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/translation_bundle.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/asc_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_credentials_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_upload_sheet.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_context_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/locale_translation_card.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/translation_language_chip.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/manual_translation_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_capture_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/translation_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

part 'translation_controls.source_picker.dart';
part 'translation_controls.locale_tile.dart';
part 'translation_controls.add_languages.dart';

/// The main Translation tab in the editor controls panel.
///
/// Provides source locale selection, target locale multi-select,
/// translate button, per-locale status, inline editing, and
/// a shortcut to provider settings.
class TranslationControls extends StatefulWidget {
  const TranslationControls({super.key});

  @override
  State<TranslationControls> createState() => _TranslationControlsState();
}

class _TranslationControlsState extends State<TranslationControls> {
  String _sourceLocale = 'en';
  final Set<String> _selectedLocales = {};
  final Set<String> _pinnedLocales = {};

  /// All supported App Store Connect locales.
  static const _availableLocales = <String, String>{
    'en': 'English',
    'en-AU': 'English (Australia)',
    'en-CA': 'English (Canada)',
    'en-GB': 'English (UK)',
    'es': 'Spanish (Spain)',
    'es-MX': 'Spanish (Mexico)',
    'fr': 'French (France)',
    'fr-CA': 'French (Canada)',
    'de': 'German',
    'it': 'Italian',
    'pt-BR': 'Portuguese (Brazil)',
    'pt-PT': 'Portuguese (Portugal)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh-Hans': 'Chinese (Simplified)',
    'zh-Hant': 'Chinese (Traditional)',
    'ar': 'Arabic',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'ru': 'Russian',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'id': 'Indonesian',
    'ms': 'Malay',
    'pl': 'Polish',
    'uk': 'Ukrainian',
    'hi': 'Hindi',
    'el': 'Greek',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'he': 'Hebrew',
    'hu': 'Hungarian',
    'cs': 'Czech',
    'ro': 'Romanian',
    'sk': 'Slovak',
    'hr': 'Croatian',
    'ca': 'Catalan',
    'bg': 'Bulgarian',
  };

  /// The 20 most popular locales shown by default.
  static const _popularLocaleKeys = <String>[
    'en',
    'es',
    'fr',
    'de',
    'it',
    'pt-BR',
    'ja',
    'ko',
    'zh-Hans',
    'zh-Hant',
    'ar',
    'th',
    'vi',
    'ru',
    'tr',
    'nl',
    'hi',
    'id',
    'pl',
    'uk',
  ];

  /// Returns the locales that should be visible as chips (popular + pinned),
  /// excluding the source locale.
  List<MapEntry<String, String>> _visibleTargetEntries() {
    final visibleKeys = <String>{
      ..._popularLocaleKeys,
      ..._pinnedLocales,
      // Also include any previously-selected locales so they remain visible.
      ..._selectedLocales,
    };
    return _availableLocales.entries
        .where((e) => e.key != _sourceLocale && visibleKeys.contains(e.key))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final translationState = context.read<TranslationCubit>().state;
    if (translationState.bundle != null) {
      _sourceLocale = translationState.bundle!.sourceLocale;
      _selectedLocales.addAll(translationState.bundle!.targetLocales);
    }
  }

  Map<String, String> _collectSourceTexts() {
    final texts = <String, String>{};

    // In multi-screenshot mode, collect from ALL designs.
    MultiScreenshotCubit? multiCubit;
    try {
      multiCubit = context.read<MultiScreenshotCubit>();
    } catch (_) {
      // Not in multi-screenshot mode — fall through to single mode.
    }

    if (multiCubit != null) {
      final designs = multiCubit.state.designs;
      for (int i = 0; i < designs.length; i++) {
        for (final overlay in designs[i].overlays) {
          if (overlay.text.trim().isNotEmpty) {
            texts['$i:${overlay.id}'] = overlay.text;
          }
        }
      }
    } else {
      // Single-screenshot mode — read from the active editor.
      final editorState = context.read<ScreenshotEditorCubit>().state;
      for (final overlay in editorState.design.overlays) {
        if (overlay.text.trim().isNotEmpty) {
          texts[overlay.id] = overlay.text;
        }
      }
    }

    return texts;
  }

  /// Get a readable label for an overlay from its current text.
  ///
  /// [overlayId] may be a scoped key like `"0:uuid"` when in multi-screenshot
  /// mode, or a bare UUID in single-screenshot mode.
  String _overlayLabel(String overlayId) {
    // Try multi-screenshot lookup first (scoped key: "designIndex:uuid").
    MultiScreenshotCubit? multiCubit;
    try {
      multiCubit = context.read<MultiScreenshotCubit>();
    } catch (_) {}

    if (multiCubit != null) {
      final colonIdx = overlayId.indexOf(':');
      if (colonIdx > 0) {
        final designIdx = int.tryParse(overlayId.substring(0, colonIdx));
        final rawId = overlayId.substring(colonIdx + 1);
        if (designIdx != null && designIdx < multiCubit.state.designs.length) {
          for (final overlay in multiCubit.state.designs[designIdx].overlays) {
            if (overlay.id == rawId) {
              final text = overlay.text.trim();
              final prefix = '#${designIdx + 1} ';
              if (text.length > 20) return '$prefix${text.substring(0, 20)}…';
              return text.isNotEmpty ? '$prefix$text' : '${prefix}Text';
            }
          }
        }
      }
    }

    // Fallback: single-screenshot mode.
    final editorState = context.read<ScreenshotEditorCubit>().state;
    for (final overlay in editorState.design.overlays) {
      if (overlay.id == overlayId) {
        final text = overlay.text.trim();
        if (text.length > 24) return '${text.substring(0, 24)}…';
        return text.isNotEmpty ? text : 'Text';
      }
    }
    return 'Text';
  }

  void _translateAll() {
    final cubit = context.read<TranslationCubit>();
    final sourceTexts = _collectSourceTexts();
    if (sourceTexts.isEmpty) {
      context.showAppSnackbar(
        context.l10n.addTextOverlaysFirst,
        type: AppSnackbarType.info,
      );
      return;
    }
    if (_selectedLocales.isEmpty) {
      context.showAppSnackbar(
        context.l10n.selectAtLeastOneTargetLanguage,
        type: AppSnackbarType.info,
      );
      return;
    }

    final selectedList = _selectedLocales.toList();

    // Reuse existing bundle to preserve translations for previously-translated
    // locales. targetLocales is the UNION of existing + newly selected so the
    // LocaleSwitcher continues showing all translated locales.
    var bundle = cubit.state.bundle ?? const TranslationBundle();
    final allTargetLocales = {
      ...bundle.targetLocales,
      ...selectedList,
    }.toList();
    bundle = bundle.copyWith(
      sourceLocale: _sourceLocale,
      targetLocales: allTargetLocales,
    );
    cubit.loadBundle(bundle);

    cubit.translateAll(
      sourceTexts: sourceTexts,
      sourceLocale: _sourceLocale,
      targetLocales: selectedList,
    );
  }

  /// Manual copy-paste flow: single dialog for all selected locales.
  Future<void> _manualTranslate(BuildContext btnCtx) async {
    final cubit = context.read<TranslationCubit>();
    final sourceTexts = _collectSourceTexts();
    if (sourceTexts.isEmpty) {
      context.showAppSnackbar(
        context.l10n.addTextOverlaysFirst,
        type: AppSnackbarType.info,
      );
      return;
    }
    if (_selectedLocales.isEmpty) {
      context.showAppSnackbar(
        context.l10n.selectAtLeastOneTargetLanguage,
        type: AppSnackbarType.info,
      );
      return;
    }

    // Capture the rect BEFORE cubit.loadBundle() — otherwise the rebuild
    // invalidates btnCtx and rectFromContext returns null.
    final srcRect = rectFromContext(btnCtx);
    if (srcRect == null) return;

    final selectedList = _selectedLocales.toList();

    // Prepare the bundle (same as _translateAll).
    var bundle = cubit.state.bundle ?? const TranslationBundle();
    final allTargetLocales = {
      ...bundle.targetLocales,
      ...selectedList,
    }.toList();
    bundle = bundle.copyWith(
      sourceLocale: _sourceLocale,
      targetLocales: allTargetLocales,
    );
    cubit.loadBundle(bundle);

    if (!mounted) return;

    final result = await ManualTranslationDialog.show(
      context: context,
      sourceRect: srcRect,
      sourceTexts: sourceTexts,
      sourceLocale: _sourceLocale,
      targetLocales: selectedList,
      customPrompt: bundle.customPrompt,
    );

    if (result != null && mounted) {
      for (final entry in result.entries) {
        cubit.applyManualTranslation(entry.key, entry.value);
      }
    }
  }

  void _selectAll() {
    final visible = _visibleTargetEntries();
    setState(() {
      _selectedLocales.addAll(visible.map((e) => e.key));
    });
  }

  void _deselectAll() => setState(() => _selectedLocales.clear());

  /// Opens the ASC upload sheet after capturing locale screenshots.
  ///
  /// Checks credentials first and prompts if missing.
  Future<void> _showUploadSheet() async {
    // Capture context-dependent values upfront.
    final captureProvider = ScreenshotCaptureProvider.of(context);
    if (captureProvider == null) return;

    String? displayType;
    try {
      displayType = context.read<MultiScreenshotCubit>().displayType;
    } catch (_) {
      displayType = context
          .read<ScreenshotEditorCubit>()
          .state
          .design
          .displayType;
    }

    // 1) Check credentials — prompt dialog if missing.
    final repo = sl<SettingsRepository>();
    final creds = await repo.getAscCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await AscCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    // 2) Capture locale screenshots.
    if (!context.mounted) return;
    final localeScreenshots = await captureProvider.captureAllLocaleScreenshots(
      context,
    );

    if (!context.mounted) return;

    if (localeScreenshots == null || localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        context.l10n.failedToCaptureLocaleScreenshots,
        type: AppSnackbarType.error,
      );
      return;
    }

    // 3) Show upload sheet — pass saved app config for auto-selection.
    final savedConfig = captureProvider.ascAppConfig;

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<AscUploadCubit>()
          ..init(savedAppConfig: savedConfig, designDisplayType: displayType),
        child: Dialog(
          child: AscUploadSheet(
            localeScreenshots: localeScreenshots,
            ascAppConfig: savedConfig,
            onAppConfigChanged: captureProvider.onAscAppConfigChanged,
          ),
        ),
      ),
    );
  }

  /// Opens the "Add Languages" dialog and pins selected extras.
  Future<void> _showAddLanguagesDialog(BuildContext anchorCtx) async {
    final srcRect = rectFromContext(anchorCtx);
    if (srcRect == null) return;

    final alreadyVisible = {
      ..._popularLocaleKeys,
      ..._pinnedLocales,
      ..._selectedLocales,
      _sourceLocale,
    };

    final extras = _availableLocales.entries
        .where((e) => !alreadyVisible.contains(e.key))
        .toList();

    if (extras.isEmpty) return;

    final added = await showGenieDialog<List<String>>(
      context: context,
      sourceRect: srcRect,
      builder: (_) => _AddLanguagesDialog(extras: extras),
    );

    if (added != null && added.isNotEmpty && mounted) {
      setState(() {
        _pinnedLocales.addAll(added);
        _selectedLocales.addAll(added);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, translationState) {
        final visibleEntries = _visibleTargetEntries();
        final allSelected = visibleEntries.every(
          (e) => _selectedLocales.contains(e.key),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Provider ──
            ControlSection(
              icon: Symbols.cloud_rounded,
              title: context.l10n.provider,
              trailing: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    TranslationSettingsDialog.show(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.settings,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Symbols.chevron_right_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── App Context ──
            Builder(
              builder: (btnCtx) {
                final prompt = translationState.bundle?.customPrompt;
                return ControlSection(
                  icon: Symbols.description_rounded,
                  title: context.l10n.appContext,
                  trailing: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => AppContextDialog.show(
                        context,
                        anchorContext: btnCtx,
                        currentPrompt: prompt,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              prompt?.isNotEmpty == true
                                  ? prompt!
                                  : context.l10n.addContext,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: prompt?.isNotEmpty == true
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Symbols.chevron_right_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Source Language ──
            ControlSection(
              icon: Symbols.language_rounded,
              title: context.l10n.sourceLanguage,
            ),
            Builder(
              builder: (fieldCtx) {
                final label = _availableLocales[_sourceLocale] ?? _sourceLocale;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await _SourceLanguagePickerDialog.show(
                        context: context,
                        anchorContext: fieldCtx,
                        availableLocales: _availableLocales,
                        currentLocale: _sourceLocale,
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _selectedLocales.remove(result);
                          _sourceLocale = result;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _sourceLocale.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Symbols.unfold_more_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Target Languages ──
            ControlSection(
              icon: Symbols.translate_rounded,
              title: context.l10n.targetLanguages,
              trailing: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: allSelected ? _deselectAll : _selectAll,
                  child: Text(
                    allSelected
                        ? context.l10n.deselectAll
                        : context.l10n.selectAll,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            ControlCard(
              padding: const EdgeInsets.all(10),
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    ...visibleEntries.map((e) {
                      final isSelected = _selectedLocales.contains(e.key);
                      final status = translationState.localeStatuses[e.key];

                      return TranslationLanguageChip(
                        code: e.key,
                        name: e.value,
                        isSelected: isSelected,
                        status: status,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedLocales.remove(e.key);
                            } else {
                              _selectedLocales.add(e.key);
                            }
                          });
                        },
                      );
                    }),
                    // ── Add More button ──
                    Builder(
                      builder: (btnCtx) {
                        return Tooltip(
                          message: context.l10n.addMoreLanguages,
                          preferBelow: false,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _showAddLanguagesDialog(btnCtx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Symbols.add_rounded,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      context.l10n.more,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Translate Buttons ──
            AppButton.primary(
              label: translationState.isTranslating
                  ? context.l10n.translatingProgress(
                      translationState.completedCount,
                      translationState.bundle?.targetLocales.length ??
                          _selectedLocales.length,
                    )
                  : context.l10n.translateAll,
              icon: Symbols.translate_rounded,
              isLoading: translationState.isTranslating,
              isExpanded: true,
              onPressed: _translateAll,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (btnCtx) {
                return AppButton.secondary(
                  label: context.l10n.manualCopyPaste,
                  icon: Icons.content_paste_rounded,
                  isExpanded: true,
                  onPressed: () => _manualTranslate(btnCtx),
                );
              },
            ),

            const SizedBox(height: 8),

            // ── Upload to ASC ──
            AppButton.secondary(
              label: context.l10n.uploadToAsc,
              icon: Symbols.cloud_upload,
              isExpanded: true,
              onPressed: _showUploadSheet,
            ),

            if (translationState.errorMessage != null) ...[
              const SizedBox(height: 8),
              ControlCard(
                padding: const EdgeInsets.all(10),
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.error_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          translationState.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // ── Inline Translation Editing ──
            if (translationState.bundle != null &&
                translationState.bundle!.translations.isNotEmpty) ...[
              const SizedBox(height: 20),
              ControlSection(
                icon: Symbols.edit_note_rounded,
                title: context.l10n.editTranslations,
              ),
              ...translationState.bundle!.targetLocales.map((locale) {
                final translations =
                    translationState.bundle!.translations[locale];
                if (translations == null || translations.isEmpty) {
                  return const SizedBox.shrink();
                }

                return LocaleTranslationCard(
                  locale: locale,
                  translations: translations,
                  status: translationState.localeStatuses[locale],
                  overlayLabel: _overlayLabel,
                  onEdit: (overlayId, newText) {
                    context.read<TranslationCubit>().updateTranslation(
                      locale,
                      overlayId,
                      newText,
                    );
                  },
                  onRetry: () {
                    context.read<TranslationCubit>().retryLocale(
                      locale,
                      _collectSourceTexts(),
                    );
                  },
                  onRemove: () {
                    context.read<TranslationCubit>().removeLocale(locale);
                    setState(() => _selectedLocales.remove(locale));
                  },
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
