import 'dart:math' as math;
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_color_picker.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/gradient_presets.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Full mesh-gradient editing panel: presets, interactive position preview,
/// per-point controls (color + position), add/remove, blend & noise.
class MeshGradientEditor extends StatelessWidget {
  final MeshGradientSettings? meshGradient;
  final ValueChanged<MeshGradientSettings?> onMeshGradientChanged;

  const MeshGradientEditor({
    super.key,
    required this.meshGradient,
    required this.onMeshGradientChanged,
  });

  String _hexOf(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mesh = meshGradient ?? GradientPresets.meshPresets.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets
        ControlSection(
          icon: Symbols.gradient_rounded,
          title: context.l10n.presetsLabel,
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GradientPresets.meshPresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final preset = GradientPresets.meshPresets[index];
              final isActive =
                  meshGradient != null &&
                  meshGradient!.points.length == preset.points.length &&
                  List.generate(
                    preset.points.length,
                    (i) =>
                        meshGradient!.points[i].color.toARGB32() ==
                        preset.points[i].color.toARGB32(),
                  ).every((e) => e);
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onMeshGradientChanged(preset),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: preset.points.map((p) => p.color).toList(),
                      ),
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                        width: isActive ? 2.5 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: isActive
                        ? Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.check_rounded,
                                size: 11,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Interactive position preview ──
        ControlSection(
          icon: Symbols.drag_pan_rounded,
          title: context.l10n.meshPoints,
          trailing: Text(
            context.l10n.pointCount(mesh.points.length),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        _MeshPointPositionPreview(mesh: mesh, onChanged: onMeshGradientChanged),
        const SizedBox(height: 16),

        // ── Per-point controls ──
        ...List.generate(mesh.points.length, (i) {
          final point = mesh.points[i];
          return _MeshPointCard(
            index: i,
            point: point,
            canRemove: mesh.points.length > 3,
            onColorChanged: (c) {
              final pts = List<MeshPoint>.from(mesh.points);
              pts[i] = point.copyWith(color: c);
              onMeshGradientChanged(mesh.copyWith(points: pts));
            },
            onPositionChanged: (pos) {
              final pts = List<MeshPoint>.from(mesh.points);
              pts[i] = point.copyWith(position: pos);
              onMeshGradientChanged(mesh.copyWith(points: pts));
            },
            onRemove: () {
              final pts = List<MeshPoint>.from(mesh.points)..removeAt(i);
              onMeshGradientChanged(mesh.copyWith(points: pts));
            },
            hexOf: _hexOf,
          );
        }),

        // ── Add point button ──
        const SizedBox(height: 8),
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final rng = math.Random();
                final newPoint = MeshPoint(
                  position: Offset(
                    (rng.nextDouble() * 0.6 + 0.2),
                    (rng.nextDouble() * 0.6 + 0.2),
                  ),
                  color: HSLColor.fromAHSL(
                    1,
                    rng.nextDouble() * 360,
                    0.7 + rng.nextDouble() * 0.3,
                    0.5 + rng.nextDouble() * 0.3,
                  ).toColor(),
                );
                final pts = List<MeshPoint>.from(mesh.points)..add(newPoint);
                onMeshGradientChanged(mesh.copyWith(points: pts));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.add_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.addPoint,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Blend & Noise
        ControlSection(
          icon: Symbols.tune_rounded,
          title: context.l10n.meshOptions,
        ),
        ControlCard(
          children: [
            LabeledSlider(
              label: context.l10n.blend,
              value: mesh.blend,
              min: 1,
              max: 10,
              valueLabel: mesh.blend.toStringAsFixed(1),
              onChanged: (v) => onMeshGradientChanged(mesh.copyWith(blend: v)),
            ),
            const SizedBox(height: 4),
            LabeledSlider(
              label: context.l10n.noise,
              value: mesh.noiseIntensity,
              min: 0,
              max: 1,
              valueLabel: mesh.noiseIntensity.toStringAsFixed(2),
              onChanged: (v) =>
                  onMeshGradientChanged(mesh.copyWith(noiseIntensity: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Interactive Mesh Point Position Preview ──
class _MeshPointPositionPreview extends StatelessWidget {
  final MeshGradientSettings mesh;
  final ValueChanged<MeshGradientSettings?> onChanged;

  const _MeshPointPositionPreview({
    required this.mesh,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: mesh.points.map((p) => p.color).toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.15)),
                ),
                ...List.generate(mesh.points.length, (i) {
                  final point = mesh.points[i];
                  final x = point.position.dx * size.width;
                  final y = point.position.dy * size.height;

                  return Positioned(
                    left: x - 14,
                    top: y - 14,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newX = ((x + details.delta.dx) / size.width)
                            .clamp(0.0, 1.0);
                        final newY = ((y + details.delta.dy) / size.height)
                            .clamp(0.0, 1.0);
                        final pts = List<MeshPoint>.from(mesh.points);
                        pts[i] = point.copyWith(position: Offset(newX, newY));
                        onChanged(mesh.copyWith(points: pts));
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: point.color,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Mesh Point Card ──
class _MeshPointCard extends StatelessWidget {
  final int index;
  final MeshPoint point;
  final bool canRemove;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onRemove;
  final String Function(Color) hexOf;

  const _MeshPointCard({
    required this.index,
    required this.point,
    required this.canRemove,
    required this.onColorChanged,
    required this.onPositionChanged,
    required this.onRemove,
    required this.hexOf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ControlCard(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => showColorPickerDialog(
                context: context,
                color: point.color,
                onColorChanged: onColorChanged,
                sourceRect: rectFromContext(context),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: point.color,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.pointLabel(index + 1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#${hexOf(point.color)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (canRemove)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Symbols.close_rounded,
                            size: 12,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Symbols.chevron_right_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: context.l10n.xAxis,
            value: point.position.dx,
            min: 0,
            max: 1,
            valueLabel: point.position.dx.toStringAsFixed(2),
            onChanged: (v) => onPositionChanged(Offset(v, point.position.dy)),
          ),
          const SizedBox(height: 4),
          LabeledSlider(
            label: context.l10n.yAxis,
            value: point.position.dy,
            min: 0,
            max: 1,
            valueLabel: point.position.dy.toStringAsFixed(2),
            onChanged: (v) => onPositionChanged(Offset(point.position.dx, v)),
          ),
        ],
      ),
    );
  }
}
