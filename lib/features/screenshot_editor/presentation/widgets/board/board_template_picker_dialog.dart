import 'dart:math' as math;

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_template.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_templates.dart';
import 'package:flutter/material.dart';

/// Picks a board layout.
///
/// Separate from the artboard preset picker because a board template also
/// carries frame rotation and zone spacing, which the thumbnails here show
/// directly — the tilt in the preview is the tilt you get.
class BoardTemplatePickerDialog extends StatelessWidget {
  const BoardTemplatePickerDialog({super.key});

  static Future<BoardTemplate?> show(BuildContext context) {
    return showDialog<BoardTemplate>(
      context: context,
      builder: (_) => const BoardTemplatePickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = BoardTemplates.all;

    // A phone leaves little room once the default dialog inset is taken out,
    // and the cards are what pays for it. Pull the inset in on small screens.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final inset = screenWidth < 400 ? 12.0 : 40.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Text(
                context.l10n.boardTemplates,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.boardTemplatesHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                // Width-driven rather than a fixed column count: two columns
                // on a tablet or desktop, one on a phone. A fixed count made
                // the cards short enough on a small phone that the name and
                // description overflowed the tile.
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: templates.length,
                itemBuilder: (context, i) => _TemplateCard(
                  template: templates[i],
                  onTap: () => Navigator.pop(context, templates[i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final BoardTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: CustomPaint(
                  painter: _TemplatePreviewPainter(template),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a miniature of the layout: three zones at the template's spacing,
/// each with its frame at that zone's rotation.
class _TemplatePreviewPainter extends CustomPainter {
  _TemplatePreviewPainter(this.template);

  final BoardTemplate template;

  static const int _zoneCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = template.thumbnailColors;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg.length >= 2 ? bg : [bg.first, bg.first],
        ).createShader(Offset.zero & size),
    );

    // Lay out the zones the way the board will: equal widths separated by the
    // template's own gap, scaled into the thumbnail.
    const margin = 8.0;
    final gapRatio = template.zoneGap / 1320; // gap as a fraction of zone width
    final available = size.width - margin * 2;
    final zoneWidth = available / (_zoneCount + gapRatio * (_zoneCount - 1));
    final gap = zoneWidth * gapRatio;
    final zoneHeight = size.height - margin * 2;

    final zonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.35);

    for (var i = 0; i < _zoneCount; i++) {
      final left = margin + i * (zoneWidth + gap);
      final zone = Rect.fromLTWH(left, margin, zoneWidth, zoneHeight);
      canvas.drawRect(zone, zonePaint);

      final placement = template.placementFor(i);
      final frameWidth = zoneWidth * placement.widthFactor;
      final frameHeight = math.min(
        frameWidth * FramePlacement.aspect,
        zoneHeight * 0.92,
      );
      final centre = Offset(
        zone.left + zone.width * placement.centerX,
        zone.top + zone.height * placement.centerY,
      );

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(placement.rotation * math.pi / 180);
      final frame = Rect.fromCenter(
        center: Offset.zero,
        width: frameWidth,
        height: frameHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(3)),
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.75),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TemplatePreviewPainter oldDelegate) =>
      oldDelegate.template.id != template.id;
}
