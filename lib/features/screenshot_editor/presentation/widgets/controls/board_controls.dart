import 'dart:io';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/frame_element.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/image_picker_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Board tab of the editor control panel: the board canvas, its crop zones,
/// and its device frames.
///
/// Replaces the single-artboard "Frame" tab in board mode, since a board's
/// frames are a list rather than one property of the design.
class BoardControls extends StatelessWidget {
  const BoardControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardCubit, BoardState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BoardSection(state: state),
            const SizedBox(height: 20),
            _CropZonesSection(state: state),
            const SizedBox(height: 20),
            _FramesSection(state: state),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Board canvas
// ─────────────────────────────────────────────────────────────────────────────

class _BoardSection extends StatelessWidget {
  const _BoardSection({required this.state});

  final BoardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BoardCubit>();
    final board = state.board;
    final included = board.exportableZones.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlSection(
          icon: Symbols.dashboard_customize_rounded,
          title: context.l10n.board,
        ),
        ControlCard(
          children: [
            Row(
              children: [
                // The label yields, not the number: a board at the zone limit
                // is over 14,000px wide, and that readout is the point of the
                // row. On a phone the panel is a bottom sheet with no more
                // room to give.
                Expanded(
                  child: Text(
                    context.l10n.boardSize,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${board.size.width.toInt()} × ${board.size.height.toInt()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.zonesIncludedInExport(
                included,
                board.cropZones.length,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: cubit.fitBoardToContent,
                    icon: const Icon(Symbols.fit_screen_rounded, size: 18),
                    label: Text(
                      context.l10n.fitBoardToContent,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.showCropZones,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AppSwitch(
                  value: state.showCropZones,
                  onChanged: cubit.setCropZonesVisible,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crop zones
// ─────────────────────────────────────────────────────────────────────────────

class _CropZonesSection extends StatelessWidget {
  const _CropZonesSection({required this.state});

  final BoardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BoardCubit>();
    final zones = state.board.cropZones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlSection(
          icon: Symbols.crop_rounded,
          title: context.l10n.cropZones,
          trailing: IconButton(
            icon: const Icon(Symbols.add_rounded, size: 18),
            tooltip: state.board.canAddZone
                ? context.l10n.addCropZone
                : context.l10n.zoneLimitReached(BoardDesign.maxZones),
            visualDensity: VisualDensity.compact,
            // Disabled rather than silently ignored at the cap, so the limit
            // is visible before the click.
            onPressed: state.board.canAddZone ? () => cubit.addZone() : null,
          ),
        ),
        if (state.board.exceedsPlayLimit) ...[
          const SizedBox(height: 4),
          _PlayLimitNotice(
            included: state.board.exportableZones.length,
          ),
        ],
        for (var i = 0; i < zones.length; i++) ...[
          _CropZoneTile(
            zone: zones[i],
            index: i,
            isSelected: zones[i].id == state.selectedZoneId,
            canDelete: zones.length > 1,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => cubit.autoArrangeZones(),
          icon: const Icon(Symbols.view_column_rounded, size: 18),
          label: Text(
            context.l10n.arrangeZones,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        _ZoneSpacingControl(gap: state.board.zoneGap),
      ],
    );
  }
}

/// Flags a board that will not upload to Google Play in full.
///
/// A warning rather than a hard cap: Apple accepts ten screenshots and Play
/// only eight, so a board sized for the App Store is legitimately over Play's
/// limit. Blocking at eight would penalise iOS-only projects, which are the
/// common case here.
class _PlayLimitNotice extends StatelessWidget {
  const _PlayLimitNotice({required this.included});

  final int included;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = included - BoardDesign.maxPlayZones;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Symbols.warning_rounded,
            size: 16,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.playLimitWarning(BoardDesign.maxPlayZones, extra),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spacing between crop zones.
///
/// Dragging to zero butts the zones together, so a background spanning the
/// board runs unbroken from one exported screenshot into the next. That is the
/// panorama layout, and it is the reason this is a first-class control rather
/// than a fixed constant.
class _ZoneSpacingControl extends StatelessWidget {
  const _ZoneSpacingControl({required this.gap});

  final double gap;

  /// Widest spacing offered, in board pixels — roughly a third of a phone
  /// screenshot's width, past which zones stop reading as one layout.
  static const double maxGap = 600.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BoardCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledSlider(
          label: context.l10n.zoneSpacing,
          value: gap.clamp(0.0, maxGap),
          min: 0,
          max: maxGap,
          valueLabel: gap <= 0
              ? context.l10n.zoneSpacingNone
              : '${gap.round()} px',
          onEditStart: cubit.beginBatchEdit,
          onEditEnd: cubit.endBatchEdit,
          onChanged: cubit.setZoneGap,
        ),
        Row(
          children: [
            // An exact zero is hard to land on by dragging, and it is the
            // value the panorama layout actually needs.
            TextButton.icon(
              onPressed: gap == 0 ? null : () => cubit.setZoneGap(0),
              icon: const Icon(Symbols.compress_rounded, size: 16),
              label: Text(context.l10n.zoneSpacingNone),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: gap == BoardDesign.defaultZoneGap
                  ? null
                  : () => cubit.setZoneGap(BoardDesign.defaultZoneGap),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(context.l10n.presetReset),
            ),
          ],
        ),
        Text(
          context.l10n.zoneSpacingHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CropZoneTile extends StatelessWidget {
  const _CropZoneTile({
    required this.zone,
    required this.index,
    required this.isSelected,
    required this.canDelete,
  });

  final CropZone zone;
  final int index;
  final bool isSelected;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BoardCubit>();
    final target = zone.targetSize;

    return GestureDetector(
      onTap: () => cubit.selectZone(zone.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  zone.included
                      ? Symbols.crop_rounded
                      : Symbols.visibility_off_rounded,
                  size: 16,
                  color: zone.included
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name ?? context.l10n.screenshotLabel(index + 1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    zone.locked
                        ? Symbols.lock_rounded
                        : Symbols.lock_open_rounded,
                    size: 16,
                  ),
                  tooltip: zone.locked
                      ? context.l10n.unlockZoneSize
                      : context.l10n.lockZoneSize,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => cubit.setZoneLocked(zone.id, !zone.locked),
                ),
                IconButton(
                  icon: const Icon(Symbols.content_copy_rounded, size: 16),
                  tooltip: context.l10n.duplicate,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => cubit.duplicateZone(zone.id),
                ),
                IconButton(
                  icon: const Icon(Symbols.delete_rounded, size: 16),
                  tooltip: context.l10n.delete,
                  visualDensity: VisualDensity.compact,
                  onPressed: canDelete ? () => cubit.removeZone(zone.id) : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: zone.displayType,
              isDense: true,
              // Without this the button takes the intrinsic width of its
              // widest entry, which overflows the panel on a small phone —
              // the panel is a bottom sheet there, so it gets no more room.
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              items: [
                for (final type in ScreenshotUtils.allDisplayTypes)
                  DropdownMenuItem(
                    value: type,
                    child: Text(
                      ScreenshotUtils.friendlyDisplayName(type),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) cubit.setZoneDisplayType(zone.id, value);
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${target.width.toInt()} × ${target.height.toInt()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!zone.isPixelPerfect) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: context.l10n.zoneSizeLockedHint,
                    child: Icon(
                      Symbols.info_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                AppSwitch(
                  value: zone.included,
                  onChanged: (value) => cubit.setZoneIncluded(zone.id, value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frames
// ─────────────────────────────────────────────────────────────────────────────

class _FramesSection extends StatelessWidget {
  const _FramesSection({required this.state});

  final BoardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BoardCubit>();
    final frames = state.board.frames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlSection(
          icon: Symbols.phone_iphone_rounded,
          title: context.l10n.frames,
          trailing: IconButton(
            icon: const Icon(Symbols.add_rounded, size: 18),
            tooltip: context.l10n.addFrame,
            visualDensity: VisualDensity.compact,
            onPressed: () => cubit.addFrame(nearZone: state.selectedZone),
          ),
        ),
        for (var i = 0; i < frames.length; i++) ...[
          _FrameTile(
            frame: frames[i],
            index: i,
            isSelected: frames[i].id == state.selectedFrameId,
          ),
          const SizedBox(height: 8),
        ],
        if (frames.isEmpty)
          Text(
            context.l10n.addFrame,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _FrameTile extends StatelessWidget {
  const _FrameTile({
    required this.frame,
    required this.index,
    required this.isSelected,
  });

  final FrameElement frame;
  final int index;
  final bool isSelected;

  Future<void> _pickImage(BuildContext context) async {
    final cubit = context.read<BoardCubit>();
    final files = await ImagePickerHelper.pickImage(context: context);
    if (files.isEmpty) return;
    await cubit.setFrameImage(frame.id, files.first);
  }

  Future<void> _pickDevice(BuildContext context) async {
    final cubit = context.read<BoardCubit>();
    final identifier = await _BoardDevicePicker.show(context, frame.device);
    if (identifier == null) return;
    cubit.updateFrame(
      frame.copyWith(device: ScreenshotDesign.findDevice(identifier)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BoardCubit>();
    final imageName = frame.imagePath?.split(Platform.pathSeparator).last;

    return GestureDetector(
      onTap: () => cubit.selectFrame(frame.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.phone_iphone_rounded,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.frameLabel(index + 1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.flip_to_front_rounded, size: 16),
                  tooltip: context.l10n.bringToFront,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => cubit.bringFrameToFront(frame.id),
                ),
                IconButton(
                  icon: const Icon(Symbols.flip_to_back_rounded, size: 16),
                  tooltip: context.l10n.sendToBack,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => cubit.sendFrameToBack(frame.id),
                ),
                IconButton(
                  icon: const Icon(Symbols.content_copy_rounded, size: 16),
                  tooltip: context.l10n.duplicate,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => cubit.duplicateFrame(frame.id),
                ),
                IconButton(
                  icon: const Icon(Symbols.delete_rounded, size: 16),
                  tooltip: context.l10n.delete,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => cubit.removeFrame(frame.id),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDevice(context),
                    icon: const Icon(Symbols.devices_rounded, size: 16),
                    label: Text(
                      frame.device?.name ?? context.l10n.noFrame,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Symbols.hide_image_rounded, size: 16),
                  tooltip: context.l10n.noFrame,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      cubit.updateFrame(frame.copyWith(clearDevice: true)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _pickImage(context),
              icon: const Icon(Symbols.image_rounded, size: 16),
              label: Text(
                imageName ?? context.l10n.importImage,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 6),
            LabeledSlider(
              label: context.l10n.frameRotation,
              value: frame.rotation,
              min: -0.5,
              max: 0.5,
              valueLabel: '${(frame.rotation * 57.2958).round()}°',
              onEditStart: cubit.beginBatchEdit,
              onEditEnd: cubit.endBatchEdit,
              onChanged: (value) =>
                  cubit.updateFrame(frame.copyWith(rotation: value)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device picker
// ─────────────────────────────────────────────────────────────────────────────

/// Picks the device shell for one board frame.
///
/// The single-artboard editor picks its device from a radio list inside
/// [FrameControls]; a board has many frames, so the same choice is made per
/// frame in a dialog instead. Returns the chosen device's identifier, or
/// `null` if the dialog was dismissed.
class _BoardDevicePicker extends StatefulWidget {
  const _BoardDevicePicker({this.current});

  final DeviceInfo? current;

  static Future<String?> show(BuildContext context, DeviceInfo? current) {
    return showDialog<String>(
      context: context,
      builder: (_) => _BoardDevicePicker(current: current),
    );
  }

  @override
  State<_BoardDevicePicker> createState() => _BoardDevicePickerState();
}

class _BoardDevicePickerState extends State<_BoardDevicePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final devices = ScreenshotDesign.allDevices
        .where((d) => query.isEmpty || d.name.toLowerCase().contains(query))
        .toList();

    return AlertDialog(
      title: Text(context.l10n.deviceFrame),
      content: SizedBox(
        width: 420,
        height: 520,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Symbols.search_rounded, size: 18),
                hintText: context.l10n.searchDevices,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  // TECH_DEBT: DeviceInfo deprecated in device_frame — no
                  // replacement API yet, matching FrameControls.
                  // ignore: deprecated_member_use
                  final isSelected =
                      widget.current?.identifier == device.identifier;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    title: Text(device.name, style: theme.textTheme.bodyMedium),
                    trailing: isSelected
                        ? Icon(
                            Symbols.check_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(
                      context,
                      device.identifier.toString(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}
