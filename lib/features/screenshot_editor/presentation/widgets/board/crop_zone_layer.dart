import 'dart:math' as math;

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Draws the board's crop zones — the regions that become exported images.
///
/// This layer sits *outside* the capture boundary, so outlines, labels, and
/// handles can never leak into an exported screenshot no matter what is
/// toggled at capture time.
///
/// The zone interior is click-through so frames and overlays underneath stay
/// directly editable; only the label chip and the border band select or drag a
/// zone (the same affordance Figma gives an artboard).
class CropZoneLayer extends StatelessWidget {
  const CropZoneLayer({
    super.key,
    required this.zones,
    required this.selectedZoneId,
  });

  final List<CropZone> zones;
  final String? selectedZoneId;

  /// Corner radius of a zone outline, in board pixels. Small on purpose — the
  /// zone marks a hard rectangular crop, so the rounding is a hint, not a
  /// shape.
  static const double cornerRadius = 28.0;

  /// Two edges this far apart or closer count as touching, in board pixels.
  static const double _adjacencyEpsilon = 1.0;

  /// Rounds only the edges of a zone that face open canvas.
  ///
  /// At zero spacing the zones butt together to form one continuous strip, and
  /// rounding every zone would draw seams through the middle of it. Only the
  /// outer ends of the run stay rounded, so the strip reads as the single image
  /// it exports as.
  static BorderRadius radiusFor(List<CropZone> zones, CropZone zone) {
    var touchesLeft = false;
    var touchesRight = false;

    for (final other in zones) {
      if (other.id == zone.id) continue;
      // Ignore zones on a different row — only a side-by-side neighbour can
      // form a seam.
      final overlapsVertically = other.rect.top < zone.rect.bottom &&
          other.rect.bottom > zone.rect.top;
      if (!overlapsVertically) continue;

      if ((other.rect.right - zone.rect.left).abs() <= _adjacencyEpsilon) {
        touchesLeft = true;
      }
      if ((other.rect.left - zone.rect.right).abs() <= _adjacencyEpsilon) {
        touchesRight = true;
      }
    }

    const r = Radius.circular(cornerRadius);
    return BorderRadius.horizontal(
      left: touchesLeft ? Radius.zero : r,
      right: touchesRight ? Radius.zero : r,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < zones.length; i++)
          _CropZoneBox(
            key: ValueKey(zones[i].id),
            zone: zones[i],
            index: i,
            isSelected: zones[i].id == selectedZoneId,
            radius: radiusFor(zones, zones[i]),
          ),
        // Hidden at the store cap rather than shown disabled — an inert button
        // floating on the canvas reads as broken.
        if (zones.isNotEmpty && zones.length < BoardDesign.maxZones)
          _AddZoneButton(zones: zones),
      ],
    );
  }
}

/// Quick "add another screenshot" affordance at the end of the zone strip, so
/// a board can be extended without leaving the canvas for the side panel.
class _AddZoneButton extends StatelessWidget {
  const _AddZoneButton({required this.zones});

  final List<CropZone> zones;

  /// Diameter in board pixels — large, because board coordinates are
  /// screenshot-resolution and the canvas is usually zoomed well out.
  static const double size = 130.0;

  /// Distance from the last zone's right edge, in board pixels.
  static const double gap = 70.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Anchor to the rightmost zone rather than the last in list order — the
    // list is export order, which the user can reorder independently.
    var anchor = zones.first.rect;
    for (final zone in zones) {
      if (zone.rect.right > anchor.right) anchor = zone.rect;
    }

    return Positioned(
      left: anchor.right + gap,
      top: anchor.center.dy - size / 2,
      width: size,
      height: size,
      child: Tooltip(
        message: context.l10n.addCropZone,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.read<BoardCubit>().addZone(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  width: 4,
                ),
              ),
              child: Icon(
                Symbols.add_rounded,
                size: size * 0.55,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CropZoneBox extends StatefulWidget {
  const _CropZoneBox({
    super.key,
    required this.zone,
    required this.index,
    required this.isSelected,
    required this.radius,
  });

  final CropZone zone;
  final int index;
  final bool isSelected;

  /// Per-corner rounding; square on any edge that abuts a neighbouring zone.
  final BorderRadius radius;

  /// Thickness of the grab band along the zone edge, in board pixels.
  static const double edgeBand = 28.0;
  static const double handleSize = 44.0;

  /// Gap between the board's top edge and the label sitting above it, in board
  /// pixels. Must stay well inside the canvas padding around the board.
  static const double labelGap = 40.0;

  @override
  State<_CropZoneBox> createState() => _CropZoneBoxState();
}

/// Draws a zone outline as a dashed rounded rectangle.
///
/// Dashed so the boundary reads as a guide rather than as part of the artwork —
/// it never appears in an export, and a solid rule at these sizes looks like a
/// deliberate border in the design.
class _DashedZonePainter extends CustomPainter {
  _DashedZonePainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius radius;

  /// Dash and gap lengths in board pixels.
  static const double _dash = 56.0;
  static const double _gap = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(radius.toRRect(Offset.zero & size));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedZonePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}

class _CropZoneBoxState extends State<_CropZoneBox> {
  Offset? _dragPosition;
  Size? _dragSize;

  BoardCubit get _cubit => context.read<BoardCubit>();

  Offset get _position => _dragPosition ?? widget.zone.position;
  Size get _size => _dragSize ?? widget.zone.size;

  void _startGesture() {
    _cubit.selectZone(widget.zone.id);
    _cubit.beginBatchEdit();
    _dragPosition = widget.zone.position;
    _dragSize = widget.zone.size;
  }

  void _endGesture() {
    if (_dragPosition == null && _dragSize == null) return;
    // A tap that registers as a zero-distance pan would otherwise commit an
    // identical zone and leave a do-nothing entry in the undo history.
    final moved =
        _position != widget.zone.position || _size != widget.zone.size;
    if (moved) {
      _cubit.updateZone(
        widget.zone.copyWith(position: _position, size: _size),
      );
    }
    _cubit.endBatchEdit();
    setState(() {
      _dragPosition = null;
      _dragSize = null;
    });
  }

  void _onMove(Offset delta) =>
      setState(() => _dragPosition = _position + delta);

  void _onResize(Alignment corner, Offset delta) {
    var left = _position.dx;
    var top = _position.dy;
    var width = _size.width;
    var height = _size.height;

    if (corner.x < 0) {
      left += delta.dx;
      width -= delta.dx;
    } else {
      width += delta.dx;
    }
    if (corner.y < 0) {
      top += delta.dy;
      height -= delta.dy;
    } else {
      height += delta.dy;
    }

    const minSide = _CropZoneBox.handleSize * 2;
    if (width < minSide || height < minSide) return;

    setState(() {
      _dragPosition = Offset(left, top);
      _dragSize = Size(width, height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zone = widget.zone;
    final accent = zone.included
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final borderWidth = widget.isSelected ? 8.0 : 4.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      width: _size.width,
      height: _size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outline. Click-through so the frames beneath stay editable.
          // An excluded zone drops to a lower alpha so "will not be exported"
          // reads at a glance, without the outline disappearing.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DashedZonePainter(
                  color: accent.withValues(
                    alpha: widget.isSelected
                        ? 1.0
                        : (widget.zone.included ? 0.8 : 0.45),
                  ),
                  strokeWidth: borderWidth,
                  radius: widget.radius,
                ),
              ),
            ),
          ),

          // Grab bands along each edge — selecting/dragging without covering
          // the zone interior.
          _edgeBand(Alignment.topCenter),
          _edgeBand(Alignment.bottomCenter),
          _edgeBand(Alignment.centerLeft),
          _edgeBand(Alignment.centerRight),

          // Label, lifted clear of the board onto the canvas above it.
          //
          // `bottom` is measured from the zone's own bottom edge, so adding the
          // zone's y offset puts the label at a fixed distance above the board
          // top (y = 0) no matter where in the board the zone sits — the labels
          // line up in a row instead of stepping with their zones.
          Positioned(
            left: 0,
            bottom: _position.dy + _size.height + _CropZoneBox.labelGap,
            child: _buildLabel(context, accent),
          ),

          if (widget.isSelected && !zone.locked) ..._buildResizeHandles(accent),
        ],
      ),
    );
  }

  Widget _edgeBand(Alignment side) {
    const band = _CropZoneBox.edgeBand;
    final horizontal = side == Alignment.topCenter ||
        side == Alignment.bottomCenter;

    return Positioned(
      left: side == Alignment.centerRight ? null : 0,
      right: side == Alignment.centerLeft ? null : 0,
      top: side == Alignment.bottomCenter ? null : 0,
      bottom: side == Alignment.topCenter ? null : 0,
      width: horizontal ? null : band,
      height: horizontal ? band : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _cubit.selectZone(widget.zone.id),
          onPanStart: (_) => _startGesture(),
          onPanUpdate: (details) => _onMove(details.delta),
          onPanEnd: (_) => _endGesture(),
          onPanCancel: _endGesture,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// The zone's label, drawn on the canvas above the board.
  ///
  /// Plain text rather than a filled chip: sitting outside the board means the
  /// backdrop is the editor's own canvas colour, not the user's artwork, so
  /// there is a known contrast to style against and no plate is needed.
  Widget _buildLabel(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final zone = widget.zone;
    final title =
        zone.name ?? context.l10n.screenshotLabel(widget.index + 1);
    final target = zone.targetSize;
    final selected = widget.isSelected;

    // Full-strength on the canvas backdrop; excluded zones drop back but stay
    // comfortably legible.
    final titleColor = selected
        ? accent
        : theme.colorScheme.onSurface.withValues(
            alpha: zone.included ? 0.9 : 0.5,
          );
    final metaColor = theme.colorScheme.onSurface.withValues(
      alpha: zone.included ? 0.6 : 0.4,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _cubit.selectZone(zone.id),
        onPanStart: (_) => _startGesture(),
        onPanUpdate: (details) => _onMove(details.delta),
        onPanEnd: (_) => _endGesture(),
        onPanCancel: _endGesture,
        onSecondaryTapUp: (details) => _showContextMenu(context, details),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              zone.included
                  ? Symbols.crop_rounded
                  : Symbols.visibility_off_rounded,
              size: 52,
              color: titleColor,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 56,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: titleColor,
              ),
            ),
            const SizedBox(width: 22),
            Text(
              '${ScreenshotUtils.friendlyDisplayName(zone.displayType)} · '
              '${target.width.toInt()} × ${target.height.toInt()}'
              '${zone.locked ? '' : ' ↔'}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: metaColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(Color accent) {
    const corners = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];
    const size = _CropZoneBox.handleSize;

    return corners.map((corner) {
      return Positioned(
        left: corner.x < 0 ? -size / 2 : null,
        right: corner.x > 0 ? -size / 2 : null,
        top: corner.y < 0 ? -size / 2 : null,
        bottom: corner.y > 0 ? -size / 2 : null,
        child: MouseRegion(
          cursor: corner == Alignment.topLeft || corner == Alignment.bottomRight
              ? SystemMouseCursors.resizeUpLeftDownRight
              : SystemMouseCursors.resizeUpRightDownLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _startGesture(),
            onPanUpdate: (details) => _onResize(corner, details.delta),
            onPanEnd: (_) => _endGesture(),
            onPanCancel: _endGesture,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: accent, width: 5),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showContextMenu(BuildContext context, TapUpDetails details) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final cubit = _cubit;
    final zone = widget.zone;

    context
        .showAppPopupMenu<String>(
          position: RelativeRect.fromRect(
            details.globalPosition & const Size(1, 1),
            Offset.zero & overlay.size,
          ),
          items: [
            AppPopupMenuItem(
              value: 'toggleInclude',
              title: zone.included
                  ? context.l10n.excludeFromExport
                  : context.l10n.includeInExport,
              icon: zone.included
                  ? Symbols.visibility_off_rounded
                  : Symbols.visibility_rounded,
            ),
            AppPopupMenuItem(
              value: 'toggleLock',
              title: zone.locked
                  ? context.l10n.unlockZoneSize
                  : context.l10n.lockZoneSize,
              icon: zone.locked
                  ? Symbols.lock_open_rounded
                  : Symbols.lock_rounded,
            ),
            AppPopupMenuItem(
              value: 'duplicate',
              title: context.l10n.duplicate,
              icon: Symbols.content_copy_rounded,
            ),
            AppPopupMenuItem(
              value: 'delete',
              title: context.l10n.delete,
              icon: Symbols.delete_rounded,
              isDestructive: true,
            ),
          ],
        )
        .then((value) {
          switch (value) {
            case 'toggleInclude':
              cubit.setZoneIncluded(zone.id, !zone.included);
            case 'toggleLock':
              cubit.setZoneLocked(zone.id, !zone.locked);
            case 'duplicate':
              cubit.duplicateZone(zone.id);
            case 'delete':
              cubit.removeZone(zone.id);
          }
        });
  }
}
