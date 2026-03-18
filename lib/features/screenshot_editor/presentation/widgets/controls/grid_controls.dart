import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class GridControls extends StatelessWidget {
  const GridControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      builder: (context, state) {
        final settings = state.design.gridSettings;
        final cubit = context.read<ScreenshotEditorCubit>();
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Visibility
            ControlSection(
              icon: Symbols.visibility_rounded,
              title: context.l10n.displayLabel,
            ),
            ControlCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              children: [
                _StyledSwitch(
                  icon: Symbols.grid_on_rounded,
                  title: context.l10n.showGridLabel,
                  subtitle: context.l10n.displayGridLines,
                  value: settings.showGrid,
                  onChanged: (val) => cubit.updateGridSettings(
                    settings.copyWith(showGrid: val),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.12,
                  ),
                ),
                _StyledSwitch(
                  icon: Symbols.near_me_rounded,
                  title: context.l10n.snapToGridLabel,
                  subtitle: context.l10n.snapToGridSubtitle,
                  value: settings.snapToGrid,
                  onChanged: (val) => cubit.updateGridSettings(
                    settings.copyWith(snapToGrid: val),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.12,
                  ),
                ),
                _StyledSwitch(
                  icon: Symbols.center_focus_strong_rounded,
                  title: context.l10n.centerLines,
                  subtitle: context.l10n.centerLinesSubtitle,
                  value: settings.showCenterLines,
                  onChanged: (val) => cubit.updateGridSettings(
                    settings.copyWith(showCenterLines: val),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.12,
                  ),
                ),
                _StyledSwitch(
                  icon: Symbols.grid_3x3_rounded,
                  title: context.l10n.showDotGrid,
                  subtitle: context.l10n.showDotGridSubtitle,
                  value: settings.showDotGrid,
                  onChanged: (val) => cubit.updateGridSettings(
                    settings.copyWith(showDotGrid: val),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Grid size
            ControlSection(
              icon: Symbols.straighten_rounded,
              title: context.l10n.gridSizeLabel,
            ),
            ControlCard(
              children: [
                LabeledSlider(
                  label: context.l10n.sizeLabel,
                  value: settings.gridSize,
                  min: 10,
                  max: 200,
                  divisions: 19,
                  suffix: 'px',
                  onChanged: (val) => cubit.updateGridSettings(
                    settings.copyWith(gridSize: val),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StyledSwitch extends StatelessWidget {
  const _StyledSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
