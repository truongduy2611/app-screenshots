import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_chip.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Result from the icon picker: codepoint + font info + optional weight.
typedef IconPickerResult = ({
  int codePoint,
  String fontFamily,
  String fontPackage,
  double fontWeight,
});

/// A dialog with SF Symbols / Material tabs, category chips, search,
/// and a color picker. Returns an [IconPickerResult].
class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({super.key});

  static Future<IconPickerResult?> show(
    BuildContext context, {
    Rect? sourceRect,
  }) {
    if (sourceRect != null) {
      return showGenieDialog<IconPickerResult>(
        context: context,
        sourceRect: sourceRect,
        builder: (_) => const IconPickerDialog(),
      );
    }
    return showDialog<IconPickerResult>(
      context: context,
      builder: (_) => const IconPickerDialog(),
    );
  }

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _search = '';
  String? _selectedCategory; // null == "All"
  double _fontWeight = 400;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, parentConstraints) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final isSmall = screenWidth < 600;
          final maxW = isSmall ? screenWidth - 16 : 480.0;
          final maxH = isSmall
              ? MediaQuery.sizeOf(context).height * 0.85
              : 620.0;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.add_reaction_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.addIcon,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Symbols.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.08),
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tabs ──
                TabBar(
                  controller: _tab,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: (_) => setState(() => _selectedCategory = null),
                  tabs: [
                    Tab(text: context.l10n.sfSymbols),
                    Tab(text: context.l10n.materialLabel),
                  ],
                ),

                // ── Search ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchIcons,
                      prefixIcon: const Icon(Symbols.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),

                // ── Grid ──
                Flexible(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildSFGrid(context),
                      _buildMaterialGrid(context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Material tab — curated icons for tree shaking
  // ===========================================================================

  Widget _buildMaterialGrid(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _materialCategories;
    final catNames = categories.keys.toList();
    final allIcons = categories.values.expand((e) => e).toList();

    // Determine visible icons
    List<_MaterialIconEntry> displayIcons;
    if (_search.isNotEmpty) {
      displayIcons = allIcons.where((e) => e.name.contains(_search)).toList();
    } else if (_selectedCategory != null &&
        categories.containsKey(_selectedCategory)) {
      displayIcons = categories[_selectedCategory]!;
    } else {
      displayIcons = allIcons;
    }

    return Column(
      children: [
        // Weight slider
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Row(
            children: [
              Text(context.l10n.weightLabel, style: theme.textTheme.labelSmall),
              Expanded(
                child: Slider(
                  value: _fontWeight,
                  min: 100,
                  max: 700,
                  divisions: 6,
                  label: _fontWeight.round().toString(),
                  onChanged: (v) => setState(() => _fontWeight = v),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  _fontWeight.round().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category chips
        if (_search.isEmpty)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AppChip(
                    compact: true,
                    label: 'All (${allIcons.length})',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                ),
                ...catNames.map((cat) {
                  final count = categories[cat]!.length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AppChip(
                      compact: true,
                      label: '$cat ($count)',
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  );
                }),
              ],
            ),
          ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 5 : 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: displayIcons.length,
            itemBuilder: (context, index) {
              final entry = displayIcons[index];
              return Tooltip(
                message: entry.name,
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => Navigator.pop<IconPickerResult>(context, (
                      codePoint: entry.iconData.codePoint,
                      fontFamily: 'MaterialSymbolsRounded',
                      fontPackage: 'material_symbols_icons',
                      fontWeight: _fontWeight,
                    )),
                    child: Center(
                      child: Icon(
                        entry.iconData,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                        weight: _fontWeight,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SF Symbols tab — curated list (no metadata API available)
  // ===========================================================================

  Widget _buildSFGrid(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _sfCategories;
    final allIcons = categories.values.expand((e) => e).toList();
    final catNames = categories.keys.toList();

    List<_SFIconEntry> displayIcons;
    if (_search.isNotEmpty) {
      displayIcons = allIcons.where((e) => e.name.contains(_search)).toList();
    } else if (_selectedCategory != null &&
        categories.containsKey(_selectedCategory)) {
      displayIcons = categories[_selectedCategory]!;
    } else {
      displayIcons = allIcons;
    }

    return Column(
      children: [
        if (_search.isEmpty)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AppChip(
                    compact: true,
                    label: 'All (${allIcons.length})',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                ),
                ...catNames.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AppChip(
                      compact: true,
                      label: '$cat (${categories[cat]!.length})',
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  );
                }),
              ],
            ),
          ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 5 : 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: displayIcons.length,
            itemBuilder: (context, index) {
              final entry = displayIcons[index];
              return Tooltip(
                message: entry.name,
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => Navigator.pop<IconPickerResult>(context, (
                      codePoint: entry.iconData.codePoint,
                      fontFamily: 'sficons',
                      fontPackage: 'flutter_sficon',
                      fontWeight: 400,
                    )),
                    child: Center(
                      child: SFIcon(
                        entry.iconData,
                        fontSize: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Material icon entry (curated — uses Symbols.* for tree shaking)
// =============================================================================

class _MaterialIconEntry {
  final String name;
  final IconData iconData;
  const _MaterialIconEntry(this.name, this.iconData);
}

// =============================================================================
// SF Icon entry
// =============================================================================

class _SFIconEntry {
  final String name;
  final IconData iconData;
  const _SFIconEntry(this.name, this.iconData);
}

// =============================================================================
// Material Symbols — curated ~300 popular icons (enables tree shaking)
// =============================================================================

final Map<String, List<_MaterialIconEntry>> _materialCategories = {
  'General': [
    _MaterialIconEntry('star', Symbols.star_rounded),
    _MaterialIconEntry('favorite', Symbols.favorite_rounded),
    _MaterialIconEntry('bookmark', Symbols.bookmark_rounded),
    _MaterialIconEntry('flag', Symbols.flag_rounded),
    _MaterialIconEntry('label', Symbols.label_rounded),
    _MaterialIconEntry('lightbulb', Symbols.lightbulb_rounded),
    _MaterialIconEntry('bolt', Symbols.bolt_rounded),
    _MaterialIconEntry('diamond', Symbols.diamond_rounded),
    _MaterialIconEntry('eco', Symbols.eco_rounded),
    _MaterialIconEntry('rocket launch', Symbols.rocket_launch_rounded),
    _MaterialIconEntry('emoji objects', Symbols.emoji_objects_rounded),
    _MaterialIconEntry('auto awesome', Symbols.auto_awesome_rounded),
    _MaterialIconEntry('workspace premium', Symbols.workspace_premium_rounded),
    _MaterialIconEntry('verified', Symbols.verified_rounded),
    _MaterialIconEntry('new releases', Symbols.new_releases_rounded),
    _MaterialIconEntry('loyalty', Symbols.loyalty_rounded),
    _MaterialIconEntry('token', Symbols.token_rounded),
    _MaterialIconEntry('thumb up', Symbols.thumb_up_rounded),
    _MaterialIconEntry('thumb down', Symbols.thumb_down_rounded),
    _MaterialIconEntry('push pin', Symbols.push_pin_rounded),
    _MaterialIconEntry('grade', Symbols.grade_rounded),
    _MaterialIconEntry('pets', Symbols.pets_rounded),
    _MaterialIconEntry('spa', Symbols.spa_rounded),
    _MaterialIconEntry(
      'local fire department',
      Symbols.local_fire_department_rounded,
    ),
    _MaterialIconEntry('celebration', Symbols.celebration_rounded),
  ],
  'Communication': [
    _MaterialIconEntry('chat', Symbols.chat_rounded),
    _MaterialIconEntry('message', Symbols.message_rounded),
    _MaterialIconEntry('mail', Symbols.mail_rounded),
    _MaterialIconEntry('call', Symbols.call_rounded),
    _MaterialIconEntry('send', Symbols.send_rounded),
    _MaterialIconEntry('forum', Symbols.forum_rounded),
    _MaterialIconEntry('chat bubble', Symbols.chat_bubble_rounded),
    _MaterialIconEntry('notifications', Symbols.notifications_rounded),
    _MaterialIconEntry(
      'notifications active',
      Symbols.notifications_active_rounded,
    ),
    _MaterialIconEntry('campaign', Symbols.campaign_rounded),
    _MaterialIconEntry('contact mail', Symbols.contact_mail_rounded),
    _MaterialIconEntry('contact phone', Symbols.contact_phone_rounded),
    _MaterialIconEntry('contacts', Symbols.contacts_rounded),
    _MaterialIconEntry('mark email read', Symbols.mark_email_read_rounded),
    _MaterialIconEntry('alternate email', Symbols.alternate_email_rounded),
    _MaterialIconEntry('rss feed', Symbols.rss_feed_rounded),
    _MaterialIconEntry('podcasts', Symbols.podcasts_rounded),
    _MaterialIconEntry('sms', Symbols.sms_rounded),
    _MaterialIconEntry('comment', Symbols.comment_rounded),
    _MaterialIconEntry('translate', Symbols.translate_rounded),
  ],
  'Media': [
    _MaterialIconEntry('camera', Symbols.camera_rounded),
    _MaterialIconEntry('photo camera', Symbols.photo_camera_rounded),
    _MaterialIconEntry('image', Symbols.image_rounded),
    _MaterialIconEntry('photo library', Symbols.photo_library_rounded),
    _MaterialIconEntry('videocam', Symbols.videocam_rounded),
    _MaterialIconEntry('music note', Symbols.music_note_rounded),
    _MaterialIconEntry('headphones', Symbols.headphones_rounded),
    _MaterialIconEntry('mic', Symbols.mic_rounded),
    _MaterialIconEntry('play arrow', Symbols.play_arrow_rounded),
    _MaterialIconEntry('pause', Symbols.pause_rounded),
    _MaterialIconEntry('skip next', Symbols.skip_next_rounded),
    _MaterialIconEntry('skip previous', Symbols.skip_previous_rounded),
    _MaterialIconEntry('stop', Symbols.stop_rounded),
    _MaterialIconEntry('replay', Symbols.replay_rounded),
    _MaterialIconEntry('volume up', Symbols.volume_up_rounded),
    _MaterialIconEntry('volume off', Symbols.volume_off_rounded),
    _MaterialIconEntry('movie', Symbols.movie_rounded),
    _MaterialIconEntry('slideshow', Symbols.slideshow_rounded),
    _MaterialIconEntry('album', Symbols.album_rounded),
    _MaterialIconEntry('equalizer', Symbols.equalizer_rounded),
    _MaterialIconEntry('radio', Symbols.radio_rounded),
    _MaterialIconEntry('slow motion video', Symbols.slow_motion_video_rounded),
    _MaterialIconEntry('library music', Symbols.library_music_rounded),
  ],
  'Devices': [
    _MaterialIconEntry('phone iphone', Symbols.phone_iphone_rounded),
    _MaterialIconEntry('tablet mac', Symbols.tablet_mac_rounded),
    _MaterialIconEntry('laptop mac', Symbols.laptop_mac_rounded),
    _MaterialIconEntry('desktop mac', Symbols.desktop_mac_rounded),
    _MaterialIconEntry('watch', Symbols.watch_rounded),
    _MaterialIconEntry('keyboard', Symbols.keyboard_rounded),
    _MaterialIconEntry('mouse', Symbols.mouse_rounded),
    _MaterialIconEntry('print', Symbols.print_rounded),
    _MaterialIconEntry('tv', Symbols.tv_rounded),
    _MaterialIconEntry('monitor', Symbols.monitor_rounded),
    _MaterialIconEntry('smartphone', Symbols.smartphone_rounded),
    _MaterialIconEntry('headset', Symbols.headset_rounded),
    _MaterialIconEntry('speaker', Symbols.speaker_rounded),
    _MaterialIconEntry('memory', Symbols.memory_rounded),
    _MaterialIconEntry('router', Symbols.router_rounded),
    _MaterialIconEntry('devices', Symbols.devices_rounded),
    _MaterialIconEntry('videogame asset', Symbols.videogame_asset_rounded),
    _MaterialIconEntry('cast', Symbols.cast_rounded),
    _MaterialIconEntry('bluetooth', Symbols.bluetooth_rounded),
    _MaterialIconEntry('usb', Symbols.usb_rounded),
  ],
  'People': [
    _MaterialIconEntry('person', Symbols.person_rounded),
    _MaterialIconEntry('people', Symbols.people_rounded),
    _MaterialIconEntry('group', Symbols.group_rounded),
    _MaterialIconEntry('groups', Symbols.groups_rounded),
    _MaterialIconEntry('person add', Symbols.person_add_rounded),
    _MaterialIconEntry('face', Symbols.face_rounded),
    _MaterialIconEntry('emoji emotions', Symbols.emoji_emotions_rounded),
    _MaterialIconEntry('emoji people', Symbols.emoji_people_rounded),
    _MaterialIconEntry('accessibility', Symbols.accessibility_rounded),
    _MaterialIconEntry('self improvement', Symbols.self_improvement_rounded),
    _MaterialIconEntry('diversity 3', Symbols.diversity_3_rounded),
    _MaterialIconEntry(
      'supervisor account',
      Symbols.supervisor_account_rounded,
    ),
    _MaterialIconEntry('waving hand', Symbols.waving_hand_rounded),
    _MaterialIconEntry('handshake', Symbols.handshake_rounded),
    _MaterialIconEntry('person search', Symbols.person_search_rounded),
    _MaterialIconEntry('child care', Symbols.child_care_rounded),
    _MaterialIconEntry('elderly', Symbols.elderly_rounded),
    _MaterialIconEntry('school', Symbols.school_rounded),
    _MaterialIconEntry('psychology', Symbols.psychology_rounded),
    _MaterialIconEntry('support agent', Symbols.support_agent_rounded),
  ],
  'Nature': [
    _MaterialIconEntry('sunny', Symbols.sunny_rounded),
    _MaterialIconEntry('dark mode', Symbols.dark_mode_rounded),
    _MaterialIconEntry('cloud', Symbols.cloud_rounded),
    _MaterialIconEntry('thunderstorm', Symbols.thunderstorm_rounded),
    _MaterialIconEntry('water drop', Symbols.water_drop_rounded),
    _MaterialIconEntry('air', Symbols.air_rounded),
    _MaterialIconEntry('ac unit', Symbols.ac_unit_rounded),
    _MaterialIconEntry('forest', Symbols.forest_rounded),
    _MaterialIconEntry('park', Symbols.park_rounded),
    _MaterialIconEntry('grass', Symbols.grass_rounded),
    _MaterialIconEntry('landscape', Symbols.landscape_rounded),
    _MaterialIconEntry('terrain', Symbols.terrain_rounded),
    _MaterialIconEntry('waves', Symbols.waves_rounded),
    _MaterialIconEntry('volcano', Symbols.volcano_rounded),
    _MaterialIconEntry('partly cloudy day', Symbols.partly_cloudy_day_rounded),
    _MaterialIconEntry('wb twilight', Symbols.wb_twilight_rounded),
    _MaterialIconEntry('thermostat', Symbols.thermostat_rounded),
    _MaterialIconEntry('rainy', Symbols.rainy_rounded),
    _MaterialIconEntry('flower', Symbols.local_florist_rounded),
  ],
  'Arrows': [
    _MaterialIconEntry('arrow forward', Symbols.arrow_forward_rounded),
    _MaterialIconEntry('arrow back', Symbols.arrow_back_rounded),
    _MaterialIconEntry('arrow upward', Symbols.arrow_upward_rounded),
    _MaterialIconEntry('arrow downward', Symbols.arrow_downward_rounded),
    _MaterialIconEntry('arrow forward ios', Symbols.arrow_forward_ios_rounded),
    _MaterialIconEntry('arrow back ios', Symbols.arrow_back_ios_rounded),
    _MaterialIconEntry('expand more', Symbols.expand_more_rounded),
    _MaterialIconEntry('expand less', Symbols.expand_less_rounded),
    _MaterialIconEntry('chevron right', Symbols.chevron_right_rounded),
    _MaterialIconEntry('chevron left', Symbols.chevron_left_rounded),
    _MaterialIconEntry('north east', Symbols.north_east_rounded),
    _MaterialIconEntry('south west', Symbols.south_west_rounded),
    _MaterialIconEntry('swap horiz', Symbols.swap_horiz_rounded),
    _MaterialIconEntry('swap vert', Symbols.swap_vert_rounded),
    _MaterialIconEntry('open in new', Symbols.open_in_new_rounded),
    _MaterialIconEntry(
      'subdirectory arrow right',
      Symbols.subdirectory_arrow_right_rounded,
    ),
    _MaterialIconEntry('undo', Symbols.undo_rounded),
    _MaterialIconEntry('redo', Symbols.redo_rounded),
    _MaterialIconEntry('refresh', Symbols.refresh_rounded),
    _MaterialIconEntry('sync', Symbols.sync_rounded),
  ],
  'Commerce': [
    _MaterialIconEntry('shopping cart', Symbols.shopping_cart_rounded),
    _MaterialIconEntry('shopping bag', Symbols.shopping_bag_rounded),
    _MaterialIconEntry('store', Symbols.store_rounded),
    _MaterialIconEntry('storefront', Symbols.storefront_rounded),
    _MaterialIconEntry('payments', Symbols.payments_rounded),
    _MaterialIconEntry('credit card', Symbols.credit_card_rounded),
    _MaterialIconEntry('receipt long', Symbols.receipt_long_rounded),
    _MaterialIconEntry('sell', Symbols.sell_rounded),
    _MaterialIconEntry('local offer', Symbols.local_offer_rounded),
    _MaterialIconEntry('card giftcard', Symbols.card_giftcard_rounded),
    _MaterialIconEntry('attach money', Symbols.attach_money_rounded),
    _MaterialIconEntry('savings', Symbols.savings_rounded),
    _MaterialIconEntry('wallet', Symbols.wallet_rounded),
    _MaterialIconEntry('monetization on', Symbols.monetization_on_rounded),
    _MaterialIconEntry('account balance', Symbols.account_balance_rounded),
    _MaterialIconEntry('trending up', Symbols.trending_up_rounded),
    _MaterialIconEntry('trending down', Symbols.trending_down_rounded),
    _MaterialIconEntry('bar chart', Symbols.bar_chart_rounded),
    _MaterialIconEntry('pie chart', Symbols.pie_chart_rounded),
    _MaterialIconEntry('analytics', Symbols.analytics_rounded),
  ],
  'Security': [
    _MaterialIconEntry('lock', Symbols.lock_rounded),
    _MaterialIconEntry('lock open', Symbols.lock_open_rounded),
    _MaterialIconEntry('key', Symbols.key_rounded),
    _MaterialIconEntry('vpn key', Symbols.vpn_key_rounded),
    _MaterialIconEntry('shield', Symbols.shield_rounded),
    _MaterialIconEntry('security', Symbols.security_rounded),
    _MaterialIconEntry(
      'admin panel settings',
      Symbols.admin_panel_settings_rounded,
    ),
    _MaterialIconEntry('visibility', Symbols.visibility_rounded),
    _MaterialIconEntry('visibility off', Symbols.visibility_off_rounded),
    _MaterialIconEntry('fingerprint', Symbols.fingerprint_rounded),
    _MaterialIconEntry('gpp good', Symbols.gpp_good_rounded),
    _MaterialIconEntry('privacy tip', Symbols.privacy_tip_rounded),
    _MaterialIconEntry(
      'enhanced encryption',
      Symbols.enhanced_encryption_rounded,
    ),
    _MaterialIconEntry('policy', Symbols.policy_rounded),
    _MaterialIconEntry('verified user', Symbols.verified_user_rounded),
    _MaterialIconEntry('password', Symbols.password_rounded),
  ],
  'Travel': [
    _MaterialIconEntry('flight', Symbols.flight_rounded),
    _MaterialIconEntry('directions car', Symbols.directions_car_rounded),
    _MaterialIconEntry('directions bus', Symbols.directions_bus_rounded),
    _MaterialIconEntry('train', Symbols.train_rounded),
    _MaterialIconEntry('directions bike', Symbols.directions_bike_rounded),
    _MaterialIconEntry('directions walk', Symbols.directions_walk_rounded),
    _MaterialIconEntry('map', Symbols.map_rounded),
    _MaterialIconEntry('place', Symbols.place_rounded),
    _MaterialIconEntry('explore', Symbols.explore_rounded),
    _MaterialIconEntry('navigation', Symbols.navigation_rounded),
    _MaterialIconEntry('near me', Symbols.near_me_rounded),
    _MaterialIconEntry('public', Symbols.public_rounded),
    _MaterialIconEntry('language', Symbols.language_rounded),
    _MaterialIconEntry('local airport', Symbols.local_airport_rounded),
    _MaterialIconEntry('hotel', Symbols.hotel_rounded),
    _MaterialIconEntry('restaurant', Symbols.restaurant_rounded),
    _MaterialIconEntry('local cafe', Symbols.local_cafe_rounded),
    _MaterialIconEntry('beach access', Symbols.beach_access_rounded),
    _MaterialIconEntry('sailing', Symbols.sailing_rounded),
    _MaterialIconEntry('directions boat', Symbols.directions_boat_rounded),
  ],
  'Fitness': [
    _MaterialIconEntry('fitness center', Symbols.fitness_center_rounded),
    _MaterialIconEntry('sports', Symbols.sports_rounded),
    _MaterialIconEntry('emoji events', Symbols.emoji_events_rounded),
    _MaterialIconEntry('sports soccer', Symbols.sports_soccer_rounded),
    _MaterialIconEntry('sports basketball', Symbols.sports_basketball_rounded),
    _MaterialIconEntry('sports tennis', Symbols.sports_tennis_rounded),
    _MaterialIconEntry('sports esports', Symbols.sports_esports_rounded),
    _MaterialIconEntry('pool', Symbols.pool_rounded),
    _MaterialIconEntry('timer', Symbols.timer_rounded),
    _MaterialIconEntry('speed', Symbols.speed_rounded),
    _MaterialIconEntry('monitor heart', Symbols.monitor_heart_rounded),
    _MaterialIconEntry('directions run', Symbols.directions_run_rounded),
    _MaterialIconEntry('hiking', Symbols.hiking_rounded),
    _MaterialIconEntry(
      'sports martial arts',
      Symbols.sports_martial_arts_rounded,
    ),
    _MaterialIconEntry('sports gymnastics', Symbols.sports_gymnastics_rounded),
    _MaterialIconEntry('scoreboard', Symbols.scoreboard_rounded),
    _MaterialIconEntry('military tech', Symbols.military_tech_rounded),
  ],
  'Editing': [
    _MaterialIconEntry('edit', Symbols.edit_rounded),
    _MaterialIconEntry('brush', Symbols.brush_rounded),
    _MaterialIconEntry('palette', Symbols.palette_rounded),
    _MaterialIconEntry('format paint', Symbols.format_paint_rounded),
    _MaterialIconEntry('crop', Symbols.crop_rounded),
    _MaterialIconEntry('tune', Symbols.tune_rounded),
    _MaterialIconEntry('auto fix high', Symbols.auto_fix_high_rounded),
    _MaterialIconEntry('draw', Symbols.draw_rounded),
    _MaterialIconEntry('design services', Symbols.design_services_rounded),
    _MaterialIconEntry('color lens', Symbols.color_lens_rounded),
    _MaterialIconEntry('straighten', Symbols.straighten_rounded),
    _MaterialIconEntry('text fields', Symbols.text_fields_rounded),
    _MaterialIconEntry('format bold', Symbols.format_bold_rounded),
    _MaterialIconEntry('format italic', Symbols.format_italic_rounded),
    _MaterialIconEntry('format underlined', Symbols.format_underlined_rounded),
    _MaterialIconEntry('format size', Symbols.format_size_rounded),
    _MaterialIconEntry('format color text', Symbols.format_color_text_rounded),
    _MaterialIconEntry('filter', Symbols.filter_rounded),
    _MaterialIconEntry('opacity', Symbols.opacity_rounded),
    _MaterialIconEntry('content cut', Symbols.content_cut_rounded),
    _MaterialIconEntry('content copy', Symbols.content_copy_rounded),
    _MaterialIconEntry('content paste', Symbols.content_paste_rounded),
  ],
  'System': [
    _MaterialIconEntry('settings', Symbols.settings_rounded),
    _MaterialIconEntry('home', Symbols.home_rounded),
    _MaterialIconEntry('search', Symbols.search_rounded),
    _MaterialIconEntry('menu', Symbols.menu_rounded),
    _MaterialIconEntry('info', Symbols.info_rounded),
    _MaterialIconEntry('help', Symbols.help_rounded),
    _MaterialIconEntry('warning', Symbols.warning_rounded),
    _MaterialIconEntry('error', Symbols.error_rounded),
    _MaterialIconEntry('check circle', Symbols.check_circle_rounded),
    _MaterialIconEntry('cancel', Symbols.cancel_rounded),
    _MaterialIconEntry('add circle', Symbols.add_circle_rounded),
    _MaterialIconEntry('remove circle', Symbols.remove_circle_rounded),
    _MaterialIconEntry('delete', Symbols.delete_rounded),
    _MaterialIconEntry('close', Symbols.close_rounded),
    _MaterialIconEntry('done', Symbols.done_rounded),
    _MaterialIconEntry('add', Symbols.add_rounded),
    _MaterialIconEntry('remove', Symbols.remove_rounded),
    _MaterialIconEntry('more horiz', Symbols.more_horiz_rounded),
    _MaterialIconEntry('more vert', Symbols.more_vert_rounded),
    _MaterialIconEntry(
      'power settings new',
      Symbols.power_settings_new_rounded,
    ),
    _MaterialIconEntry('build', Symbols.build_rounded),
    _MaterialIconEntry('code', Symbols.code_rounded),
    _MaterialIconEntry('terminal', Symbols.terminal_rounded),
    _MaterialIconEntry('bug report', Symbols.bug_report_rounded),
    _MaterialIconEntry('extension', Symbols.extension_rounded),
  ],
  'Files & Data': [
    _MaterialIconEntry('folder', Symbols.folder_rounded),
    _MaterialIconEntry('file', Symbols.description_rounded),
    _MaterialIconEntry('cloud upload', Symbols.cloud_upload_rounded),
    _MaterialIconEntry('cloud download', Symbols.cloud_download_rounded),
    _MaterialIconEntry('download', Symbols.download_rounded),
    _MaterialIconEntry('upload', Symbols.upload_rounded),
    _MaterialIconEntry('save', Symbols.save_rounded),
    _MaterialIconEntry('database', Symbols.database_rounded),
    _MaterialIconEntry('storage', Symbols.storage_rounded),
    _MaterialIconEntry('attach file', Symbols.attach_file_rounded),
    _MaterialIconEntry('link', Symbols.link_rounded),
    _MaterialIconEntry('share', Symbols.share_rounded),
    _MaterialIconEntry('qr code', Symbols.qr_code_rounded),
    _MaterialIconEntry('inventory', Symbols.inventory_rounded),
    _MaterialIconEntry('task', Symbols.task_rounded),
    _MaterialIconEntry('assignment', Symbols.assignment_rounded),
    _MaterialIconEntry('note', Symbols.note_rounded),
    _MaterialIconEntry('article', Symbols.article_rounded),
    _MaterialIconEntry('feed', Symbols.feed_rounded),
    _MaterialIconEntry('backup', Symbols.backup_rounded),
  ],
  'Social': [
    _MaterialIconEntry('share', Symbols.ios_share_rounded),
    _MaterialIconEntry('rate review', Symbols.rate_review_rounded),
    _MaterialIconEntry('reviews', Symbols.reviews_rounded),
    _MaterialIconEntry(
      'volunteer activism',
      Symbols.volunteer_activism_rounded,
    ),
    _MaterialIconEntry(
      'sentiment satisfied',
      Symbols.sentiment_satisfied_rounded,
    ),
    _MaterialIconEntry(
      'sentiment dissatisfied',
      Symbols.sentiment_dissatisfied_rounded,
    ),
    _MaterialIconEntry('mood', Symbols.mood_rounded),
    _MaterialIconEntry('recommend', Symbols.recommend_rounded),
    _MaterialIconEntry('event', Symbols.event_rounded),
    _MaterialIconEntry('cake', Symbols.cake_rounded),
    _MaterialIconEntry('local bar', Symbols.local_bar_rounded),
    _MaterialIconEntry('nightlife', Symbols.nightlife_rounded),
    _MaterialIconEntry('local activity', Symbols.local_activity_rounded),
    _MaterialIconEntry('theater comedy', Symbols.theater_comedy_rounded),
    _MaterialIconEntry('music note', Symbols.music_note_rounded),
    _MaterialIconEntry('piano', Symbols.piano_rounded),
  ],
  'Health': [
    _MaterialIconEntry('health and safety', Symbols.health_and_safety_rounded),
    _MaterialIconEntry('medical services', Symbols.medical_services_rounded),
    _MaterialIconEntry('medication', Symbols.medication_rounded),
    _MaterialIconEntry('local hospital', Symbols.local_hospital_rounded),
    _MaterialIconEntry('monitor heart', Symbols.monitor_heart_rounded),
    _MaterialIconEntry('healing', Symbols.healing_rounded),
    _MaterialIconEntry('bloodtype', Symbols.bloodtype_rounded),
    _MaterialIconEntry('vaccines', Symbols.vaccines_rounded),
    _MaterialIconEntry('science', Symbols.science_rounded),
    _MaterialIconEntry('biotech', Symbols.biotech_rounded),
    _MaterialIconEntry('coronavirus', Symbols.coronavirus_rounded),
    _MaterialIconEntry('emergency', Symbols.emergency_rounded),
  ],
  'Education': [
    _MaterialIconEntry('school', Symbols.school_rounded),
    _MaterialIconEntry('menu book', Symbols.menu_book_rounded),
    _MaterialIconEntry('auto stories', Symbols.auto_stories_rounded),
    _MaterialIconEntry('history edu', Symbols.history_edu_rounded),
    _MaterialIconEntry('calculate', Symbols.calculate_rounded),
    _MaterialIconEntry('architecture', Symbols.architecture_rounded),
    _MaterialIconEntry('science', Symbols.science_rounded),
    _MaterialIconEntry('engineering', Symbols.engineering_rounded),
    _MaterialIconEntry('quiz', Symbols.quiz_rounded),
    _MaterialIconEntry('library books', Symbols.library_books_rounded),
    _MaterialIconEntry('draw', Symbols.draw_rounded),
    _MaterialIconEntry('abc', Symbols.abc_rounded),
  ],
};

// =============================================================================
// SF Symbols — organized by category (curated, no metadata API available)
// =============================================================================

final Map<String, List<_SFIconEntry>> _sfCategories = {
  'General': [
    _SFIconEntry('star', SFIcons.sf_star),
    _SFIconEntry('star.fill', SFIcons.sf_star_fill),
    _SFIconEntry('heart', SFIcons.sf_heart),
    _SFIconEntry('heart.fill', SFIcons.sf_heart_fill),
    _SFIconEntry('bookmark', SFIcons.sf_bookmark),
    _SFIconEntry('bookmark.fill', SFIcons.sf_bookmark_fill),
    _SFIconEntry('flag', SFIcons.sf_flag),
    _SFIconEntry('flag.fill', SFIcons.sf_flag_fill),
    _SFIconEntry('bell', SFIcons.sf_bell),
    _SFIconEntry('bell.fill', SFIcons.sf_bell_fill),
    _SFIconEntry('tag', SFIcons.sf_tag),
    _SFIconEntry('bolt', SFIcons.sf_bolt),
    _SFIconEntry('bolt.fill', SFIcons.sf_bolt_fill),
    _SFIconEntry('pin', SFIcons.sf_pin),
    _SFIconEntry('pin.fill', SFIcons.sf_pin_fill),
    _SFIconEntry('sparkles', SFIcons.sf_sparkles),
    _SFIconEntry('crown', SFIcons.sf_crown),
    _SFIconEntry('crown.fill', SFIcons.sf_crown_fill),
  ],
  'Communication': [
    _SFIconEntry('message', SFIcons.sf_message),
    _SFIconEntry('message.fill', SFIcons.sf_message_fill),
    _SFIconEntry('phone', SFIcons.sf_phone),
    _SFIconEntry('phone.fill', SFIcons.sf_phone_fill),
    _SFIconEntry('envelope', SFIcons.sf_envelope),
    _SFIconEntry('envelope.fill', SFIcons.sf_envelope_fill),
    _SFIconEntry('paperplane', SFIcons.sf_paperplane),
    _SFIconEntry('paperplane.fill', SFIcons.sf_paperplane_fill),
    _SFIconEntry('bubble.left', SFIcons.sf_bubble_left),
    _SFIconEntry('megaphone', SFIcons.sf_megaphone),
    _SFIconEntry('megaphone.fill', SFIcons.sf_megaphone_fill),
    _SFIconEntry(
      'antenna.radiowaves',
      SFIcons.sf_antenna_radiowaves_left_and_right,
    ),
  ],
  'Media': [
    _SFIconEntry('camera', SFIcons.sf_camera),
    _SFIconEntry('camera.fill', SFIcons.sf_camera_fill),
    _SFIconEntry('photo', SFIcons.sf_photo),
    _SFIconEntry('photo.fill', SFIcons.sf_photo_fill),
    _SFIconEntry('video', SFIcons.sf_video),
    _SFIconEntry('video.fill', SFIcons.sf_video_fill),
    _SFIconEntry('music.note', SFIcons.sf_music_note),
    _SFIconEntry('music.note.list', SFIcons.sf_music_note_list),
    _SFIconEntry('mic', SFIcons.sf_microphone),
    _SFIconEntry('mic.fill', SFIcons.sf_microphone_fill),
    _SFIconEntry('play', SFIcons.sf_play),
    _SFIconEntry('play.fill', SFIcons.sf_play_fill),
    _SFIconEntry('pause', SFIcons.sf_pause),
    _SFIconEntry('headphones', SFIcons.sf_headphones),
    _SFIconEntry('speaker.wave.2', SFIcons.sf_speaker_wave_2),
    _SFIconEntry('film', SFIcons.sf_film),
  ],
  'Devices': [
    _SFIconEntry('iphone', SFIcons.sf_iphone),
    _SFIconEntry('ipad', SFIcons.sf_ipad),
    _SFIconEntry('macbook', SFIcons.sf_macbook),
    _SFIconEntry('applewatch', SFIcons.sf_applewatch),
    _SFIconEntry('desktopcomputer', SFIcons.sf_desktopcomputer),
    _SFIconEntry('keyboard', SFIcons.sf_keyboard),
    _SFIconEntry('printer', SFIcons.sf_printer),
    _SFIconEntry('tv', SFIcons.sf_tv),
    _SFIconEntry('gamecontroller', SFIcons.sf_gamecontroller),
    _SFIconEntry('gamecontroller.fill', SFIcons.sf_gamecontroller_fill),
    _SFIconEntry('airpods.pro', SFIcons.sf_airpods_pro),
    _SFIconEntry('homepod', SFIcons.sf_homepod),
  ],
  'People': [
    _SFIconEntry('person', SFIcons.sf_person),
    _SFIconEntry('person.fill', SFIcons.sf_person_fill),
    _SFIconEntry('person.2', SFIcons.sf_person_2),
    _SFIconEntry('person.3', SFIcons.sf_person_3),
    _SFIconEntry('person.crop.circle', SFIcons.sf_person_crop_circle),
    _SFIconEntry('hand.raised', SFIcons.sf_hand_raised),
    _SFIconEntry('hand.thumbsup', SFIcons.sf_hand_thumbsup),
    _SFIconEntry('hand.thumbsdown', SFIcons.sf_hand_thumbsdown),
    _SFIconEntry('hand.wave', SFIcons.sf_hand_wave),
    _SFIconEntry('figure.walk', SFIcons.sf_figure_walk),
    _SFIconEntry('figure.run', SFIcons.sf_figure_run),
    _SFIconEntry('figure.stand', SFIcons.sf_figure_stand),
  ],
  'Nature': [
    _SFIconEntry('sun.max', SFIcons.sf_sun_max),
    _SFIconEntry('sun.max.fill', SFIcons.sf_sun_max_fill),
    _SFIconEntry('moon', SFIcons.sf_moon),
    _SFIconEntry('moon.fill', SFIcons.sf_moon_fill),
    _SFIconEntry('cloud', SFIcons.sf_cloud),
    _SFIconEntry('cloud.fill', SFIcons.sf_cloud_fill),
    _SFIconEntry('cloud.rain', SFIcons.sf_cloud_rain),
    _SFIconEntry('snowflake', SFIcons.sf_snowflake),
    _SFIconEntry('flame', SFIcons.sf_flame),
    _SFIconEntry('flame.fill', SFIcons.sf_flame_fill),
    _SFIconEntry('drop', SFIcons.sf_drop),
    _SFIconEntry('drop.fill', SFIcons.sf_drop_fill),
    _SFIconEntry('leaf', SFIcons.sf_leaf),
    _SFIconEntry('leaf.fill', SFIcons.sf_leaf_fill),
    _SFIconEntry('tree', SFIcons.sf_tree),
    _SFIconEntry('mountain', SFIcons.sf_mountain_2),
  ],
  'Animals': [
    _SFIconEntry('pawprint', SFIcons.sf_pawprint),
    _SFIconEntry('pawprint.fill', SFIcons.sf_pawprint_fill),
    _SFIconEntry('hare', SFIcons.sf_hare),
    _SFIconEntry('tortoise', SFIcons.sf_tortoise),
    _SFIconEntry('ant', SFIcons.sf_ant),
    _SFIconEntry('ant.fill', SFIcons.sf_ant_fill),
    _SFIconEntry('ladybug', SFIcons.sf_ladybug),
    _SFIconEntry('ladybug.fill', SFIcons.sf_ladybug_fill),
    _SFIconEntry('fish', SFIcons.sf_fish),
    _SFIconEntry('bird', SFIcons.sf_bird),
  ],
  'Arrows': [
    _SFIconEntry('arrow.up', SFIcons.sf_arrow_up),
    _SFIconEntry('arrow.down', SFIcons.sf_arrow_down),
    _SFIconEntry('arrow.left', SFIcons.sf_arrow_left),
    _SFIconEntry('arrow.right', SFIcons.sf_arrow_right),
    _SFIconEntry('arrow.up.circle', SFIcons.sf_arrow_up_circle),
    _SFIconEntry('arrow.clockwise', SFIcons.sf_arrow_clockwise),
    _SFIconEntry('arrow.2.squarepath', SFIcons.sf_arrow_2_squarepath),
    _SFIconEntry(
      'arrowshape.turn.up.right',
      SFIcons.sf_arrowshape_turn_up_right,
    ),
    _SFIconEntry('chevron.up', SFIcons.sf_chevron_up),
    _SFIconEntry('chevron.down', SFIcons.sf_chevron_down),
    _SFIconEntry('chevron.left', SFIcons.sf_chevron_left),
    _SFIconEntry('chevron.right', SFIcons.sf_chevron_right),
  ],
  'Commerce': [
    _SFIconEntry('cart', SFIcons.sf_cart),
    _SFIconEntry('cart.fill', SFIcons.sf_cart_fill),
    _SFIconEntry('bag', SFIcons.sf_bag),
    _SFIconEntry('bag.fill', SFIcons.sf_bag_fill),
    _SFIconEntry('creditcard', SFIcons.sf_creditcard),
    _SFIconEntry('creditcard.fill', SFIcons.sf_creditcard_fill),
    _SFIconEntry('gift', SFIcons.sf_gift),
    _SFIconEntry('gift.fill', SFIcons.sf_gift_fill),
    _SFIconEntry('dollarsign.circle', SFIcons.sf_dollarsign_circle),
    _SFIconEntry('percent', SFIcons.sf_percent),
    _SFIconEntry('chart.bar', SFIcons.sf_chart_bar),
    _SFIconEntry('chart.line.uptrend', SFIcons.sf_chart_line_uptrend_xyaxis),
  ],
  'Security': [
    _SFIconEntry('lock', SFIcons.sf_lock),
    _SFIconEntry('lock.fill', SFIcons.sf_lock_fill),
    _SFIconEntry('lock.open', SFIcons.sf_lock_open),
    _SFIconEntry('key', SFIcons.sf_key),
    _SFIconEntry('key.fill', SFIcons.sf_key_fill),
    _SFIconEntry('shield', SFIcons.sf_shield),
    _SFIconEntry('shield.fill', SFIcons.sf_shield_fill),
    _SFIconEntry('checkmark.shield', SFIcons.sf_checkmark_shield),
    _SFIconEntry('eye', SFIcons.sf_eye),
    _SFIconEntry('eye.fill', SFIcons.sf_eye_fill),
    _SFIconEntry('eye.slash', SFIcons.sf_eye_slash),
  ],
  'Travel': [
    _SFIconEntry('airplane', SFIcons.sf_airplane),
    _SFIconEntry('car', SFIcons.sf_car),
    _SFIconEntry('car.fill', SFIcons.sf_car_fill),
    _SFIconEntry('bicycle', SFIcons.sf_bicycle),
    _SFIconEntry('bus', SFIcons.sf_bus),
    _SFIconEntry('tram', SFIcons.sf_tram),
    _SFIconEntry('location', SFIcons.sf_location),
    _SFIconEntry('location.fill', SFIcons.sf_location_fill),
    _SFIconEntry('map', SFIcons.sf_map),
    _SFIconEntry('map.fill', SFIcons.sf_map_fill),
    _SFIconEntry('globe', SFIcons.sf_globe),
    _SFIconEntry('compass', SFIcons.sf_compass_drawing),
  ],
  'Fitness': [
    _SFIconEntry('dumbbell', SFIcons.sf_dumbbell),
    _SFIconEntry('dumbbell.fill', SFIcons.sf_dumbbell_fill),
    _SFIconEntry('trophy', SFIcons.sf_trophy),
    _SFIconEntry('trophy.fill', SFIcons.sf_trophy_fill),
    _SFIconEntry('medal', SFIcons.sf_medal),
    _SFIconEntry('sportscourt', SFIcons.sf_sportscourt),
    _SFIconEntry('figure.yoga', SFIcons.sf_figure_yoga),
    _SFIconEntry('figure.cooldown', SFIcons.sf_figure_cooldown),
    _SFIconEntry('timer', SFIcons.sf_timer),
    _SFIconEntry('stopwatch', SFIcons.sf_stopwatch),
    _SFIconEntry('heart.text.square', SFIcons.sf_heart_text_square),
  ],
  'Editing': [
    _SFIconEntry('pencil', SFIcons.sf_pencil),
    _SFIconEntry('highlighter', SFIcons.sf_highlighter),
    _SFIconEntry('paintbrush', SFIcons.sf_paintbrush),
    _SFIconEntry('paintbrush.fill', SFIcons.sf_paintbrush_fill),
    _SFIconEntry('scissors', SFIcons.sf_scissors),
    _SFIconEntry('wand.and.sparkles', SFIcons.sf_wand_and_sparkles),
    _SFIconEntry('crop', SFIcons.sf_crop),
    _SFIconEntry('slider.horizontal.3', SFIcons.sf_slider_horizontal_3),
    _SFIconEntry('eyedropper', SFIcons.sf_eyedropper),
    _SFIconEntry('ruler', SFIcons.sf_ruler),
    _SFIconEntry('square.and.pencil', SFIcons.sf_square_and_pencil),
  ],
  'System': [
    _SFIconEntry('gear', SFIcons.sf_gear),
    _SFIconEntry('gear.circle', SFIcons.sf_gear_circle),
    _SFIconEntry('house', SFIcons.sf_house),
    _SFIconEntry('house.fill', SFIcons.sf_house_fill),
    _SFIconEntry('magnifyingglass', SFIcons.sf_magnifyingglass),
    _SFIconEntry('info.circle', SFIcons.sf_info_circle),
    _SFIconEntry('questionmark.circle', SFIcons.sf_questionmark_circle),
    _SFIconEntry(
      'exclamationmark.triangle',
      SFIcons.sf_exclamationmark_triangle,
    ),
    _SFIconEntry('checkmark.circle', SFIcons.sf_checkmark_circle),
    _SFIconEntry('xmark.circle', SFIcons.sf_xmark_circle),
    _SFIconEntry('plus.circle', SFIcons.sf_plus_circle),
    _SFIconEntry('minus.circle', SFIcons.sf_minus_circle),
    _SFIconEntry('wifi', SFIcons.sf_wifi),
    _SFIconEntry('app', SFIcons.sf_app),
    _SFIconEntry('link', SFIcons.sf_link),
    _SFIconEntry('qrcode', SFIcons.sf_qrcode),
    _SFIconEntry('square.and.arrow.up', SFIcons.sf_square_and_arrow_up),
    _SFIconEntry('square.and.arrow.down', SFIcons.sf_square_and_arrow_down),
  ],
};
