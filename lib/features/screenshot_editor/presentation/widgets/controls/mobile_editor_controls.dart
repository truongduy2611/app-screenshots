import 'package:app_screenshots/core/extensions/context_extensions.dart';

import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/ai_assistant_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/background_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/doodle_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/frame_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/text_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/translation_controls.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

/// Height of the drag-handle pill area at the top of the panel.
const _kHandleHeight = 16.0;

/// Index of the Text tab — used externally to auto-select when an overlay
/// is tapped on the canvas.
const kTextTabIndex = 2;

/// Default collapsed height of the mobile editor controls panel.
const kMobileControlsCollapsedHeight = 56.0 + _kHandleHeight;

/// Persistent bottom control panel for mobile editor.
///
/// Replaces the old FAB → tool-picker → control-sheet two-tap flow with a
/// single-tap tab bar and a collapsible panel that keeps the canvas visible.
/// Supports drag-to-expand and drag-to-collapse gestures on the handle area.
class MobileEditorControls extends StatefulWidget {
  const MobileEditorControls({super.key});

  @override
  State<MobileEditorControls> createState() => MobileEditorControlsState();
}

class MobileEditorControlsState extends State<MobileEditorControls>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  late final AnimationController _heightController;
  int _selectedIndex = 0;

  /// Exposes the panel's current pixel height so parents can add
  /// matching bottom padding to the canvas.
  final panelHeightNotifier = ValueNotifier<double>(_collapsedHeight);

  /// 0 = collapsed, 1 = fully expanded
  bool get _isExpanded => _heightController.value > 0.5;

  static const _collapsedHeight = 56.0 + _kHandleHeight;
  static const _dragThreshold = 0.3; // fraction of panel height to trigger snap
  static const _velocityThreshold = 300.0; // pixels/sec for fling

  double _expandedPanelHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.42;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _pageController = PageController();
    _tabController.addListener(_onTabChanged);

    _heightController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          value: 0, // start collapsed
        )..addListener(() {
          setState(() {});
          _updatePanelHeight();
        });
  }

  void _updatePanelHeight() {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return;
    final bottomPadding = mq.padding.bottom;
    final expandedPanelHeight = mq.size.height * 0.42;
    panelHeightNotifier.value =
        _collapsedHeight +
        bottomPadding * (1 - _heightController.value) +
        expandedPanelHeight * _heightController.value;
  }

  @override
  void dispose() {
    panelHeightNotifier.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newIndex = _tabController.index;
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Expand the panel and switch to the given tab index.
  /// Called externally when e.g. an overlay is selected on the canvas.
  void selectTab(int index) {
    setState(() => _selectedIndex = index);
    _heightController.animateTo(1, curve: Curves.easeOutCubic);
    _tabController.animateTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex && _isExpanded) {
      // Tapping the active tab collapses the panel
      _heightController.animateTo(0, curve: Curves.easeOutCubic);
    } else {
      setState(() => _selectedIndex = index);
      _heightController.animateTo(1, curve: Curves.easeOutCubic);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ── Drag handling ──

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final panelHeight = _expandedPanelHeight(context);
    // Dragging up (negative dy) → expand (increase value)
    // Dragging down (positive dy) → collapse (decrease value)
    final delta = -details.primaryDelta! / panelHeight;
    _heightController.value = (_heightController.value + delta).clamp(0.0, 1.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > _velocityThreshold) {
      // Fling: up = expand, down = collapse
      if (velocity < 0) {
        _heightController.animateTo(1, curve: Curves.easeOutCubic);
      } else {
        _heightController.animateTo(0, curve: Curves.easeOutCubic);
      }
    } else {
      // Snap based on distance
      if (_heightController.value > _dragThreshold) {
        _heightController.animateTo(1, curve: Curves.easeOutCubic);
      } else {
        _heightController.animateTo(0, curve: Curves.easeOutCubic);
      }
    }
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _heightController.animateTo(0, curve: Curves.easeOutCubic);
    } else {
      _heightController.animateTo(1, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final expandedPanelHeight = _expandedPanelHeight(context);

    // Interpolate between collapsed and expanded heights
    final currentHeight =
        _collapsedHeight +
        bottomPadding * (1 - _heightController.value) +
        expandedPanelHeight * _heightController.value;

    final tabs = [
      _MobileTab(icon: Symbols.format_paint_rounded, label: l10n.background),
      _MobileTab(icon: Symbols.phone_iphone_rounded, label: l10n.frame),
      _MobileTab(icon: Symbols.text_fields_rounded, label: l10n.textOverlay),
      _MobileTab(icon: Symbols.draw_rounded, label: l10n.doodle),
      _MobileTab(icon: Symbols.auto_awesome_rounded, label: l10n.aiAssistant),
      _MobileTab(icon: Symbols.translate_rounded, label: 'Translation'),
    ];

    return SizedBox(
      height: currentHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Drag handle + Tab bar (draggable area) ──
            GestureDetector(
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle pill
                  GestureDetector(
                    onTap: _toggleExpanded,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: double.infinity,
                      height: _kHandleHeight,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tab bar
                  SizedBox(
                    height: _collapsedHeight - _kHandleHeight,
                    child: Row(
                      children: List.generate(tabs.length, (i) {
                        final tab = tabs[i];
                        final isActive = i == _selectedIndex && _isExpanded;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onTabTapped(i),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: 20,
                                    weight: isActive ? 400 : 300,
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tab.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  // Bottom indicator pill
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    width: isActive ? 20 : 0,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // ── Panel content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                  _tabController.animateTo(index);
                },
                children: const [
                  BackgroundControls(),
                  FrameControls(),
                  TextControls(),
                  DoodleControls(),
                  AiAssistantControls(),
                  TranslationControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTab {
  const _MobileTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
