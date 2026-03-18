import 'dart:math' as math;

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_segmented_control.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class FrameControls extends StatelessWidget {
  const FrameControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      builder: (context, state) {
        final cubit = context.read<ScreenshotEditorCubit>();
        final category = ScreenshotUtils.getDeviceCategory(
          state.design.displayType ?? '',
        );
        final devices = _getDevicesForCategory(category);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Orientation
            ControlSection(
              icon: Symbols.screen_rotation_rounded,
              title: context.l10n.orientation,
            ),
            AppSegmentedControl<Orientation>(
              value: state.design.orientation,
              items: [
                AppSegment(
                  value: Orientation.portrait,
                  label: context.l10n.portrait,
                  icon: Symbols.stay_current_portrait_rounded,
                ),
                AppSegment(
                  value: Orientation.landscape,
                  label: context.l10n.landscape,
                  icon: Symbols.stay_current_landscape_rounded,
                ),
              ],
              onChanged: (_) => cubit.toggleOrientation(),
            ),

            const SizedBox(height: 20),

            // Transform
            ControlSection(
              icon: Symbols.transform_rounded,
              title: context.l10n.transform,
            ),
            ControlCard(
              children: [
                _RotationSlider(
                  label: context.l10n.rotationX,
                  value: state.design.frameRotationX,
                  onChanged: cubit.updateFrameRotationX,
                ),
                const SizedBox(height: 8),
                _RotationSlider(
                  label: context.l10n.rotationY,
                  value: state.design.frameRotationY,
                  onChanged: cubit.updateFrameRotationY,
                ),
                const SizedBox(height: 8),
                _RotationSlider(
                  label: context.l10n.rotationZ,
                  value: state.design.frameRotation,
                  onChanged: cubit.updateFrameRotation,
                ),
                if (state.design.deviceFrame == null) ...[
                  const SizedBox(height: 4),
                  LabeledSlider(
                    label: context.l10n.cornerRadius,
                    value: state.design.cornerRadius,
                    min: 0,
                    max: 500,
                    suffix: 'px',
                    onChanged: cubit.updateCornerRadius,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Padding
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

            // Device Frame
            ControlSection(
              icon: Symbols.phone_iphone_rounded,
              title: context.l10n.deviceFrame,
            ),
            ControlCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _DeviceRadioTile(
                  title: context.l10n.none,
                  device: null,
                  // TECH_DEBT: DeviceInfo deprecated in device_frame — no replacement API yet
                  // ignore: deprecated_member_use
                  groupValue: state.design.deviceFrame,
                  onChanged: cubit.updateDeviceFrame,
                ),
                ...devices.map(
                  (device) => _DeviceRadioTile(
                    title: device.name,
                    device: device,
                    // TECH_DEBT: DeviceInfo deprecated in device_frame — no replacement API yet
                    // ignore: deprecated_member_use
                    groupValue: state.design.deviceFrame,
                    onChanged: cubit.updateDeviceFrame,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<DeviceInfo> _getDevicesForCategory(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.android:
        return [
          DeviceInfo.genericPhone(
            platform: TargetPlatform.android,
            name: 'Android Phone',
            id: 'android_phone',
            screenSize: const Size(411, 915),
            pixelRatio: 2.6,
            safeAreas: const EdgeInsets.only(top: 24, bottom: 24),
            rotatedSafeAreas: const EdgeInsets.only(left: 24, right: 24),
          ),
          ...Devices.android.all,
        ];
      case DeviceCategory.iphone:
        return [
          // iPhone 17 series (newest first, all colors per model)
          ...Devices.ios.iPhone17ProMaxColors,
          ...Devices.ios.iPhone17ProColors,
          ...Devices.ios.iPhone17Colors,
          ...Devices.ios.iPhoneAirColors,
          // iPhone 16 series
          Devices.ios.iPhone16ProMax,
          Devices.ios.iPhone16Pro,
          Devices.ios.iPhone16Plus,
          Devices.ios.iPhone16,
          // iPhone 15 series
          Devices.ios.iPhone15ProMax,
          Devices.ios.iPhone15Pro,
          // Older
          Devices.ios.iPhone13ProMax,
          Devices.ios.iPhoneSE,
        ];
      case DeviceCategory.ipad:
        return [
          Devices.ios.iPadAir4,
          Devices.ios.iPad,
          Devices.ios.iPadPro11Inches,
          Devices.ios.iPad12InchesGen2,
          Devices.ios.iPad12InchesGen4,
          Devices.ios.iPadPro11InchesM4,
          Devices.ios.iPadPro13InchesM4,
        ];
      case DeviceCategory.mac:
        return [
          Devices.macOS.macBookAir13M4,
          Devices.macOS.macBookPro14M4,
          Devices.macOS.macBookPro16M4,
          Devices.macOS.macBookPro,
          Devices.macOS.wideMonitor,
        ];
      case DeviceCategory.watch:
        return [
          ...Devices.watch.all42mm,
          ...Devices.watch.all46mm,
          ...Devices.watch.allUltra3,
        ];
      case DeviceCategory.tv:
        return [];
      case DeviceCategory.twitter:
      case DeviceCategory.instagram:
      case DeviceCategory.facebook:
      case DeviceCategory.linkedin:
      case DeviceCategory.youtube:
      case DeviceCategory.tiktok:
      case DeviceCategory.threads:
      case DeviceCategory.generic:
        return [
          Devices.ios.iPhone16ProMax,
          Devices.ios.iPhone16,
          Devices.ios.iPhone13ProMax,
          Devices.ios.iPhoneSE,
          Devices.ios.iPadPro13InchesM4,
          ...Devices.android.all,
        ];
    }
  }
}

class _DeviceRadioTile extends StatelessWidget {
  const _DeviceRadioTile({
    required this.title,
    required this.device,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final DeviceInfo? device;
  final DeviceInfo? groupValue;
  final ValueChanged<DeviceInfo?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = device == groupValue;

    return InkWell(
      onTap: () => onChanged(device),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: isSelected ? 5 : 1.5,
                ),
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotation slider with tick marks at every 15° and haptic snap feedback.
class _RotationSlider extends StatefulWidget {
  const _RotationSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value; // radians, -π to π
  final ValueChanged<double> onChanged;

  @override
  State<_RotationSlider> createState() => _RotationSliderState();
}

class _RotationSliderState extends State<_RotationSlider> {
  static const _divisions = 72; // every 5°
  static const _step = (2 * math.pi) / _divisions; // ~0.2618 rad

  int _lastTickIndex = -999;

  int _tickIndex(double value) => ((value + math.pi) / _step).round();

  void _onChanged(double value) {
    final tick = _tickIndex(value);
    if (tick != _lastTickIndex) {
      _lastTickIndex = tick;
      HapticFeedback.selectionClick();
    }
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final degrees = (widget.value * 180 / math.pi).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$degrees°',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: theme.colorScheme.primary,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
            activeTickMarkColor: theme.colorScheme.primary.withValues(
              alpha: 0.4,
            ),
            inactiveTickMarkColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.15,
            ),
          ),
          child: Slider(
            value: widget.value.clamp(-math.pi, math.pi),
            min: -math.pi,
            max: math.pi,
            divisions: _divisions,
            onChanged: _onChanged,
          ),
        ),
      ],
    );
  }
}
