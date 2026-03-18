import 'dart:math' as math;
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/gradient_presets.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/gradient_stop_handle.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/mesh_gradient_editor.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_color_picker.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_segmented_control.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gradient type enum for the editor
// ─────────────────────────────────────────────────────────────────────────────

enum GradientMode { linear, radial, sweep, mesh }

// ─────────────────────────────────────────────────────────────────────────────
// Main editor widget
// ─────────────────────────────────────────────────────────────────────────────

class GradientEditor extends StatefulWidget {
  /// Current standard gradient (linear / radial / sweep). Can be null when
  /// mesh gradient is active.
  final Gradient? gradient;
  final MeshGradientSettings? meshGradient;
  final ValueChanged<Gradient> onGradientChanged;
  final ValueChanged<MeshGradientSettings?> onMeshGradientChanged;
  final bool showMesh;

  const GradientEditor({
    super.key,
    this.gradient,
    this.meshGradient,
    required this.onGradientChanged,
    required this.onMeshGradientChanged,
    this.showMesh = true,
  });

  // Presets are in gradient_presets.dart via [GradientPresets].

  @override
  State<GradientEditor> createState() => _GradientEditorState();
}

class _GradientEditorState extends State<GradientEditor> {
  late GradientMode _mode;
  late List<Color> _colors;
  late List<double> _stops;
  int _selectedStopIndex = 0;
  double _angle = 0; // linear
  // Radial params
  double _centerX = 0;
  double _centerY = 0;
  double _radius = 0.5;
  // Sweep params
  double _sweepStartAngle = 0;
  double _sweepEndAngle = math.pi * 2;

  @override
  void initState() {
    super.initState();
    _initializeFromWidget();
  }

  @override
  void didUpdateWidget(covariant GradientEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradient != widget.gradient ||
        oldWidget.meshGradient != widget.meshGradient) {
      _initializeFromWidget();
    }
  }

  void _initializeFromWidget() {
    if (widget.meshGradient != null) {
      _mode = GradientMode.mesh;
      _colors = [];
      _stops = [];
      return;
    }
    final g = widget.gradient;
    if (g is RadialGradient) {
      _mode = GradientMode.radial;
      _colors = List.from(g.colors);
      _stops = g.stops == null
          ? List.generate(_colors.length, (i) => i / (_colors.length - 1))
          : List.from(g.stops!);
      final center = g.center is Alignment
          ? g.center as Alignment
          : Alignment.center;
      _centerX = center.x;
      _centerY = center.y;
      _radius = g.radius;
    } else if (g is SweepGradient) {
      _mode = GradientMode.sweep;
      _colors = List.from(g.colors);
      _stops = g.stops == null
          ? List.generate(_colors.length, (i) => i / (_colors.length - 1))
          : List.from(g.stops!);
      final center = g.center is Alignment
          ? g.center as Alignment
          : Alignment.center;
      _centerX = center.x;
      _centerY = center.y;
      _sweepStartAngle = g.startAngle;
      _sweepEndAngle = g.endAngle;
    } else if (g is LinearGradient) {
      _mode = GradientMode.linear;
      _colors = List.from(g.colors);
      _stops = g.stops == null
          ? List.generate(_colors.length, (i) => i / (_colors.length - 1))
          : List.from(g.stops!);
      _calculateAngle(g);
    } else {
      _mode = GradientMode.linear;
      _colors = [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
      _stops = [0, 1];
      _angle = 90;
    }
  }

  void _calculateAngle(LinearGradient g) {
    final begin = g.begin is Alignment
        ? g.begin as Alignment
        : Alignment.topLeft;
    final end = g.end is Alignment ? g.end as Alignment : Alignment.bottomRight;
    final dx = end.x - begin.x;
    final dy = end.y - begin.y;
    var angleDeg = math.atan2(dy, dx) * 180 / math.pi;
    if (angleDeg < 0) angleDeg += 360;
    _angle = angleDeg;
  }

  // ── Emit changes ──────────────────────────────────────────────────────
  void _sortAndEmit() {
    final zipped = List.generate(
      _stops.length,
      (i) => MapEntry(_stops[i], _colors[i]),
    );
    zipped.sort((a, b) => a.key.compareTo(b.key));
    final sortedStops = zipped.map((e) => e.key).toList();
    final sortedColors = zipped.map((e) => e.value).toList();

    switch (_mode) {
      case GradientMode.linear:
        final angleRad = _angle * math.pi / 180;
        final cos = math.cos(angleRad);
        final sin = math.sin(angleRad);
        widget.onGradientChanged(
          LinearGradient(
            colors: sortedColors,
            stops: sortedStops,
            begin: Alignment(-cos, -sin),
            end: Alignment(cos, sin),
          ),
        );
        break;
      case GradientMode.radial:
        widget.onGradientChanged(
          RadialGradient(
            colors: sortedColors,
            stops: sortedStops,
            center: Alignment(_centerX, _centerY),
            radius: _radius,
          ),
        );
        break;
      case GradientMode.sweep:
        widget.onGradientChanged(
          SweepGradient(
            colors: sortedColors,
            stops: sortedStops,
            center: Alignment(_centerX, _centerY),
            startAngle: _sweepStartAngle,
            endAngle: _sweepEndAngle,
          ),
        );
        break;
      case GradientMode.mesh:
        break; // mesh emits via its own handler
    }
  }

  void _updateAngle(double newAngle) {
    setState(() => _angle = newAngle);
    _sortAndEmit();
  }

  void _updateStopPosition(int index, double position) {
    setState(() => _stops[index] = position.clamp(0.0, 1.0));
    _sortAndEmit();
  }

  void _updateStopColor(int index, Color color) {
    setState(() => _colors[index] = color);
    _sortAndEmit();
  }

  void _addStop(double position) {
    setState(() {
      _colors.add(Colors.white);
      _stops.add(position);
      _selectedStopIndex = _colors.length - 1;
    });
    _sortAndEmit();
  }

  void _removeStop(int index) {
    if (_colors.length <= 2) return;
    setState(() {
      _colors.removeAt(index);
      _stops.removeAt(index);
      if (_selectedStopIndex >= index && _selectedStopIndex > 0) {
        _selectedStopIndex--;
      }
    });
    _sortAndEmit();
  }

  bool _isMatchingGradient(Gradient preset) {
    if (preset is LinearGradient && _mode != GradientMode.linear) return false;
    if (preset is RadialGradient && _mode != GradientMode.radial) return false;
    if (preset is SweepGradient && _mode != GradientMode.sweep) return false;
    if (_colors.length != preset.colors.length) return false;
    for (int i = 0; i < _colors.length; i++) {
      if (_colors[i].toARGB32() != preset.colors[i].toARGB32()) return false;
    }
    return true;
  }

  String _hexOf(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2);

  void _switchMode(GradientMode newMode) {
    setState(() => _mode = newMode);
    if (newMode == GradientMode.mesh) {
      widget.onMeshGradientChanged(GradientPresets.meshPresets.first);
    } else {
      widget.onMeshGradientChanged(null);
      if (_colors.length < 2) {
        _colors = [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
        _stops = [0, 1];
      }
      _sortAndEmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Type selector ──
        ControlSection(
          icon: Symbols.category_rounded,
          title: context.l10n.gradientType,
        ),
        AppSegmentedControl<GradientMode>(
          value: _mode,
          items: [
            AppSegment(value: GradientMode.linear, label: context.l10n.linear),
            AppSegment(value: GradientMode.radial, label: context.l10n.radial),
            AppSegment(value: GradientMode.sweep, label: context.l10n.sweep),
            if (widget.showMesh)
              AppSegment(value: GradientMode.mesh, label: context.l10n.mesh),
          ],
          onChanged: _switchMode,
        ),
        const SizedBox(height: 16),

        if (_mode == GradientMode.mesh)
          MeshGradientEditor(
            meshGradient: widget.meshGradient,
            onMeshGradientChanged: widget.onMeshGradientChanged,
          )
        else ...[
          // ── Presets ──
          ControlSection(
            icon: Symbols.gradient_rounded,
            title: context.l10n.presetsLabel,
          ),
          _buildPresetsRow(theme),
          const SizedBox(height: 16),
          // ── Stops bar ──
          _buildStopsSection(theme),
          const SizedBox(height: 16),
          // ── Selected stop controls ──
          _buildSelectedStopControls(theme),
          const SizedBox(height: 16),
          // ── Type-specific controls ──
          ..._buildTypeSpecificControls(theme),
        ],
      ],
    );
  }

  // ── Presets Row ──
  Widget _buildPresetsRow(ThemeData theme) {
    final List<Gradient> presets;
    switch (_mode) {
      case GradientMode.linear:
        presets = GradientPresets.linearPresets;
        break;
      case GradientMode.radial:
        presets = GradientPresets.radialPresets;
        break;
      case GradientMode.sweep:
        presets = GradientPresets.sweepPresets;
        break;
      case GradientMode.mesh:
        presets = [];
        break;
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isActive = _isMatchingGradient(preset);
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                widget.onGradientChanged(preset as dynamic);
                _initializeFromWidget();
                setState(() {});
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: preset,
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 2,
                              ),
                            ],
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
    );
  }

  // ── Stops Section ──
  Widget _buildStopsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlSection(
          icon: Symbols.linear_scale_rounded,
          title: context.l10n.stops,
          trailing: Text(
            context.l10n.tapBarToAdd,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        Container(
          height: 48,
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTapUp: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    _addStop(
                      (localPos.dx / constraints.maxWidth).clamp(0.0, 1.0),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          gradient: LinearGradient(
                            colors: _colors,
                            stops: _stops,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(_stops.length, (index) {
                        return Positioned(
                          left: _stops[index] * constraints.maxWidth - 12,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                _updateStopPosition(
                                  index,
                                  _stops[index] +
                                      details.delta.dx / constraints.maxWidth,
                                );
                                setState(() => _selectedStopIndex = index);
                              },
                              onTap: () =>
                                  setState(() => _selectedStopIndex = index),
                              child: GradientStopHandle(
                                color: _colors[index],
                                isSelected: index == _selectedStopIndex,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Selected Stop Controls ──
  Widget _buildSelectedStopControls(ThemeData theme) {
    final selectedColor = _colors[_selectedStopIndex];
    final selectedStop = _stops[_selectedStopIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlSection(
          icon: Symbols.colorize_rounded,
          title: context.l10n.selectedStop,
          trailing: _colors.length > 2
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _removeStop(_selectedStopIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.remove_rounded,
                            size: 12,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.l10n.removeStop,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        ),
        ControlCard(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => showColorPickerDialog(
                  context: context,
                  color: selectedColor,
                  onColorChanged: (c) =>
                      _updateStopColor(_selectedStopIndex, c),
                  enableAlpha: true,
                  sourceRect: rectFromContext(context),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '#${_hexOf(selectedColor)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(selectedColor.a * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Symbols.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            LabeledSlider(
              label: context.l10n.location,
              value: selectedStop,
              min: 0,
              max: 1,
              valueLabel: '${(selectedStop * 100).round()}%',
              onChanged: (val) => _updateStopPosition(_selectedStopIndex, val),
            ),
          ],
        ),
      ],
    );
  }

  // ── Type-specific controls ──
  List<Widget> _buildTypeSpecificControls(ThemeData theme) {
    switch (_mode) {
      case GradientMode.linear:
        return [
          ControlSection(
            icon: Symbols.rotate_right_rounded,
            title: context.l10n.angle,
          ),
          ControlCard(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _colors,
                        stops: _stops,
                        begin: Alignment(
                          -math.cos(_angle * math.pi / 180),
                          -math.sin(_angle * math.pi / 180),
                        ),
                        end: Alignment(
                          math.cos(_angle * math.pi / 180),
                          math.sin(_angle * math.pi / 180),
                        ),
                      ),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledSlider(
                      label: context.l10n.angle,
                      value: _angle,
                      min: 0,
                      max: 360,
                      valueLabel: '${_angle.round()}°',
                      onChanged: _updateAngle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];
      case GradientMode.radial:
        return [
          ControlSection(
            icon: Symbols.blur_circular_rounded,
            title: context.l10n.radialSettings,
          ),
          ControlCard(
            children: [
              LabeledSlider(
                label: context.l10n.centerX,
                value: _centerX,
                min: -1,
                max: 1,
                valueLabel: _centerX.toStringAsFixed(2),
                onChanged: (v) {
                  setState(() => _centerX = v);
                  _sortAndEmit();
                },
              ),
              const SizedBox(height: 4),
              LabeledSlider(
                label: context.l10n.centerY,
                value: _centerY,
                min: -1,
                max: 1,
                valueLabel: _centerY.toStringAsFixed(2),
                onChanged: (v) {
                  setState(() => _centerY = v);
                  _sortAndEmit();
                },
              ),
              const SizedBox(height: 4),
              LabeledSlider(
                label: context.l10n.radius,
                value: _radius,
                min: 0.1,
                max: 2.0,
                valueLabel: _radius.toStringAsFixed(2),
                onChanged: (v) {
                  setState(() => _radius = v);
                  _sortAndEmit();
                },
              ),
            ],
          ),
        ];
      case GradientMode.sweep:
        return [
          ControlSection(
            icon: Symbols.autorenew_rounded,
            title: context.l10n.sweepSettings,
          ),
          ControlCard(
            children: [
              LabeledSlider(
                label: context.l10n.centerX,
                value: _centerX,
                min: -1,
                max: 1,
                valueLabel: _centerX.toStringAsFixed(2),
                onChanged: (v) {
                  setState(() => _centerX = v);
                  _sortAndEmit();
                },
              ),
              const SizedBox(height: 4),
              LabeledSlider(
                label: context.l10n.centerY,
                value: _centerY,
                min: -1,
                max: 1,
                valueLabel: _centerY.toStringAsFixed(2),
                onChanged: (v) {
                  setState(() => _centerY = v);
                  _sortAndEmit();
                },
              ),
              const SizedBox(height: 4),
              LabeledSlider(
                label: context.l10n.startAngle,
                value: _sweepStartAngle / math.pi * 180,
                min: 0,
                max: 360,
                valueLabel: '${(_sweepStartAngle / math.pi * 180).round()}°',
                onChanged: (v) {
                  setState(() => _sweepStartAngle = v * math.pi / 180);
                  _sortAndEmit();
                },
              ),
              const SizedBox(height: 4),
              LabeledSlider(
                label: context.l10n.endAngle,
                value: _sweepEndAngle / math.pi * 180,
                min: 0,
                max: 360,
                valueLabel: '${(_sweepEndAngle / math.pi * 180).round()}°',
                onChanged: (v) {
                  setState(() => _sweepEndAngle = v * math.pi / 180);
                  _sortAndEmit();
                },
              ),
            ],
          ),
        ];
      case GradientMode.mesh:
        return [];
    }
  }
}
