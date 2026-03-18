// TECH_DEBT: Color.value deprecated in Flutter 3.27 — used by device_frame package internals
// ignore_for_file: deprecated_member_use
import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/screenshot_presets.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/template_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/ai_template_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A dialog that displays all available presets as beautiful cards.
/// Returns the selected [ScreenshotPreset] on tap.
class PresetPickerDialog extends StatefulWidget {
  const PresetPickerDialog({super.key, this.asPage = false});

  /// When true, renders as a full-screen page instead of a floating dialog.
  final bool asPage;

  /// Shows the preset picker as a dialog on wide screens (≥ 600 px) or
  /// pushes a full-page route on small / mobile screens.
  ///
  /// When [sourceRect] is provided, a genie animation is used.
  static Future<ScreenshotPreset?> show(
    BuildContext context, {
    Rect? sourceRect,
  }) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    if (isSmallScreen) {
      if (sourceRect != null) {
        return Navigator.of(context).push<ScreenshotPreset>(
          geniePageRoute<ScreenshotPreset>(
            sourceRect: sourceRect,
            builder: (_) => const PresetPickerDialog(asPage: true),
          ),
        );
      }
      return Navigator.of(context).push<ScreenshotPreset>(
        MaterialPageRoute(
          builder: (_) => const PresetPickerDialog(asPage: true),
        ),
      );
    }

    if (sourceRect != null) {
      return showGenieDialog<ScreenshotPreset>(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => const PresetPickerDialog(),
      );
    }

    return showDialog<ScreenshotPreset>(
      context: context,
      builder: (_) => const PresetPickerDialog(),
    );
  }

  @override
  State<PresetPickerDialog> createState() => _PresetPickerDialogState();
}

class _PresetPickerDialogState extends State<PresetPickerDialog> {
  late Future<List<ScreenshotPreset>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = sl<TemplatePersistenceService>().loadTemplates();
  }

  Widget _buildGrid(
    BuildContext context, {
    required int crossAxisCount,
    required List<ScreenshotPreset> customTemplates,
  }) {
    final defaultPresets = ScreenshotPresets.all;
    final allPresets = [...customTemplates, ...defaultPresets];

    // +1 for the AI Generate card at index 0
    final totalCount = allPresets.length + 1;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // First item is the AI Generate card
        if (index == 0) {
          return _AiGenerateCard(
            onGenerated: (preset) => Navigator.pop(context, preset),
          );
        }
        final preset = allPresets[index - 1];
        return _PresetCard(
          preset: preset,
          onTap: () => Navigator.pop(context, preset),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return FutureBuilder<List<ScreenshotPreset>>(
      future: _templatesFuture,
      builder: (context, snapshot) {
        final customTemplates = snapshot.data ?? [];

        // ── Full-page mode (mobile / small screens) ──
        if (widget.asPage) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.templates),
              centerTitle: true,
            ),
            body: _buildGrid(
              context,
              crossAxisCount: 2,
              customTemplates: customTemplates,
            ),
          );
        }

        // ── Dialog mode (desktop / wide screens) ──
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.15),
                              theme.colorScheme.tertiary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Symbols.style_rounded,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.templates,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              context.l10n.pickAStyleForScreenshots,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Symbols.close_rounded),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ── Grid content ──
                Expanded(
                  child: _buildGrid(
                    context,
                    crossAxisCount: 3,
                    customTemplates: customTemplates,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================

class _PresetCard extends StatefulWidget {
  final ScreenshotPreset preset;
  final VoidCallback onTap;

  const _PresetCard({required this.preset, required this.onTap});

  @override
  State<_PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<_PresetCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = widget.preset;
    final colors = preset.thumbnailColors.isNotEmpty
        ? preset.thumbnailColors
        : [Colors.grey];

    final previewBg = colors.first;
    final isLightBg =
        ThemeData.estimateBrightnessForColor(previewBg) == Brightness.light;

    final textColor = isLightBg
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.9);

    final phoneColor = isLightBg
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.12);

    final phoneBorder = isLightBg
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.1);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered ? 1.04 : 1.0,
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: _hovered ? 8 : 1,
          shadowColor: Colors.black26,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Preview area — mimics App Store screenshot layout ──
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors.length >= 2
                            ? colors
                            : [colors.first, colors.first],
                      ),
                      // Subtle border so white presets don't blend in
                      border: isLightBg
                          ? Border(
                              bottom: BorderSide(
                                color: Colors.black.withValues(alpha: 0.08),
                                width: 0.5,
                              ),
                            )
                          : null,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final areaW = constraints.maxWidth;
                        final areaH = constraints.maxHeight;

                        // Phone frame dimensions — 9:19.5 aspect ratio
                        final phoneW = (areaW - 28) / 5; // 5 phones with gaps
                        final phoneH = phoneW * 2.1;
                        final phoneTop = areaH - phoneH - 6;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ── Sample title text ──
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Text(
                                preset.designs.isNotEmpty &&
                                        preset.designs.first.overlays.isNotEmpty
                                    ? preset.designs.first.overlays.first.text
                                          .replaceAll('\n', ' ')
                                    : preset.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.getFont(
                                  preset.titleFont,
                                  textStyle: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),

                            // ── 5 mini phone frames ──
                            ...List.generate(5, (i) {
                              final x = 4.0 + i * (phoneW + 4);
                              return Positioned(
                                left: x,
                                top: phoneTop.clamp(28.0, areaH),
                                width: phoneW,
                                height: phoneH,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: phoneColor,
                                    borderRadius: BorderRadius.circular(
                                      phoneW * 0.15,
                                    ),
                                    border: Border.all(
                                      color: phoneBorder,
                                      width: 0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  // Inner "screen" area
                                  padding: EdgeInsets.all(phoneW * 0.08),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isLightBg
                                          ? Colors.black.withValues(alpha: 0.07)
                                          : Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        phoneW * 0.1,
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
                ),

                // ── Info ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        preset.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================

class _AiGenerateCard extends StatefulWidget {
  final ValueChanged<ScreenshotPreset> onGenerated;

  const _AiGenerateCard({required this.onGenerated});

  @override
  State<_AiGenerateCard> createState() => _AiGenerateCardState();
}

class _AiGenerateCardState extends State<_AiGenerateCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered ? 1.04 : 1.0,
        child: Material(
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: _hovered ? 8 : 2,
          shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () async {
              final preset = await AiTemplateDialog.show(
                context,
                providerRepo: sl<AIProviderRepository>(),
              );
              if (preset != null) widget.onGenerated(preset);
            },
            child: Stack(
              children: [
                // ── Animated gradient background ──
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      final t = _shimmerController.value;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1.0 + 2.0 * t, -1.0),
                            end: Alignment(1.0 + 2.0 * t, 1.0),
                            colors: const [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFFA855F7),
                              Color(0xFF8B5CF6),
                              Color(0xFF6366F1),
                            ],
                            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Content ──
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Symbols.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.aiGenerate,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.aiGenerateSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
