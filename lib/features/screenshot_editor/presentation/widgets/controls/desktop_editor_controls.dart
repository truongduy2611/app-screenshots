import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/ai_assistant_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/background_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/doodle_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/frame_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/text_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/translation_controls.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

const _tabContents = <Widget>[
  BackgroundControls(),
  FrameControls(),
  TextControls(),
  DoodleControls(),
  AiAssistantControls(),
  TranslationControls(),
];

const _tabIcons = <IconData>[
  Symbols.format_paint_rounded,
  Symbols.phone_iphone_rounded,
  Symbols.text_fields_rounded,
  Symbols.gesture_rounded,
  Symbols.auto_awesome_rounded,
  Symbols.translate_rounded,
];

class DesktopEditorControls extends StatefulWidget {
  const DesktopEditorControls({super.key});

  @override
  State<DesktopEditorControls> createState() => _DesktopEditorControlsState();
}

class _DesktopEditorControlsState extends State<DesktopEditorControls>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: index.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..reset()
      ..forward();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = [
      context.l10n.background,
      context.l10n.frame,
      context.l10n.text,
      context.l10n.doodle,
      context.l10n.aiAssistant,
      'Translation',
    ];
    final selectedLabel = labels[_selectedIndex];
    final selectedContent = _tabContents[_selectedIndex];
    final count = _tabIcons.length;

    return Column(
      children: [
        // Segmented tab selector with sliding pill
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / count;

                return AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // Sliding pill indicator
                        Positioned(
                          left: _slideAnimation.value * segmentWidth,
                          top: 0,
                          bottom: 0,
                          width: segmentWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tab icons
                        Row(
                          children: List.generate(count, (i) {
                            final icon = _tabIcons[i];
                            final isSelected = i == _selectedIndex;

                            return Expanded(
                              child: Tooltip(
                                message: labels[i],
                                waitDuration: const Duration(milliseconds: 500),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _selectTab(i),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 20,
                                        weight: 300,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              selectedLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Divider(
          height: 8,
          indent: 16,
          endIndent: 16,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [...previousChildren, ?currentChild],
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: selectedContent,
            ),
          ),
        ),
      ],
    );
  }
}
