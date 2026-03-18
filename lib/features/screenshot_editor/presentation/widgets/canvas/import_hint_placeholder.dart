import 'dart:io';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Visual placeholder that educates users how to import screenshots.
///
/// Tap handling is done by the parent [GestureDetector] in [EditorCanvas].
///
/// On Desktop: "Drag screenshots here" + "or click here to import"
/// On Mobile:  "Tap to import screenshot"
class ImportHintPlaceholder extends StatelessWidget {
  const ImportHintPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    final l10n = context.l10n;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        color: const Color(0xFF1C1C1E),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Symbols.add_photo_alternate_rounded,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary text
                  Text(
                    isDesktop
                        ? l10n.dragScreenshotsHint
                        : l10n.tapImportHintMobile,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: 8),
                    // Secondary text
                    Text(
                      l10n.tapImportHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
