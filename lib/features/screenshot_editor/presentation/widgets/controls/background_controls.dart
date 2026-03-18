import 'dart:io';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_chip.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_color_picker.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_segmented_control.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/gradient_editor.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/gradient_presets.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/icon_picker_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class BackgroundControls extends StatelessWidget {
  const BackgroundControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      builder: (context, state) {
        final isGradient =
            state.design.backgroundGradient != null ||
            state.design.meshGradient != null;
        final isTransparent = state.design.transparentBackground;
        final cubit = context.read<ScreenshotEditorCubit>();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Color section
            ControlSection(
              icon: Symbols.palette_rounded,
              title: context.l10n.backgroundColor,
            ),

            // Transparent toggle
            ControlCard(
                children: [
                  Row(
                    children: [
                      const Icon(Symbols.texture_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.transparent,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Spacer(),
                      AppSwitch(
                        value: isTransparent,
                        onChanged: (value) {
                          cubit.updateTransparentBackground(value);
                          if (value) {
                            cubit.updateBackgroundGradient(null);
                          }
                        },
                      ),
                    ],
                  ),
                ],
            ),

            // Color / Gradient controls (hidden when transparent)
            if (!isTransparent) ...[
              const SizedBox(height: 12),
              AppSegmentedControl<bool>(
                value: isGradient,
                items: [
                  AppSegment(value: false, label: context.l10n.solid),
                  AppSegment(value: true, label: context.l10n.gradient),
                ],
                onChanged: (useGradient) {
                  if (useGradient) {
                    cubit.updateBackgroundColor(Colors.black87);
                    cubit.updateBackgroundGradient(
                      GradientPresets.linearPresets.first,
                    );
                  } else {
                    cubit.updateBackgroundGradient(null);
                    cubit.updateMeshGradient(null);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Color / Gradient editor
              if (!isGradient)
                AppColorPicker(
                  color: state.design.backgroundColor,
                  onColorChanged: cubit.updateBackgroundColor,
                  onEditStart: cubit.beginBatchEdit,
                  onEditEnd: cubit.endBatchEdit,
                )
              else
                GradientEditor(
                  gradient: state.design.backgroundGradient,
                  meshGradient: state.design.meshGradient,
                  onGradientChanged: cubit.updateBackgroundGradient,
                  onMeshGradientChanged: cubit.updateMeshGradient,
                ),
            ],

            const SizedBox(height: 20),

            // Padding section
            ControlSection(
              icon: Symbols.padding_rounded,
              title: context.l10n.padding,
            ),
            ControlCard(
              children: [
                LabeledSlider(
                  label: context.l10n.padding,
                  value: state.design.padding,
                  min: 0,
                  max: 400,
                  suffix: 'px',
                  onChanged: cubit.updatePadding,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Images section
            ControlSection(
              icon: Symbols.image_rounded,
              title: context.l10n.images,
              trailing: Text(
                '${state.design.imageOverlays.length}/10',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ControlCard(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.design.imageOverlays.length >= 10
                        ? null
                        : () => _pickImageOverlay(context),
                    icon: const Icon(
                      Symbols.add_photo_alternate_rounded,
                      size: 18,
                    ),
                    label: Text(context.l10n.addImage),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (state.design.imageOverlays.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.design.imageOverlays
                        .where((o) => o.filePath != null)
                        .map((overlay) {
                          final isSelected =
                              state.selectedOverlayId == overlay.id;
                          return _ImageThumbnail(
                            filePath: overlay.filePath!,
                            isSelected: isSelected,
                            onTap: () => cubit.selectOverlay(overlay.id),
                            onDelete: () =>
                                cubit.deleteImageOverlay(overlay.id),
                          );
                        })
                        .toList(),
                  ),
                ],
                // ── Layer controls for selected image ──
                ..._buildImageExtraControls(context, state, cubit),
              ],
            ),

            const SizedBox(height: 20),

            // Icons section
            ControlSection(
              icon: Symbols.add_reaction_rounded,
              title: context.l10n.icons,
              trailing: Text(
                '${state.design.iconOverlays.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ControlCard(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickIcon(context),
                    icon: const Icon(Symbols.add_rounded, size: 18),
                    label: Text(context.l10n.addIcon),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (state.design.iconOverlays.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.design.iconOverlays.map((overlay) {
                      final isSelected = state.selectedOverlayId == overlay.id;
                      return _IconThumbnail(
                        codePoint: overlay.codePoint,
                        fontFamily: overlay.fontFamily,
                        fontPackage: overlay.fontPackage,
                        iconColor: overlay.color,
                        isSelected: isSelected,
                        onTap: () => cubit.selectOverlay(overlay.id),
                        onDelete: () => cubit.deleteIconOverlay(overlay.id),
                      );
                    }).toList(),
                  ),
                ],
                // ── Color editor for selected icon ──
                ..._buildIconColorControls(context, state, cubit),
              ],
            ),

            const SizedBox(height: 20),

            // Magnifier section
            ControlSection(
              icon: Symbols.search_rounded,
              title: 'Magnifier',
              trailing: Text(
                '${state.design.magnifierOverlays.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ControlCard(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => cubit.addMagnifierOverlay(),
                    icon: const Icon(Symbols.add_rounded, size: 18),
                    label: const Text('Add Magnifier'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                ..._buildMagnifierControls(context, state, cubit),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildImageExtraControls(
    BuildContext context,
    ScreenshotEditorState state,
    ScreenshotEditorCubit cubit,
  ) {
    final selectedId = state.selectedOverlayId;
    if (selectedId == null) return [];
    final imgIdx = state.design.imageOverlays.indexWhere(
      (o) => o.id == selectedId,
    );
    if (imgIdx == -1) return [];

    final overlay = state.design.imageOverlays[imgIdx];
    final theme = Theme.of(context);

    return [
      const SizedBox(height: 12),
      Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      const SizedBox(height: 10),
      // ── Layer controls ──
      Row(
        children: [
          Text(
            'Layer',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Bring Forward',
            icon: const Icon(Symbols.flip_to_front_rounded, size: 18),
            onPressed: () => cubit.bringSelectedOverlayForward(),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Send Backward',
            icon: const Icon(Symbols.flip_to_back_rounded, size: 18),
            onPressed: () => cubit.sendSelectedOverlayBackward(),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: overlay.behindFrame ? 'In Front of Frame' : 'Behind Frame',
            icon: Icon(
              overlay.behindFrame
                  ? Symbols.move_up_rounded
                  : Symbols.move_down_rounded,
              size: 18,
            ),
            onPressed: () => cubit.updateImageOverlay(
              overlay.id,
              overlay.copyWith(behindFrame: !overlay.behindFrame),
            ),
            style: IconButton.styleFrom(
              backgroundColor: overlay.behindFrame
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: overlay.behindFrame
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // ── Opacity ──
      LabeledSlider(
        label: 'Opacity',
        value: overlay.opacity * 100,
        min: 0,
        max: 100,
        suffix: '%',
        onChanged: (v) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(opacity: v / 100),
        ),
      ),
      const SizedBox(height: 4),
      // ── Scale ──
      LabeledSlider(
        label: 'Scale',
        value: overlay.scale * 100,
        min: 10,
        max: 500,
        suffix: '%',
        onChanged: (v) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(scale: v / 100),
        ),
      ),
      const SizedBox(height: 4),
      // ── Corner Radius ──
      LabeledSlider(
        label: 'Corner Radius',
        value: overlay.cornerRadius,
        min: 0,
        max: 100,
        suffix: 'px',
        onChanged: (v) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(cornerRadius: v),
        ),
      ),
      const SizedBox(height: 8),
      // ── Flip ──
      Row(
        children: [
          Text(
            'Flip',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Flip Horizontal',
            isSelected: overlay.flipHorizontal,
            icon: const Icon(Symbols.flip_rounded, size: 18),
            onPressed: () => cubit.updateImageOverlay(
              overlay.id,
              overlay.copyWith(flipHorizontal: !overlay.flipHorizontal),
            ),
            style: IconButton.styleFrom(
              backgroundColor: overlay.flipHorizontal
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: overlay.flipHorizontal
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Flip Vertical',
            isSelected: overlay.flipVertical,
            icon: Transform.rotate(
              angle: 1.5708,
              child: const Icon(Symbols.flip_rounded, size: 18),
            ),
            onPressed: () => cubit.updateImageOverlay(
              overlay.id,
              overlay.copyWith(flipVertical: !overlay.flipVertical),
            ),
            style: IconButton.styleFrom(
              backgroundColor: overlay.flipVertical
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: overlay.flipVertical
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // ── Shadow ──
      _buildShadowControls(
        context: context,
        shadowColor: overlay.shadowColor,
        shadowBlurRadius: overlay.shadowBlurRadius,
        shadowOffset: overlay.shadowOffset,
        onShadowColorChanged: (c) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(shadowColor: c),
        ),
        onShadowBlurChanged: (v) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(shadowBlurRadius: v),
        ),
        onShadowOffsetXChanged: (v) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(shadowOffset: Offset(v, overlay.shadowOffset.dy)),
        ),
        onShadowOffsetYChanged: (v) => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(shadowOffset: Offset(overlay.shadowOffset.dx, v)),
        ),
        onClearShadow: () => cubit.updateImageOverlay(
          overlay.id,
          overlay.copyWith(
            clearShadowColor: true,
            shadowBlurRadius: 0,
            shadowOffset: Offset.zero,
          ),
        ),
        cubit: cubit,
      ),
    ];
  }

  List<Widget> _buildIconColorControls(
    BuildContext context,
    ScreenshotEditorState state,
    ScreenshotEditorCubit cubit,
  ) {
    final selectedId = state.selectedOverlayId;
    if (selectedId == null) return [];
    final iconIdx = state.design.iconOverlays.indexWhere(
      (o) => o.id == selectedId,
    );
    if (iconIdx == -1) return [];

    final overlay = state.design.iconOverlays[iconIdx];
    final theme = Theme.of(context);

    return [
      const SizedBox(height: 12),
      Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      const SizedBox(height: 10),
      // ── Layer + Color ──
      Row(
        children: [
          Text(
            context.l10n.iconColor,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Bring Forward',
            icon: const Icon(Symbols.flip_to_front_rounded, size: 18),
            onPressed: () => cubit.bringSelectedOverlayForward(),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Send Backward',
            icon: const Icon(Symbols.flip_to_back_rounded, size: 18),
            onPressed: () => cubit.sendSelectedOverlayBackward(),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: overlay.behindFrame ? 'In Front of Frame' : 'Behind Frame',
            icon: Icon(
              overlay.behindFrame
                  ? Symbols.move_up_rounded
                  : Symbols.move_down_rounded,
              size: 18,
            ),
            onPressed: () => cubit.updateIconOverlay(
              overlay.id,
              overlay.copyWith(behindFrame: !overlay.behindFrame),
            ),
            style: IconButton.styleFrom(
              backgroundColor: overlay.behindFrame
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: overlay.behindFrame
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          // Current color swatch
          GestureDetector(
            onTap: () => showColorPickerDialog(
              context: context,
              color: overlay.color,
              onColorChanged: (c) => cubit.updateIconOverlay(
                overlay.id,
                overlay.copyWith(color: c),
              ),
              sourceRect: rectFromContext(context),
              onEditStart: cubit.beginBatchEdit,
              onEditEnd: cubit.endBatchEdit,
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: overlay.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // ── Quick color presets ──
      SizedBox(
        height: 28,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _iconQuickColors.map((c) {
            final sel = c == overlay.color;
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: () => cubit.updateIconOverlay(
                  overlay.id,
                  overlay.copyWith(color: c),
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),
      // ── Opacity ──
      LabeledSlider(
        label: 'Opacity',
        value: overlay.opacity * 100,
        min: 0,
        max: 100,
        suffix: '%',
        onChanged: (v) => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(opacity: v / 100),
        ),
      ),
      const SizedBox(height: 4),
      // ── Size ──
      LabeledSlider(
        label: 'Size',
        value: overlay.size,
        min: 20,
        max: 300,
        suffix: 'px',
        onChanged: (v) =>
            cubit.updateIconOverlay(overlay.id, overlay.copyWith(size: v)),
      ),
      const SizedBox(height: 4),
      // ── Background Color ──
      Row(
        children: [
          Text(
            'Background',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (overlay.backgroundColor != null)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Symbols.close_rounded, size: 16),
              onPressed: () => cubit.updateIconOverlay(
                overlay.id,
                overlay.copyWith(clearBackground: true),
              ),
              visualDensity: VisualDensity.compact,
            ),
          GestureDetector(
            onTap: () => showColorPickerDialog(
              context: context,
              color: overlay.backgroundColor ?? Colors.black,
              onColorChanged: (c) => cubit.updateIconOverlay(
                overlay.id,
                overlay.copyWith(backgroundColor: c),
              ),
              sourceRect: rectFromContext(context),
              onEditStart: cubit.beginBatchEdit,
              onEditEnd: cubit.endBatchEdit,
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: overlay.backgroundColor ?? Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: overlay.backgroundColor == null
                  ? Icon(
                      Symbols.add_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      // ── Border Radius ──
      LabeledSlider(
        label: 'Border Radius',
        value: overlay.borderRadius,
        min: 0,
        max: 100,
        suffix: 'px',
        onChanged: (v) => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(borderRadius: v),
        ),
      ),
      const SizedBox(height: 4),
      // ── Padding ──
      LabeledSlider(
        label: 'Padding',
        value: overlay.padding,
        min: 0,
        max: 60,
        suffix: 'px',
        onChanged: (v) =>
            cubit.updateIconOverlay(overlay.id, overlay.copyWith(padding: v)),
      ),
      const SizedBox(height: 8),
      // ── Shadow ──
      _buildShadowControls(
        context: context,
        shadowColor: overlay.shadowColor,
        shadowBlurRadius: overlay.shadowBlurRadius,
        shadowOffset: overlay.shadowOffset,
        onShadowColorChanged: (c) => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(shadowColor: c),
        ),
        onShadowBlurChanged: (v) => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(shadowBlurRadius: v),
        ),
        onShadowOffsetXChanged: (v) => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(shadowOffset: Offset(v, overlay.shadowOffset.dy)),
        ),
        onShadowOffsetYChanged: (v) => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(shadowOffset: Offset(overlay.shadowOffset.dx, v)),
        ),
        onClearShadow: () => cubit.updateIconOverlay(
          overlay.id,
          overlay.copyWith(
            clearShadowColor: true,
            shadowBlurRadius: 0,
            shadowOffset: Offset.zero,
          ),
        ),
        cubit: cubit,
      ),
    ];
  }

  /// Shared shadow controls for both image and icon overlays.
  Widget _buildShadowControls({
    required BuildContext context,
    required Color? shadowColor,
    required double shadowBlurRadius,
    required Offset shadowOffset,
    required ValueChanged<Color> onShadowColorChanged,
    required ValueChanged<double> onShadowBlurChanged,
    required ValueChanged<double> onShadowOffsetXChanged,
    required ValueChanged<double> onShadowOffsetYChanged,
    required VoidCallback onClearShadow,
    required ScreenshotEditorCubit cubit,
  }) {
    final theme = Theme.of(context);
    final hasShadow = shadowColor != null && shadowBlurRadius > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Shadow',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (hasShadow)
              IconButton(
                tooltip: 'Clear Shadow',
                icon: const Icon(Symbols.close_rounded, size: 16),
                onPressed: onClearShadow,
                visualDensity: VisualDensity.compact,
              ),
            GestureDetector(
              onTap: () => showColorPickerDialog(
                context: context,
                color: shadowColor ?? Colors.black54,
                onColorChanged: (c) {
                  onShadowColorChanged(c);
                  if (shadowBlurRadius == 0) onShadowBlurChanged(10);
                },
                sourceRect: rectFromContext(context),
                onEditStart: cubit.beginBatchEdit,
                onEditEnd: cubit.endBatchEdit,
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: shadowColor ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: shadowColor == null
                    ? Icon(
                        Symbols.add_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
          ],
        ),
        if (hasShadow) ...[
          LabeledSlider(
            label: 'Blur',
            value: shadowBlurRadius,
            min: 0,
            max: 100,
            suffix: 'px',
            onChanged: onShadowBlurChanged,
          ),
          LabeledSlider(
            label: 'X Offset',
            value: shadowOffset.dx,
            min: -50,
            max: 50,
            suffix: 'px',
            onChanged: onShadowOffsetXChanged,
          ),
          LabeledSlider(
            label: 'Y Offset',
            value: shadowOffset.dy,
            min: -50,
            max: 50,
            suffix: 'px',
            onChanged: onShadowOffsetYChanged,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildMagnifierControls(
    BuildContext context,
    ScreenshotEditorState state,
    ScreenshotEditorCubit cubit,
  ) {
    final selectedId = state.selectedOverlayId;
    if (selectedId == null) return [];

    final overlay = state.design.magnifierOverlays
        .where((e) => e.id == selectedId)
        .firstOrNull;
    if (overlay == null) return [];

    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall;
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface,
    );

    final canvasSize = ScreenshotUtils.getDimensions(
      state.design.displayType ?? '',
      state.design.orientation,
    );

    return [
      const Divider(height: 24),

      // Shape selector
      Text(context.l10n.magnifierShapeLabel, style: labelStyle),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: MagnifierShape.values.map((s) {
          final selected = overlay.shape == s;
          final label = switch (s) {
            MagnifierShape.circle => context.l10n.magnifierShapeCircle,
            MagnifierShape.roundedRectangle =>
              context.l10n.magnifierShapeRounded,
            MagnifierShape.star => context.l10n.magnifierShapeStar,
            MagnifierShape.hexagon => context.l10n.magnifierShapeHexagon,
            MagnifierShape.diamond => context.l10n.magnifierShapeDiamond,
            MagnifierShape.heart => context.l10n.magnifierShapeHeart,
          };
          final icon = switch (s) {
            MagnifierShape.circle => Icons.circle_outlined,
            MagnifierShape.roundedRectangle => Icons.rounded_corner,
            MagnifierShape.star => Icons.star_outline,
            MagnifierShape.hexagon => Icons.hexagon_outlined,
            MagnifierShape.diamond => Icons.diamond_outlined,
            MagnifierShape.heart => Icons.favorite_outline,
          };
          return AppChip(
            label: label,
            icon: icon,
            isSelected: selected,
            compact: true,
            onTap: () => cubit.updateMagnifierOverlay(
              overlay.id,
              overlay.copyWith(shape: s),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),

      // Corner radius (for rounded rectangle only)
      if (overlay.shape == MagnifierShape.roundedRectangle) ...[
        Text(
          context.l10n.magnifierCorner(overlay.cornerRadius.toInt()),
          style: labelStyle,
        ),
        Slider(
          value: overlay.cornerRadius,
          min: 0,
          max: 100,
          divisions: 20,
          label: '${overlay.cornerRadius.toInt()}',
          onChanged: (v) => cubit.updateMagnifierOverlay(
            overlay.id,
            overlay.copyWith(cornerRadius: v),
          ),
        ),
      ],

      // Star points (for star only)
      if (overlay.shape == MagnifierShape.star) ...[
        Text(
          context.l10n.magnifierPoints(overlay.starPoints),
          style: labelStyle,
        ),
        Slider(
          value: overlay.starPoints.toDouble(),
          min: 3,
          max: 12,
          divisions: 9,
          label: '${overlay.starPoints}',
          onChanged: (v) => cubit.updateMagnifierOverlay(
            overlay.id,
            overlay.copyWith(starPoints: v.round()),
          ),
        ),
      ],

      // Zoom level
      Text(
        context.l10n.magnifierZoom(overlay.zoomLevel.toStringAsFixed(1)),
        style: labelStyle,
      ),
      Slider(
        value: overlay.zoomLevel,
        min: 1.5,
        max: 5.0,
        divisions: 14,
        label: '${overlay.zoomLevel.toStringAsFixed(1)}×',
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(zoomLevel: v),
        ),
      ),

      // Width
      Text(
        context.l10n.magnifierWidth(overlay.width.toInt()),
        style: labelStyle,
      ),
      Slider(
        value: overlay.width,
        min: 40,
        max: canvasSize.width,
        divisions: 116,
        label: '${overlay.width.toInt()}',
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(width: v),
        ),
      ),

      // Height
      Text(
        context.l10n.magnifierHeight(overlay.height.toInt()),
        style: labelStyle,
      ),
      Slider(
        value: overlay.height,
        min: 40,
        max: canvasSize.height,
        divisions: 116,
        label: '${overlay.height.toInt()}',
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(height: v),
        ),
      ),

      // Border width
      Text(
        context.l10n.magnifierBorder(overlay.borderWidth.toStringAsFixed(1)),
        style: labelStyle,
      ),
      Slider(
        value: overlay.borderWidth,
        min: 0,
        max: 10,
        divisions: 20,
        label: overlay.borderWidth.toStringAsFixed(1),
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(borderWidth: v),
        ),
      ),

      // Source offset X
      Text(
        context.l10n.magnifierSourceX(overlay.sourceOffset.dx.toInt()),
        style: labelStyle,
      ),
      Slider(
        value: overlay.sourceOffset.dx,
        min: -canvasSize.width,
        max: canvasSize.width,
        label: '${overlay.sourceOffset.dx.toInt()}',
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(sourceOffset: Offset(v, overlay.sourceOffset.dy)),
        ),
      ),

      // Source offset Y
      Text(
        context.l10n.magnifierSourceY(overlay.sourceOffset.dy.toInt()),
        style: labelStyle,
      ),
      Slider(
        value: overlay.sourceOffset.dy,
        min: -canvasSize.height,
        max: canvasSize.height,
        label: '${overlay.sourceOffset.dy.toInt()}',
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(sourceOffset: Offset(overlay.sourceOffset.dx, v)),
        ),
      ),

      // Opacity
      Text(
        context.l10n.magnifierOpacity((overlay.opacity * 100).toInt()),
        style: labelStyle,
      ),
      Slider(
        value: overlay.opacity,
        min: 0.1,
        max: 1.0,
        divisions: 9,
        label: '${(overlay.opacity * 100).toInt()}%',
        onChanged: (v) => cubit.updateMagnifierOverlay(
          overlay.id,
          overlay.copyWith(opacity: v),
        ),
      ),

      const SizedBox(height: 8),
      // Actions row
      Row(
        children: [
          IconButton(
            icon: const Icon(Symbols.flip_to_front_rounded, size: 20),
            tooltip: context.l10n.bringForward,
            onPressed: cubit.bringSelectedOverlayForward,
            style: buttonStyle,
          ),
          IconButton(
            icon: const Icon(Symbols.flip_to_back_rounded, size: 20),
            tooltip: context.l10n.sendBackward,
            onPressed: cubit.sendSelectedOverlayBackward,
            style: buttonStyle,
          ),
          IconButton(
            icon: Icon(
              overlay.behindFrame
                  ? Symbols.layers_rounded
                  : Symbols.layers_clear_rounded,
              size: 20,
            ),
            tooltip: overlay.behindFrame
                ? context.l10n.inFrontOfFrame
                : context.l10n.behindFrame,
            onPressed: () => cubit.updateMagnifierOverlay(
              overlay.id,
              overlay.copyWith(behindFrame: !overlay.behindFrame),
            ),
            style: buttonStyle,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Symbols.delete_rounded, size: 20),
            tooltip: context.l10n.delete,
            onPressed: () => cubit.deleteMagnifierOverlay(overlay.id),
            style: buttonStyle,
          ),
        ],
      ),
    ];
  }

  Future<void> _pickImageOverlay(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      context.read<ScreenshotEditorCubit>().addImageOverlay(
        File(result.files.single.path!),
      );
    }
  }

  Future<void> _pickIcon(BuildContext context) async {
    final result = await IconPickerDialog.show(
      context,
      sourceRect: rectFromContext(context),
    );
    if (result != null && context.mounted) {
      context.read<ScreenshotEditorCubit>().addIconOverlay(
        result.codePoint,
        result.fontFamily,
        result.fontPackage,
        fontWeight: result.fontWeight,
      );
    }
  }
}

const _iconQuickColors = [
  Colors.white,
  Colors.black,
  Color(0xFF00F5FF), // cyan neon
  Color(0xFFFF6B6B), // coral
  Color(0xFF4ECDC4), // teal
  Color(0xFFFFE66D), // yellow
  Color(0xFF7C83FD), // periwinkle
  Color(0xFFFC5185), // hot pink
  Color(0xFF34C759), // green
  Color(0xFF007AFF), // blue
  Color(0xFFFF9500), // orange
  Color(0xFFAF52DE), // purple
];

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.filePath,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final String filePath;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
              image: DecorationImage(
                image: FileImage(File(filePath)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Symbols.close_rounded,
                  size: 10,
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconThumbnail extends StatelessWidget {
  const _IconThumbnail({
    required this.codePoint,
    required this.fontFamily,
    required this.fontPackage,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final int codePoint;
  final String fontFamily;
  final String fontPackage;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(codePoint),
                style: TextStyle(
                  fontFamily: fontFamily,
                  package: fontPackage,
                  fontSize: 24,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Symbols.close_rounded,
                  size: 10,
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
