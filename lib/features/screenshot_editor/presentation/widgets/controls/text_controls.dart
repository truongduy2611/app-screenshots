import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/overlay_override.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/font_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class TextControls extends StatelessWidget {
  const TextControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      builder: (context, state) {
        final cubit = context.read<ScreenshotEditorCubit>();
        final selectedId = state.selectedOverlayId;
        final selectedOverlay = selectedId != null
            ? state.design.overlays.where((e) => e.id == selectedId).firstOrNull
            : null;

        if (selectedId != null &&
            !state.design.overlays.any((e) => e.id == selectedId)) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => cubit.addTextOverlay(),
              icon: const Icon(Symbols.add_rounded),
              label: Text(context.l10n.addText),
            ),
          );
        }

        // ── Translation-aware layer ──
        return BlocBuilder<TranslationCubit, TranslationState>(
          builder: (context, tState) {
            final tCubit = context.read<TranslationCubit>();
            final previewLocale = tState.previewLocale;
            final bundle = tState.bundle;
            final isLocalePreview = previewLocale != null && bundle != null;

            // Resolve design index for scoped translation keys
            // (multi-screenshot mode stores keys as "designIndex:overlayId").
            int? designIndex;
            try {
              designIndex = context
                  .read<MultiScreenshotCubit>()
                  .state
                  .activeIndex;
            } catch (_) {}

            // Resolve per-locale override for the selected overlay.
            OverlayOverride? localeOverride;
            String? translationKey;
            if (isLocalePreview && selectedOverlay != null) {
              translationKey = designIndex != null
                  ? '$designIndex:${selectedOverlay.id}'
                  : selectedOverlay.id;
              localeOverride = bundle.getOverride(
                previewLocale,
                translationKey,
              );
            }

            // ── Effective values (override ?? base) ──
            String effectiveText = selectedOverlay?.text ?? '';
            if (isLocalePreview && selectedOverlay != null) {
              effectiveText =
                  bundle.getTranslation(previewLocale, translationKey!) ??
                  selectedOverlay.text;
            }

            // Effective styling values
            final effectiveFontSize =
                (isLocalePreview ? localeOverride?.fontSize : null) ??
                selectedOverlay?.style.fontSize ??
                14.0;
            final effectiveFontWeight =
                (isLocalePreview ? localeOverride?.fontWeight : null) ??
                selectedOverlay?.style.fontWeight;
            final effectiveFontStyle =
                (isLocalePreview ? localeOverride?.fontStyle : null) ??
                selectedOverlay?.style.fontStyle;
            final effectiveTextAlign =
                (isLocalePreview ? localeOverride?.textAlign : null) ??
                selectedOverlay?.textAlign ??
                TextAlign.center;
            final effectiveDecoration =
                (isLocalePreview ? localeOverride?.textDecoration : null) ??
                selectedOverlay?.decoration ??
                TextDecoration.none;
            final effectiveDecorationStyle =
                (isLocalePreview
                    ? localeOverride?.textDecorationStyle
                    : null) ??
                selectedOverlay?.decorationStyle ??
                TextDecorationStyle.solid;
            final effectiveDecorationColor =
                (isLocalePreview && localeOverride?.decorationColor != null
                    ? Color(localeOverride!.decorationColor!)
                    : null) ??
                selectedOverlay?.decorationColor;
            final effectiveColor =
                (isLocalePreview && localeOverride?.color != null
                    ? Color(localeOverride!.color!)
                    : null) ??
                selectedOverlay?.style.color ??
                Colors.black;
            final effectiveGoogleFont =
                (isLocalePreview ? localeOverride?.googleFont : null) ??
                selectedOverlay?.googleFont ??
                'Roboto';
            final effectiveBackgroundColor =
                (isLocalePreview && localeOverride?.backgroundColor != null
                    ? Color(localeOverride!.backgroundColor!)
                    : null) ??
                selectedOverlay?.backgroundColor;
            final effectiveBorderColor =
                (isLocalePreview && localeOverride?.borderColor != null
                    ? Color(localeOverride!.borderColor!)
                    : null) ??
                selectedOverlay?.borderColor;
            final effectiveBorderWidth =
                (isLocalePreview ? localeOverride?.borderWidth : null) ??
                selectedOverlay?.borderWidth ??
                0.0;
            final effectiveBorderRadius =
                (isLocalePreview ? localeOverride?.borderRadius : null) ??
                selectedOverlay?.borderRadius ??
                0.0;
            final effectiveHPad =
                (isLocalePreview ? localeOverride?.horizontalPadding : null) ??
                selectedOverlay?.horizontalPadding ??
                8.0;
            final effectiveVPad =
                (isLocalePreview ? localeOverride?.verticalPadding : null) ??
                selectedOverlay?.verticalPadding ??
                8.0;
            final effectiveRotation =
                (isLocalePreview ? localeOverride?.rotation : null) ??
                selectedOverlay?.rotation ??
                0.0;
            final effectiveFontWeightValue =
                (effectiveFontWeight?.value ?? 3) * 100 + 100;

            /// Helper to directly set a single override field without diffing.
            void setOverrideField(
              OverlayOverride Function(OverlayOverride) updater,
            ) {
              if (selectedOverlay == null) return;
              final oo = updater(localeOverride ?? const OverlayOverride());
              tCubit.updateOverlayOverride(previewLocale!, translationKey!, oo);
            }

            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(
                16,
              ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              children: [
                // Add button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => cubit.addTextOverlay(),
                    icon: const Icon(Symbols.add_rounded, size: 18),
                    label: Text(context.l10n.addText),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Overlay selection list
                if (state.design.overlays.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.design.overlays.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final overlay = state.design.overlays[index];
                        final isActive = overlay.id == selectedId;
                        final theme = Theme.of(context);

                        // Show translated text in the chip when previewing.
                        String chipText = overlay.text;
                        if (isLocalePreview) {
                          final chipKey = designIndex != null
                              ? '$designIndex:${overlay.id}'
                              : overlay.id;
                          chipText =
                              bundle.getTranslation(previewLocale, chipKey) ??
                              overlay.text;
                        }

                        return Material(
                          color: isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => cubit.selectOverlay(overlay.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.3),
                                  width: isActive ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                chipText.length > 20
                                    ? '${chipText.substring(0, 20)}…'
                                    : chipText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isActive
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                if (selectedOverlay != null) ...[
                  // ── Locale preview badge ──
                  if (isLocalePreview) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.translate_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              context.l10n.editingLocale(
                                previewLocale.toUpperCase(),
                              ),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Content
                  ControlSection(
                    icon: Symbols.edit_note_rounded,
                    title: context.l10n.content,
                  ),
                  ControlCard(
                    children: [
                      TextFormField(
                        key: ValueKey(
                          '${selectedOverlay.id}_${previewLocale ?? "src"}',
                        ),
                        initialValue: effectiveText,
                        decoration: InputDecoration(
                          hintText: context.l10n.enterText,
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                          isDense: true,
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        style: Theme.of(context).textTheme.bodyMedium,
                        onChanged: (val) {
                          if (isLocalePreview) {
                            tCubit.updateTranslation(
                              previewLocale,
                              translationKey!,
                              val,
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(text: val),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Typography
                  ControlSection(
                    icon: Symbols.text_fields_rounded,
                    title: context.l10n.typography,
                  ),
                  ControlCard(
                    children: [
                      // Font family picker
                      _FontFamilyPicker(
                        fontName: effectiveGoogleFont,
                        onTap: () => _showFontPicker(
                          context,
                          cubit,
                          selectedOverlay,
                          isLocalePreview: isLocalePreview,
                          onFontSelected: isLocalePreview
                              ? (font) => setOverrideField(
                                  (oo) => oo.copyWith(googleFont: font),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Alignment
                      SegmentedButton<TextAlign>(
                        segments: const [
                          ButtonSegment(
                            value: TextAlign.left,
                            icon: Icon(
                              Symbols.format_align_left_rounded,
                              size: 18,
                            ),
                          ),
                          ButtonSegment(
                            value: TextAlign.center,
                            icon: Icon(
                              Symbols.format_align_center_rounded,
                              size: 18,
                            ),
                          ),
                          ButtonSegment(
                            value: TextAlign.right,
                            icon: Icon(
                              Symbols.format_align_right_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                        selected: {effectiveTextAlign},
                        onSelectionChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) =>
                                  oo.copyWith(textAlignIndex: val.first.index),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(textAlign: val.first),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Style toggles
                      Row(
                        children: [
                          ToggleButtons(
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 36,
                            ),
                            isSelected: [
                              effectiveFontWeight == FontWeight.bold,
                              effectiveFontStyle == FontStyle.italic,
                              effectiveDecoration == TextDecoration.underline,
                            ],
                            onPressed: (i) {
                              if (isLocalePreview) {
                                _toggleStyleOverride(
                                  i,
                                  localeOverride,
                                  selectedOverlay,
                                  effectiveFontWeight,
                                  effectiveFontStyle,
                                  effectiveDecoration,
                                  (oo) => setOverrideField((_) => oo),
                                );
                              } else {
                                _toggleStyle(cubit, selectedOverlay, i);
                              }
                            },
                            children: const [
                              Icon(Symbols.format_bold_rounded, size: 18),
                              Icon(Symbols.format_italic_rounded, size: 18),
                              Icon(Symbols.format_underlined_rounded, size: 18),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Layer actions + delete
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Bring Forward',
                            icon: const Icon(
                              Symbols.flip_to_front_rounded,
                              size: 18,
                            ),
                            onPressed: () =>
                                cubit.bringSelectedOverlayForward(),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Send Backward',
                            icon: const Icon(
                              Symbols.flip_to_back_rounded,
                              size: 18,
                            ),
                            onPressed: () =>
                                cubit.sendSelectedOverlayBackward(),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: selectedOverlay.behindFrame
                                ? 'In Front of Frame'
                                : 'Behind Frame',
                            icon: Icon(
                              selectedOverlay.behindFrame
                                  ? Symbols.move_up_rounded
                                  : Symbols.move_down_rounded,
                              size: 18,
                            ),
                            onPressed: () => cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(
                                behindFrame: !selectedOverlay.behindFrame,
                              ),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: selectedOverlay.behindFrame
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              foregroundColor: selectedOverlay.behindFrame
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          IconButton.filled(
                            tooltip: context.l10n.delete,
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                            icon: const Icon(Symbols.delete_rounded, size: 18),
                            onPressed: () =>
                                cubit.deleteTextOverlay(selectedOverlay.id),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Underline decoration options
                  if (effectiveDecoration == TextDecoration.underline) ...[
                    const SizedBox(height: 12),
                    ControlCard(
                      children: [
                        Text(
                          context.l10n.decorationStyle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: TextDecorationStyle.values.map((style) {
                            return ChoiceChip(
                              mouseCursor: SystemMouseCursors.click,
                              label: Text(style.name),
                              selected: effectiveDecorationStyle == style,
                              onSelected: (selected) {
                                if (selected) {
                                  if (isLocalePreview) {
                                    setOverrideField(
                                      (oo) => oo.copyWith(
                                        decorationStyleIndex: style.index,
                                      ),
                                    );
                                  } else {
                                    cubit.updateTextOverlay(
                                      selectedOverlay.id,
                                      selectedOverlay.copyWith(
                                        decorationStyle: style,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.decorationColor,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _HexColorPicker(
                          color: effectiveDecorationColor ?? effectiveColor,
                          onColorChanged: (color) {
                            if (isLocalePreview) {
                              setOverrideField(
                                (oo) => oo.copyWith(
                                  decorationColor: color.toARGB32(),
                                ),
                              );
                            } else {
                              cubit.updateTextOverlay(
                                selectedOverlay.id,
                                selectedOverlay.copyWith(
                                  decorationColor: color,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Size & Weight
                  ControlSection(
                    icon: Symbols.format_size_rounded,
                    title: context.l10n.sizeAndWeight,
                  ),
                  ControlCard(
                    children: [
                      LabeledSlider(
                        label: context.l10n.fontSize,
                        value: effectiveFontSize,
                        min: 10,
                        max: 250,
                        suffix: 'px',
                        onChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(fontSize: val),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(
                                style: selectedOverlay.style.copyWith(
                                  fontSize: val,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      LabeledSlider(
                        label: context.l10n.fontWeight,
                        value: effectiveFontWeightValue.toDouble(),
                        min: 100,
                        max: 900,
                        divisions: 8,
                        valueLabel: 'w$effectiveFontWeightValue',
                        onChanged: (val) {
                          final index = (val / 100).round() - 1;
                          if (index >= 0 && index < FontWeight.values.length) {
                            if (isLocalePreview) {
                              setOverrideField(
                                (oo) => oo.copyWith(fontWeightIndex: index),
                              );
                            } else {
                              cubit.updateTextOverlay(
                                selectedOverlay.id,
                                selectedOverlay.copyWith(
                                  style: selectedOverlay.style.copyWith(
                                    fontWeight: FontWeight.values[index],
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      LabeledSlider(
                        label: context.l10n.rotation,
                        value: effectiveRotation,
                        min: -3.14,
                        max: 3.14,
                        valueLabel:
                            '${(effectiveRotation * 180 / 3.14).round()}°',
                        onChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(rotation: val),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(rotation: val),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Color
                  ControlSection(
                    icon: Symbols.palette_rounded,
                    title: context.l10n.color,
                  ),
                  ControlCard(
                    children: [
                      _HexColorPicker(
                        color: effectiveColor,
                        onColorChanged: (color) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(color: color.toARGB32()),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(
                                style: selectedOverlay.style.copyWith(
                                  color: color,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Border & Fill
                  ControlSection(
                    icon: Symbols.border_style_rounded,
                    title: context.l10n.borderAndFill,
                  ),
                  ControlCard(
                    children: [
                      _HexColorPicker(
                        color: effectiveBackgroundColor ?? Colors.transparent,
                        onColorChanged: (color) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(
                                backgroundColor: color.toARGB32(),
                              ),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(backgroundColor: color),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _HexColorPicker(
                        color: effectiveBorderColor ?? Colors.transparent,
                        onColorChanged: (color) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) =>
                                  oo.copyWith(borderColor: color.toARGB32()),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(borderColor: color),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      LabeledSlider(
                        label: context.l10n.borderWidth,
                        value: effectiveBorderWidth,
                        min: 0,
                        max: 20,
                        suffix: 'px',
                        onChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(borderWidth: val),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(borderWidth: val),
                            );
                          }
                        },
                      ),
                      LabeledSlider(
                        label: context.l10n.borderRadius,
                        value: effectiveBorderRadius.clamp(
                          0.0,
                          _maxBorderRadius(effectiveFontSize),
                        ),
                        min: 0,
                        max: _maxBorderRadius(effectiveFontSize),
                        suffix: 'px',
                        onChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(borderRadius: val),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(borderRadius: val),
                            );
                          }
                        },
                      ),
                      LabeledSlider(
                        label: context.l10n.horizontalPadding,
                        value: effectiveHPad,
                        min: 0,
                        max: 50,
                        suffix: 'px',
                        onChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(horizontalPadding: val),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(horizontalPadding: val),
                            );
                          }
                        },
                      ),
                      LabeledSlider(
                        label: context.l10n.verticalPadding,
                        value: effectiveVPad,
                        min: 0,
                        max: 50,
                        suffix: 'px',
                        onChanged: (val) {
                          if (isLocalePreview) {
                            setOverrideField(
                              (oo) => oo.copyWith(verticalPadding: val),
                            );
                          } else {
                            cubit.updateTextOverlay(
                              selectedOverlay.id,
                              selectedOverlay.copyWith(verticalPadding: val),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        context.l10n.selectOrAddText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  double _maxBorderRadius(double fontSize) {
    return (fontSize * 1.5 > 50) ? fontSize * 1.5 : 50.0;
  }

  void _toggleStyle(ScreenshotEditorCubit cubit, dynamic overlay, int index) {
    if (index == 0) {
      final isBold = overlay.style.fontWeight == FontWeight.bold;
      cubit.updateTextOverlay(
        overlay.id,
        overlay.copyWith(
          style: overlay.style.copyWith(
            fontWeight: isBold ? FontWeight.normal : FontWeight.bold,
          ),
        ),
      );
    } else if (index == 1) {
      final isItalic = overlay.style.fontStyle == FontStyle.italic;
      cubit.updateTextOverlay(
        overlay.id,
        overlay.copyWith(
          style: overlay.style.copyWith(
            fontStyle: isItalic ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      );
    } else if (index == 2) {
      final isUnderlined = overlay.decoration == TextDecoration.underline;
      cubit.updateTextOverlay(
        overlay.id,
        overlay.copyWith(
          decoration: isUnderlined
              ? TextDecoration.none
              : TextDecoration.underline,
        ),
      );
    }
  }

  void _toggleStyleOverride(
    int index,
    OverlayOverride? localeOverride,
    dynamic overlay,
    FontWeight? currentWeight,
    FontStyle? currentStyle,
    TextDecoration currentDecoration,
    void Function(OverlayOverride) applyOverride,
  ) {
    final oo = localeOverride ?? const OverlayOverride();
    if (index == 0) {
      final isBold = currentWeight == FontWeight.bold;
      applyOverride(
        oo.copyWith(
          fontWeightIndex: isBold
              ? FontWeight.normal.value
              : FontWeight.bold.value,
        ),
      );
    } else if (index == 1) {
      final isItalic = currentStyle == FontStyle.italic;
      applyOverride(
        oo.copyWith(
          fontStyleIndex: isItalic
              ? FontStyle.normal.index
              : FontStyle.italic.index,
        ),
      );
    } else if (index == 2) {
      final isUnderlined = currentDecoration == TextDecoration.underline;
      applyOverride(
        oo.copyWith(
          decoration: isUnderlined
              ? TextDecoration.none.toString()
              : TextDecoration.underline.toString(),
        ),
      );
    }
  }

  void _showFontPicker(
    BuildContext context,
    ScreenshotEditorCubit cubit,
    dynamic overlay, {
    bool isLocalePreview = false,
    void Function(String)? onFontSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (scrollContext, scrollController) => FontPickerSheet(
          selectedFont: overlay.googleFont ?? 'Roboto',
          onFontSelected: (font) {
            if (isLocalePreview && onFontSelected != null) {
              onFontSelected(font);
            } else {
              cubit.updateTextOverlay(
                overlay.id,
                overlay.copyWith(googleFont: font),
              );
            }
          },
        ),
      ),
    );
  }
}

class _FontFamilyPicker extends StatelessWidget {
  const _FontFamilyPicker({required this.fontName, required this.onTap});

  final String fontName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Symbols.font_download_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fontName,
                style: GoogleFonts.getFont(fontName, fontSize: 14),
              ),
            ),
            Icon(
              Symbols.expand_more_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _HexColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  const _HexColorPicker({required this.color, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(
                text: color
                    .toARGB32()
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .toUpperCase()
                    .substring(2),
              ),
              decoration: InputDecoration(
                prefixText: '# ',
                prefixStyle: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              onSubmitted: (val) {
                if (val.length == 6) {
                  final newColor = Color(int.parse('FF$val', radix: 16));
                  onColorChanged(newColor.withValues(alpha: color.a));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => showColorPickerDialog(
                context: context,
                color: color,
                onColorChanged: onColorChanged,
                enableAlpha: true,
                sourceRect: rectFromContext(context),
              ),
              child: Container(
                width: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
