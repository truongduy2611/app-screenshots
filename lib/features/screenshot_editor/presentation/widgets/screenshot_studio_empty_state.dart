import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ScreenshotStudioEmptyState extends StatelessWidget {
  const ScreenshotStudioEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final tertiary = theme.colorScheme.tertiary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient icon container with glassmorphism
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    tertiary.withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background decorative icon
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Icon(
                      Symbols.devices_rounded,
                      size: 28,
                      color: primary.withValues(alpha: 0.15),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Icon(
                      Symbols.screenshot_rounded,
                      size: 24,
                      color: tertiary.withValues(alpha: 0.15),
                    ),
                  ),
                  // Main icon
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [primary, tertiary],
                    ).createShader(bounds),
                    child: const Icon(
                      Symbols.add_photo_alternate_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  theme.colorScheme.onSurface,
                  theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ],
              ).createShader(bounds),
              child: Text(
                context.l10n.noDesignsYet,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              context.l10n.createYourFirstDesign,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Feature chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _FeatureChip(
                  icon: Symbols.phone_iphone_rounded,
                  label: context.l10n.deviceFrames,
                  primary: primary,
                ),
                _FeatureChip(
                  icon: Symbols.gradient_rounded,
                  label: context.l10n.gradients,
                  primary: primary,
                ),
                _FeatureChip(
                  icon: Symbols.text_fields_rounded,
                  label: context.l10n.textOverlays,
                  primary: primary,
                ),
                _FeatureChip(
                  icon: Symbols.auto_awesome_rounded,
                  label: context.l10n.doodles,
                  primary: primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.2 : 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
