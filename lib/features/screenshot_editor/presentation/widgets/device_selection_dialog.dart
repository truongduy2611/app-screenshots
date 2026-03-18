import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Human-readable names for App Store Connect display types.
const _displayTypeNames = <String, String>{
  // iPhone
  'APP_IPHONE_69': 'iPhone 17 Pro Max',
  'APP_IPHONE_67': 'iPhone 16 Pro Max',
  'APP_IPHONE_65': 'iPhone 15/16 Plus',
  'APP_IPHONE_61': 'iPhone 15/16/17',
  'APP_IPHONE_58': 'iPhone 14 Pro / 13 / 12',
  'APP_IPHONE_55': 'iPhone 8 Plus',
  'APP_IPHONE_47': 'iPhone SE / 8',
  'APP_IPHONE_40': 'iPhone SE (1st gen)',
  'APP_IPHONE_35': 'iPhone 4s',
  // iPad
  'APP_IPAD_PRO_3GEN_129': 'iPad Pro 12.9"',
  'APP_IPAD_PRO_3GEN_11': 'iPad Pro 11"',
  'APP_IPAD_PRO_129': 'iPad Pro 12.9" (2nd)',
  'APP_IPAD_105': 'iPad Air 10.5"',
  'APP_IPAD_97': 'iPad 9.7"',
  // Mac
  'APP_DESKTOP': 'Mac',
  // Watch
  'APP_WATCH_ULTRA': 'Apple Watch Ultra 3',
  'APP_WATCH_S11_46MM': 'Watch S11 46mm',
  'APP_WATCH_S11_42MM': 'Watch S11 42mm',
  // TV
  'APP_APPLE_TV': 'Apple TV',
  // Android
  'ANDROID_PHONE': 'Phone (Modern)',
  'ANDROID_PHONE_1080': 'Phone (1080p)',
  'ANDROID_TABLET_7': 'Tablet 7"',
  'ANDROID_TABLET_10': 'Tablet 10"',
  // X / Twitter
  'TWITTER_POST': 'Post Image',
  'TWITTER_HEADER': 'Profile Header',
  'TWITTER_CARD': 'Card Image',
  // Instagram
  'INSTAGRAM_SQUARE': 'Square Post',
  'INSTAGRAM_PORTRAIT': 'Portrait Post',
  'INSTAGRAM_STORY': 'Story / Reel',
  'INSTAGRAM_LANDSCAPE': 'Landscape Post',
  // Facebook
  'FACEBOOK_POST': 'Post Image',
  'FACEBOOK_COVER': 'Cover Photo',
  'FACEBOOK_STORY': 'Story',
  // LinkedIn
  'LINKEDIN_POST': 'Post Image',
  'LINKEDIN_COVER': 'Cover Banner',
  // YouTube
  'YOUTUBE_THUMBNAIL': 'Thumbnail',
  'YOUTUBE_BANNER': 'Channel Banner',
  // TikTok
  'TIKTOK_VIDEO': 'Video Cover',
  // Threads
  'THREADS_POST': 'Post Image',
  // Generic
  'GENERIC_SQUARE': 'Square (1:1)',
  'GENERIC_16_9': 'FHD (16:9)',
  'GENERIC_4K': '4K (16:9)',
  'GENERIC_ULTRAWIDE': 'Ultrawide (21:9)',
};

/// Returns a user-friendly name for a display type.
String _friendlyName(String type) {
  return _displayTypeNames[type] ?? type.replaceAll('_', ' ');
}

class DeviceSelectionDialog extends StatefulWidget {
  final List<String> excludedTypes;
  final bool asPage;

  const DeviceSelectionDialog({
    super.key,
    this.excludedTypes = const [],
    this.asPage = false,
  });

  /// Shows the device selection as a dialog on wide screens (≥ 600 px) or
  /// pushes a full-page route on small / mobile screens.
  ///
  /// When [sourceRect] is provided, a genie animation is used to make the
  /// dialog appear to emerge from the source widget (e.g. the FAB button).
  static Future<String?> show(
    BuildContext context, {
    List<String> excludedTypes = const [],
    Rect? sourceRect,
  }) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    if (isSmallScreen) {
      // Full-page route with genie transition when sourceRect is available
      if (sourceRect != null) {
        return Navigator.of(context).push<String>(
          geniePageRoute<String>(
            sourceRect: sourceRect,
            builder: (_) => DeviceSelectionDialog(
              excludedTypes: excludedTypes,
              asPage: true,
            ),
          ),
        );
      }
      return Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => DeviceSelectionDialog(
            excludedTypes: excludedTypes,
            asPage: true,
          ),
        ),
      );
    }

    // Dialog mode with genie animation when sourceRect is available
    if (sourceRect != null) {
      return showGenieDialog<String>(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => DeviceSelectionDialog(excludedTypes: excludedTypes),
      );
    }

    return showDialog<String>(
      context: context,
      builder: (_) => DeviceSelectionDialog(excludedTypes: excludedTypes),
    );
  }

  @override
  State<DeviceSelectionDialog> createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  static const _prefKeyMultiMode = 'device_selection_multi_mode';

  int _selectedCategoryIndex = 0;
  bool _isMultiMode = false;

  @override
  void initState() {
    super.initState();
    final prefs = GetIt.I<SharedPreferences>();
    _isMultiMode = prefs.getBool(_prefKeyMultiMode) ?? false;
  }

  static final _categoryMeta = <(DeviceCategory, String, IconData)>[
    (DeviceCategory.iphone, 'iPhone', SFIcons.sf_iphone),
    (DeviceCategory.ipad, 'iPad', SFIcons.sf_ipad),
    (DeviceCategory.mac, 'Mac', SFIcons.sf_macbook),
    (DeviceCategory.watch, 'Watch', SFIcons.sf_applewatch),
    (DeviceCategory.tv, 'TV', SFIcons.sf_appletv),
    (DeviceCategory.android, 'Android', Symbols.phone_android_rounded),
    (DeviceCategory.twitter, 'X/Twitter', Symbols.share_rounded),
    (DeviceCategory.instagram, 'Instagram', Symbols.photo_camera_rounded),
    (DeviceCategory.facebook, 'Facebook', Symbols.public_rounded),
    (DeviceCategory.linkedin, 'LinkedIn', Symbols.work_rounded),
    (DeviceCategory.youtube, 'YouTube', Symbols.play_circle_rounded),
    (DeviceCategory.tiktok, 'TikTok', Symbols.music_note_rounded),
    (DeviceCategory.threads, 'Threads', Symbols.forum_rounded),
    (DeviceCategory.generic, 'Generic', Symbols.aspect_ratio_rounded),
  ];

  /// Categories that are grouped under the "Others" chip.
  static const _socialCategories = {
    DeviceCategory.twitter,
    DeviceCategory.instagram,
    DeviceCategory.facebook,
    DeviceCategory.linkedin,
    DeviceCategory.youtube,
    DeviceCategory.tiktok,
    DeviceCategory.threads,
    DeviceCategory.generic,
  };

  /// Human-readable labels for each social sub-group.
  static const _socialGroupLabels = <DeviceCategory, (String, IconData)>{
    DeviceCategory.twitter: ('X / Twitter', Symbols.share_rounded),
    DeviceCategory.instagram: ('Instagram', Symbols.photo_camera_rounded),
    DeviceCategory.facebook: ('Facebook', Symbols.public_rounded),
    DeviceCategory.linkedin: ('LinkedIn', Symbols.work_rounded),
    DeviceCategory.youtube: ('YouTube', Symbols.play_circle_rounded),
    DeviceCategory.tiktok: ('TikTok', Symbols.music_note_rounded),
    DeviceCategory.threads: ('Threads', Symbols.forum_rounded),
    DeviceCategory.generic: ('Generic', Symbols.aspect_ratio_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Build category → devices map.
    // Merge all social/generic categories under the "Others" umbrella
    // (represented by DeviceCategory.twitter).
    final Map<DeviceCategory, List<String>> devicesByCategory = {};
    for (var key in ScreenshotUtils.allDisplayTypes) {
      if (widget.excludedTypes.contains(key)) continue;
      var category = ScreenshotUtils.getDeviceCategory(key);
      if (_socialCategories.contains(category)) {
        category = DeviceCategory.twitter; // merge into one tab
      }
      devicesByCategory.putIfAbsent(category, () => []).add(key);
    }

    // Visible category tabs: Apple devices + Android + one "Others" chip.
    // We use a separate list so we can rename the twitter entry to "Others".
    final visibleCategories = <(DeviceCategory, String, IconData)>[
      for (final c in _categoryMeta)
        if (!_socialCategories.contains(c.$1))
          if (devicesByCategory[c.$1]?.isNotEmpty ?? false) c,
      // Single "Others" chip for all social/generic
      if (devicesByCategory[DeviceCategory.twitter]?.isNotEmpty ?? false)
        (DeviceCategory.twitter, 'Others', Symbols.dashboard_rounded),
    ];

    if (_selectedCategoryIndex >= visibleCategories.length) {
      _selectedCategoryIndex = 0;
    }

    final currentCategory = visibleCategories[_selectedCategoryIndex];
    final devices = devicesByCategory[currentCategory.$1] ?? [];
    final isOthersTab =
        currentCategory.$1 == DeviceCategory.twitter &&
        currentCategory.$2 == 'Others';

    final content = _buildContent(
      context,
      theme: theme,
      primary: primary,
      activeCategories: visibleCategories,
      currentCategory: currentCategory,
      devices: devices,
      isOthersTab: isOthersTab,
    );

    // ── Full-page mode (mobile / small screens) ──
    if (widget.asPage) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.selectDevice),
          centerTitle: true,
        ),
        body: content,
      );
    }

    // ── Dialog mode (desktop / wide screens) ──
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.15),
                          theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Symbols.devices_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.selectDevice,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.chooseScreenSize,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required ThemeData theme,
    required Color primary,
    required List<(DeviceCategory, String, IconData)> activeCategories,
    required (DeviceCategory, String, IconData) currentCategory,
    required List<String> devices,
    bool isOthersTab = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category chips
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: activeCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = activeCategories[index];
              final isSF =
                  cat.$1 == DeviceCategory.ipad ||
                  cat.$1 == DeviceCategory.iphone ||
                  cat.$1 == DeviceCategory.mac ||
                  cat.$1 == DeviceCategory.watch ||
                  cat.$1 == DeviceCategory.tv;
              final isSelected = index == _selectedCategoryIndex;

              return FilterChip(
                mouseCursor: SystemMouseCursors.click,
                selected: isSelected,
                showCheckmark: false,
                avatar: SizedBox(
                  width: 20,
                  height: 20,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isSF ? SFIcon(cat.$3, fontSize: 20) : Icon(cat.$3),
                  ),
                ),
                label: Text(cat.$2),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                onSelected: (_) {
                  setState(() => _selectedCategoryIndex = index);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Multi-Screenshot option ↔ back-button sub-header
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          crossFadeState: _isMultiMode
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _MultiScreenshotCard(
              onTap: () {
                setState(() => _isMultiMode = true);
                GetIt.I<SharedPreferences>().setBool(_prefKeyMultiMode, true);
              },
            ),
          ),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Symbols.arrow_back_rounded, size: 20),
                    onPressed: () {
                      setState(() => _isMultiMode = false);
                      GetIt.I<SharedPreferences>().setBool(
                        _prefKeyMultiMode,
                        false,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.pickScreenSize,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Divider label
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isMultiMode ? 0.0 : 1.0,
            child: _isMultiMode
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(40, 14, 40, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.l10n.orPickDeviceSize,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.35,
                              ),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 4),

        // Device list
        Flexible(
          child: isOthersTab
              ? _buildGroupedDeviceList(
                  context,
                  devices: devices,
                  currentCategory: currentCategory,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  itemCount: devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final type = devices[index];
                    final dims = ScreenshotUtils.getDimensions(
                      type,
                      Orientation.portrait,
                    );
                    final name = _friendlyName(type);
                    return _DeviceCard(
                      name: name,
                      dimensions:
                          '${dims.width.toInt()} × ${dims.height.toInt()}',
                      icon: currentCategory.$3,
                      isLocked: false,
                      onTap: () {
                        Navigator.pop(
                          context,
                          _isMultiMode ? 'multi:$type' : type,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Builds a scrollable list for the "Others" tab, grouping device types
  /// by their original platform category with sub-headers.
  Widget _buildGroupedDeviceList(
    BuildContext context, {
    required List<String> devices,
    required (DeviceCategory, String, IconData) currentCategory,
  }) {
    final theme = Theme.of(context);
    // Group devices by their original (un-merged) category, preserving order.
    final groups = <DeviceCategory, List<String>>{};
    for (final type in devices) {
      final originalCat = ScreenshotUtils.getDeviceCategory(type);
      groups.putIfAbsent(originalCat, () => []).add(type);
    }

    // Build a flat widget list with headers interspersed.
    final items = <Widget>[];
    for (final entry in groups.entries) {
      final label = _socialGroupLabels[entry.key];
      if (label != null) {
        if (items.isNotEmpty) items.add(const SizedBox(height: 12));
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, top: 4),
            child: Row(
              children: [
                Icon(
                  label.$2,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  label.$1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      for (final type in entry.value) {
        final dims = ScreenshotUtils.getDimensions(type, Orientation.portrait);
        final name = _friendlyName(type);
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DeviceCard(
              name: name,
              dimensions: '${dims.width.toInt()} × ${dims.height.toInt()}',
              icon: label?.$2 ?? currentCategory.$3,
              isLocked: false,
              onTap: () {
                Navigator.pop(context, _isMultiMode ? 'multi:$type' : type);
              },
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      children: items,
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String name;
  final String dimensions;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLocked;

  const _DeviceCard({
    required this.name,
    required this.dimensions,
    required this.icon,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dimensions,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isLocked
                    ? Symbols.lock_rounded
                    : Symbols.arrow_forward_ios_rounded,
                size: 16,
                color: isLocked
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiScreenshotCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MultiScreenshotCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary.withValues(alpha: 0.12),
                theme.colorScheme.tertiary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Symbols.photo_library_rounded,
                  size: 20,
                  color: primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.multiScreenshot,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.createUpTo10Screenshots,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.arrow_forward_ios_rounded,
                size: 16,
                color: primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
