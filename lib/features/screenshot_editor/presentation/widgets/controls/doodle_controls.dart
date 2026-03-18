import 'package:app_screenshots/core/extensions/context_extensions.dart';

import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/control_styles.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/gradient_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_color_picker.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_segmented_control.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:material_symbols_icons/symbols.dart';

class _Preset {
  final String label;
  final IconData displayIcon;
  final List<IconData> icons;
  const _Preset(this.label, this.displayIcon, this.icons);

  List<int> get codePoints => icons.map((e) => e.codePoint).toList();
}

class _EmojiPreset {
  final String label;
  final String displayEmoji;
  final List<String> emojis;
  const _EmojiPreset(this.label, this.displayEmoji, this.emojis);
}

final _sfPresets = [
  _Preset('Tech', SFIcons.sf_iphone, [
    SFIcons.sf_iphone,
    SFIcons.sf_applewatch,
    SFIcons.sf_wifi,
    SFIcons.sf_gear,
    SFIcons.sf_app,
    SFIcons.sf_magnifyingglass,
    SFIcons.sf_bolt,
    SFIcons.sf_antenna_radiowaves_left_and_right,
  ]),
  _Preset('Fitness', SFIcons.sf_dumbbell, [
    SFIcons.sf_dumbbell,
    SFIcons.sf_figure_walk,
    SFIcons.sf_heart,
    SFIcons.sf_flame,
    SFIcons.sf_bolt,
    SFIcons.sf_trophy,
    SFIcons.sf_timer,
  ]),
  _Preset('Nature', SFIcons.sf_leaf, [
    SFIcons.sf_leaf,
    SFIcons.sf_sun_max,
    SFIcons.sf_moon,
    SFIcons.sf_cloud,
    SFIcons.sf_drop,
    SFIcons.sf_snowflake,
    SFIcons.sf_tree,
    SFIcons.sf_mountain_2,
  ]),
  _Preset('Animals', SFIcons.sf_pawprint, [
    SFIcons.sf_pawprint,
    SFIcons.sf_hare,
    SFIcons.sf_fish,
    SFIcons.sf_ant,
    SFIcons.sf_ladybug,
    SFIcons.sf_bird,
    SFIcons.sf_tortoise,
  ]),
  _Preset('Travel', SFIcons.sf_airplane, [
    SFIcons.sf_airplane,
    SFIcons.sf_car,
    SFIcons.sf_bicycle,
    SFIcons.sf_globe,
    SFIcons.sf_map,
    SFIcons.sf_suitcase,
    SFIcons.sf_camera,
  ]),
  _Preset('Music', SFIcons.sf_music_note, [
    SFIcons.sf_music_note,
    SFIcons.sf_headphones,
    SFIcons.sf_guitars,
    SFIcons.sf_pianokeys,
    SFIcons.sf_speaker_wave_3,
    SFIcons.sf_waveform,
    SFIcons.sf_microphone,
  ]),
  _Preset('Mixed', SFIcons.sf_sparkles, [
    SFIcons.sf_sparkles,
    SFIcons.sf_star,
    SFIcons.sf_heart,
    SFIcons.sf_crown,
    SFIcons.sf_bolt,
    SFIcons.sf_flame,
    SFIcons.sf_bookmark,
    SFIcons.sf_globe,
    SFIcons.sf_bell,
    SFIcons.sf_diamond,
  ]),
];

final _materialPresets = [
  _Preset('Tech', Symbols.smartphone_rounded, [
    Symbols.smartphone_rounded,
    Symbols.watch_rounded,
    Symbols.wifi_rounded,
    Symbols.settings_rounded,
    Symbols.apps_rounded,
    Symbols.search_rounded,
    Symbols.bolt_rounded,
    Symbols.router_rounded,
  ]),
  _Preset('Fitness', Symbols.fitness_center_rounded, [
    Symbols.fitness_center_rounded,
    Symbols.directions_run_rounded,
    Symbols.favorite_rounded,
    Symbols.local_fire_department_rounded,
    Symbols.bolt_rounded,
    Symbols.emoji_events_rounded,
    Symbols.timer_rounded,
  ]),
  _Preset('Nature', Symbols.eco_rounded, [
    Symbols.eco_rounded,
    Symbols.light_mode_rounded,
    Symbols.dark_mode_rounded,
    Symbols.cloud_rounded,
    Symbols.water_drop_rounded,
    Symbols.ac_unit_rounded,
    Symbols.park_rounded,
    Symbols.landscape_rounded,
  ]),
  _Preset('Animals', Symbols.pets_rounded, [
    Symbols.pets_rounded,
    Symbols.bug_report_rounded,
    Symbols.pest_control_rounded,
    Symbols.flutter_rounded,
    Symbols.phishing_rounded,
    Symbols.cruelty_free_rounded,
  ]),
  _Preset('Travel', Symbols.flight_rounded, [
    Symbols.flight_rounded,
    Symbols.directions_car_rounded,
    Symbols.pedal_bike_rounded,
    Symbols.language_rounded,
    Symbols.explore_rounded,
    Symbols.map_rounded,
    Symbols.luggage_rounded,
  ]),
  _Preset('Music', Symbols.music_note_rounded, [
    Symbols.music_note_rounded,
    Symbols.headphones_rounded,
    Symbols.piano_rounded,
    Symbols.speaker_rounded,
    Symbols.graphic_eq_rounded,
    Symbols.mic_rounded,
    Symbols.queue_music_rounded,
  ]),
  _Preset('Mixed', Symbols.auto_awesome_rounded, [
    Symbols.auto_awesome_rounded,
    Symbols.star_rounded,
    Symbols.favorite_rounded,
    Symbols.diamond_rounded,
    Symbols.bolt_rounded,
    Symbols.local_fire_department_rounded,
    Symbols.bookmark_rounded,
    Symbols.language_rounded,
    Symbols.notifications_rounded,
  ]),
];

class _IconEntry {
  final String name;
  final IconData iconData;
  const _IconEntry(this.name, this.iconData);

  int get codePoint => iconData.codePoint;
}

final List<_IconEntry> _sfBrowsable = [
  _IconEntry('star', SFIcons.sf_star),
  _IconEntry('heart', SFIcons.sf_heart),
  _IconEntry('house', SFIcons.sf_house),
  _IconEntry('gear', SFIcons.sf_gear),
  _IconEntry('flame', SFIcons.sf_flame),
  _IconEntry('bolt', SFIcons.sf_bolt),
  _IconEntry('cloud', SFIcons.sf_cloud),
  _IconEntry('leaf', SFIcons.sf_leaf),
  _IconEntry('sun', SFIcons.sf_sun_max),
  _IconEntry('moon', SFIcons.sf_moon),
  _IconEntry('camera', SFIcons.sf_camera),
  _IconEntry('music', SFIcons.sf_music_note),
  _IconEntry('search', SFIcons.sf_magnifyingglass),
  _IconEntry('bell', SFIcons.sf_bell),
  _IconEntry('person', SFIcons.sf_person),
  _IconEntry('iphone', SFIcons.sf_iphone),
  _IconEntry('watch', SFIcons.sf_applewatch),
  _IconEntry('globe', SFIcons.sf_globe),
  _IconEntry('trophy', SFIcons.sf_trophy),
  _IconEntry('game', SFIcons.sf_gamecontroller),
  _IconEntry('dumbbell', SFIcons.sf_dumbbell),
  _IconEntry('run', SFIcons.sf_figure_walk),
  _IconEntry('crown', SFIcons.sf_crown),
  _IconEntry('diamond', SFIcons.sf_diamond),
  _IconEntry('brush', SFIcons.sf_highlighter),
  _IconEntry('pencil', SFIcons.sf_pencil),
  _IconEntry('sparkles', SFIcons.sf_sparkles),
  _IconEntry('bookmark', SFIcons.sf_bookmark),
  _IconEntry('app', SFIcons.sf_app),
  _IconEntry('wifi', SFIcons.sf_wifi),
  _IconEntry('airplane', SFIcons.sf_airplane),
  _IconEntry('car', SFIcons.sf_car),
  _IconEntry('bicycle', SFIcons.sf_bicycle),
  _IconEntry('drop', SFIcons.sf_drop),
  _IconEntry('snowflake', SFIcons.sf_snowflake),
  _IconEntry('paw', SFIcons.sf_pawprint),
  _IconEntry('hare', SFIcons.sf_hare),
  _IconEntry('bird', SFIcons.sf_bird),
  _IconEntry('tortoise', SFIcons.sf_tortoise),
  _IconEntry('tree', SFIcons.sf_tree),
  _IconEntry('mountain', SFIcons.sf_mountain_2),
  _IconEntry('ant', SFIcons.sf_ant),
  _IconEntry('ladybug', SFIcons.sf_ladybug),
  _IconEntry('fish', SFIcons.sf_fish),
  _IconEntry('timer', SFIcons.sf_timer),
  _IconEntry('headphones', SFIcons.sf_headphones),
  _IconEntry('guitars', SFIcons.sf_guitars),
  _IconEntry('piano', SFIcons.sf_pianokeys),
  _IconEntry('speaker', SFIcons.sf_speaker_wave_3),
  _IconEntry('waveform', SFIcons.sf_waveform),
  _IconEntry('mic', SFIcons.sf_microphone),
  _IconEntry('map', SFIcons.sf_map),
  _IconEntry('suitcase', SFIcons.sf_suitcase),
  _IconEntry('lock', SFIcons.sf_lock),
  _IconEntry('tag', SFIcons.sf_tag),
  _IconEntry('shield', SFIcons.sf_shield),
];

final List<_IconEntry> _materialBrowsable = [
  _IconEntry('star', Symbols.star_rounded),
  _IconEntry('heart', Symbols.favorite_rounded),
  _IconEntry('home', Symbols.home_rounded),
  _IconEntry('settings', Symbols.settings_rounded),
  _IconEntry('fire', Symbols.local_fire_department_rounded),
  _IconEntry('bolt', Symbols.bolt_rounded),
  _IconEntry('cloud', Symbols.cloud_rounded),
  _IconEntry('eco', Symbols.eco_rounded),
  _IconEntry('sun', Symbols.light_mode_rounded),
  _IconEntry('moon', Symbols.dark_mode_rounded),
  _IconEntry('camera', Symbols.photo_camera_rounded),
  _IconEntry('music', Symbols.music_note_rounded),
  _IconEntry('search', Symbols.search_rounded),
  _IconEntry('bell', Symbols.notifications_rounded),
  _IconEntry('person', Symbols.person_rounded),
  _IconEntry('phone', Symbols.smartphone_rounded),
  _IconEntry('watch', Symbols.watch_rounded),
  _IconEntry('globe', Symbols.language_rounded),
  _IconEntry('trophy', Symbols.emoji_events_rounded),
  _IconEntry('game', Symbols.sports_esports_rounded),
  _IconEntry('fitness', Symbols.fitness_center_rounded),
  _IconEntry('run', Symbols.directions_run_rounded),
  _IconEntry('diamond', Symbols.diamond_rounded),
  _IconEntry('palette', Symbols.palette_rounded),
  _IconEntry('edit', Symbols.edit_rounded),
  _IconEntry('sparkle', Symbols.auto_awesome_rounded),
  _IconEntry('bookmark', Symbols.bookmark_rounded),
  _IconEntry('apps', Symbols.apps_rounded),
  _IconEntry('wifi', Symbols.wifi_rounded),
  _IconEntry('flight', Symbols.flight_rounded),
  _IconEntry('car', Symbols.directions_car_rounded),
  _IconEntry('bike', Symbols.pedal_bike_rounded),
  _IconEntry('water', Symbols.water_drop_rounded),
  _IconEntry('snow', Symbols.ac_unit_rounded),
  _IconEntry('pets', Symbols.pets_rounded),
  _IconEntry('park', Symbols.park_rounded),
  _IconEntry('landscape', Symbols.landscape_rounded),
  _IconEntry('explore', Symbols.explore_rounded),
  _IconEntry('bug', Symbols.bug_report_rounded),
  _IconEntry('rocket', Symbols.rocket_launch_rounded),
  _IconEntry('timer', Symbols.timer_rounded),
  _IconEntry('mic', Symbols.mic_rounded),
  _IconEntry('piano', Symbols.piano_rounded),
  _IconEntry('headphones', Symbols.headphones_rounded),
  _IconEntry('speaker', Symbols.speaker_rounded),
  _IconEntry('equalizer', Symbols.graphic_eq_rounded),
  _IconEntry('queue', Symbols.queue_music_rounded),
  _IconEntry('bunny', Symbols.cruelty_free_rounded),
  _IconEntry('luggage', Symbols.luggage_rounded),
  _IconEntry('map', Symbols.map_rounded),
  _IconEntry('lock', Symbols.lock_rounded),
  _IconEntry('label', Symbols.label_rounded),
  _IconEntry('shield', Symbols.shield_rounded),
];

final _emojiPresets = [
  const _EmojiPreset('Faces', '😀', [
    '😀',
    '😍',
    '🥳',
    '😎',
    '🤩',
    '😂',
    '🥰',
    '🤗',
  ]),
  const _EmojiPreset('Animals', '🐶', [
    '🐶',
    '🐱',
    '🦊',
    '🐻',
    '🐼',
    '🐵',
    '🦁',
    '🐸',
  ]),
  const _EmojiPreset('Food', '🍕', [
    '🍕',
    '🍔',
    '🍩',
    '🍰',
    '🍎',
    '🍉',
    '☕',
    '🧁',
  ]),
  const _EmojiPreset('Nature', '🌸', [
    '🌸',
    '🌻',
    '🌈',
    '⭐',
    '🔥',
    '💧',
    '❄️',
    '🍀',
  ]),
  const _EmojiPreset('Sports', '⚽', [
    '⚽',
    '🏀',
    '🎾',
    '🏈',
    '⛳',
    '🏆',
    '🎯',
    '🥇',
  ]),
  const _EmojiPreset('Travel', '✈️', [
    '✈️',
    '🚗',
    '🚀',
    '🌍',
    '🗺️',
    '🏖️',
    '🎒',
    '⛺',
  ]),
  const _EmojiPreset('Objects', '💡', [
    '💡',
    '💎',
    '🎵',
    '📷',
    '🎮',
    '🔑',
    '⏰',
    '🎁',
  ]),
];

final List<String> _emojiBrowsable = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '🤣',
  '😂',
  '🙂',
  '😉',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😘',
  '😋',
  '😛',
  '🤪',
  '😎',
  '🤗',
  '🤭',
  '🥳',
  '😤',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🖤',
  '💖',
  '⭐',
  '🌟',
  '✨',
  '💫',
  '🔥',
  '💧',
  '❄️',
  '🌈',
  '🌸',
  '🌻',
  '🌺',
  '🍀',
  '🌴',
  '🍃',
  '🌙',
  '☀️',
  '🐶',
  '🐱',
  '🦊',
  '🐻',
  '🐼',
  '🐵',
  '🦁',
  '🐸',
  '🦋',
  '🐝',
  '🐢',
  '🐬',
  '🦅',
  '🐧',
  '🐰',
  '🐷',
  '🍕',
  '🍔',
  '🍩',
  '🍰',
  '🍎',
  '🍉',
  '☕',
  '🧁',
  '🎵',
  '🎶',
  '🎸',
  '🎹',
  '🎤',
  '🎧',
  '🎺',
  '🥁',
  '⚽',
  '🏀',
  '🎾',
  '🏆',
  '🎯',
  '🥇',
  '🏈',
  '⛳',
  '✈️',
  '🚗',
  '🚀',
  '🌍',
  '🏖️',
  '🎒',
  '🗺️',
  '⛺',
  '💡',
  '💎',
  '📷',
  '🎮',
  '🔑',
  '⏰',
  '🎁',
  '📱',
  '👑',
  '🎭',
  '🎨',
  '🪄',
  '🧲',
  '📚',
  '💻',
  '🔔',
];

class DoodleControls extends StatelessWidget {
  const DoodleControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
      builder: (context, state) {
        final settings = state.design.doodleSettings ?? const DoodleSettings();
        final isEnabled = settings.enabled;
        final theme = Theme.of(context);

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            // Enable toggle
            ControlSection(
              icon: Symbols.auto_awesome_rounded,
              title: context.l10n.doodle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSwitch(
                    value: isEnabled,
                    onChanged: (val) =>
                        _update(context, settings.copyWith(enabled: val)),
                  ),
                ],
              ),
            ),
            Text(
              context.l10n.scatterIconPatterns,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (isEnabled) ...[
              const SizedBox(height: 20),

              // Icon style
              ControlSection(
                icon: Symbols.category_rounded,
                title: context.l10n.iconStyle,
              ),
              AppSegmentedControl<DoodleIconSource>(
                value: settings.iconSource,
                items: [
                  AppSegment(
                    value: DoodleIconSource.sfSymbols,
                    label: context.l10n.sfSymbols,
                  ),
                  AppSegment(
                    value: DoodleIconSource.materialSymbols,
                    label: context.l10n.materialLabel,
                  ),
                  AppSegment(
                    value: DoodleIconSource.emoji,
                    label: context.l10n.emojiLabel,
                  ),
                ],
                onChanged: (source) {
                  if (source == DoodleIconSource.emoji) {
                    _update(
                      context,
                      settings.copyWith(
                        iconSource: source,
                        emojiCharacters: _emojiPresets.first.emojis,
                      ),
                    );
                  } else {
                    final firstPreset = source == DoodleIconSource.sfSymbols
                        ? _sfPresets.first.codePoints
                        : _materialPresets.first.codePoints;
                    _update(
                      context,
                      settings.copyWith(
                        iconSource: source,
                        iconCodePoints: firstPreset,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Presets
              ControlCard(
                children: [
                  Text(
                    context.l10n.presetsLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPresetChips(context, settings),
                  const SizedBox(height: 12),
                  _buildCustomIconPicker(context, settings),
                ],
              ),

              // Color – hidden for emoji (emojis have inherent color)
              if (settings.iconSource != DoodleIconSource.emoji) ...[
                const SizedBox(height: 20),

                ControlSection(
                  icon: Symbols.palette_rounded,
                  title: context.l10n.color,
                ),
                AppSegmentedControl<bool>(
                  value: settings.iconGradient != null,
                  items: [
                    AppSegment(value: false, label: context.l10n.solid),
                    AppSegment(value: true, label: context.l10n.gradient),
                  ],
                  onChanged: (useGradient) {
                    if (useGradient) {
                      _update(
                        context,
                        settings.copyWith(
                          iconGradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    } else {
                      _update(context, settings.copyWith(clearGradient: true));
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (settings.iconGradient != null)
                  GradientEditor(
                    gradient: settings.iconGradient!,
                    meshGradient: null,
                    showMesh: false,
                    onGradientChanged: (gradient) => _update(
                      context,
                      settings.copyWith(iconGradient: gradient),
                    ),
                    onMeshGradientChanged: (_) {},
                  )
                else
                  _CompactColorPicker(
                    color: settings.iconColor,
                    onColorChanged: (color) =>
                        _update(context, settings.copyWith(iconColor: color)),
                    onEditStart: context
                        .read<ScreenshotEditorCubit>()
                        .beginBatchEdit,
                    onEditEnd: context
                        .read<ScreenshotEditorCubit>()
                        .endBatchEdit,
                  ),
              ],

              const SizedBox(height: 20),

              // Layout
              ControlSection(
                icon: Symbols.tune_rounded,
                title: context.l10n.layoutLabel,
              ),
              ControlCard(
                children: [
                  LabeledSlider(
                    label: context.l10n.opacityLabel,
                    value: settings.iconOpacity,
                    min: 0.02,
                    max: 0.5,
                    valueLabel: '${(settings.iconOpacity * 100).round()}%',
                    onChanged: (val) =>
                        _update(context, settings.copyWith(iconOpacity: val)),
                  ),
                  const SizedBox(height: 4),
                  LabeledSlider(
                    label: context.l10n.iconSizeLabel,
                    value: settings.iconSize,
                    min: 16,
                    max: 200,
                    suffix: 'px',
                    onChanged: (val) =>
                        _update(context, settings.copyWith(iconSize: val)),
                  ),
                  const SizedBox(height: 4),
                  LabeledSlider(
                    label: context.l10n.spacingLabel,
                    value: settings.spacing,
                    min: 30,
                    max: 300,
                    suffix: 'px',
                    onChanged: (val) =>
                        _update(context, settings.copyWith(spacing: val)),
                  ),
                  const SizedBox(height: 4),
                  LabeledSlider(
                    label: context.l10n.rotation,
                    value: settings.rotation,
                    min: -45,
                    max: 45,
                    valueLabel: '${settings.rotation.round()}°',
                    onChanged: (val) =>
                        _update(context, settings.copyWith(rotation: val)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.shuffle_rounded,
                          size: 18,
                          color: settings.randomizeRotation
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.randomizeRotation,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        AppSwitch(
                          value: settings.randomizeRotation,
                          onChanged: (val) => _update(
                            context,
                            settings.copyWith(randomizeRotation: val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPresetChips(BuildContext context, DoodleSettings settings) {
    final isEmoji = settings.iconSource == DoodleIconSource.emoji;

    if (isEmoji) {
      return _buildEmojiPresetChips(context, settings);
    }

    final isSF = settings.iconSource == DoodleIconSource.sfSymbols;
    final presets = isSF ? _sfPresets : _materialPresets;
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final preset = presets[index];

          final isSelected = _listsEqual(
            settings.iconCodePoints,
            preset.codePoints,
          );
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _update(
                  context,
                  settings.copyWith(iconCodePoints: preset.codePoints),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      preset.displayIcon,
                      size: 15,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      preset.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmojiPresetChips(BuildContext context, DoodleSettings settings) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _emojiPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final preset = _emojiPresets[index];

          final isSelected = _stringListsEqual(
            settings.emojiCharacters,
            preset.emojis,
          );
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _update(
                  context,
                  settings.copyWith(emojiCharacters: preset.emojis),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preset.displayEmoji,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      preset.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomIconPicker(BuildContext context, DoodleSettings settings) {
    final isEmoji = settings.iconSource == DoodleIconSource.emoji;

    if (isEmoji) {
      return _buildCustomEmojiPicker(context, settings);
    }

    final isSF = settings.iconSource == DoodleIconSource.sfSymbols;
    final browsable = isSF ? _sfBrowsable : _materialBrowsable;
    final fontFamily = isSF ? 'sficons' : 'MaterialSymbolsRounded';
    final fontPackage = isSF ? 'flutter_sficon' : 'material_symbols_icons';
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Symbols.grid_view_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.customIcons,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        collapsedIconColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.5,
        ),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: browsable.length,
            itemBuilder: (context, index) {
              final entry = browsable[index];
              final isSelected = settings.iconCodePoints.contains(
                entry.codePoint,
              );
              return Tooltip(
                message: entry.name,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      final updated = List<int>.from(settings.iconCodePoints);
                      if (isSelected) {
                        updated.remove(entry.codePoint);
                      } else {
                        updated.add(entry.codePoint);
                      }
                      _update(
                        context,
                        settings.copyWith(iconCodePoints: updated),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(entry.codePoint),
                          style: TextStyle(
                            fontFamily: fontFamily,
                            package: fontPackage,
                            fontSize: 18,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomEmojiPicker(
    BuildContext context,
    DoodleSettings settings,
  ) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Symbols.grid_view_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.customIcons,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        collapsedIconColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.5,
        ),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _emojiBrowsable.length,
            itemBuilder: (context, index) {
              final emoji = _emojiBrowsable[index];
              final isSelected = settings.emojiCharacters.contains(emoji);
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final updated = List<String>.from(settings.emojiCharacters);
                    if (isSelected) {
                      updated.remove(emoji);
                    } else {
                      updated.add(emoji);
                    }
                    _update(
                      context,
                      settings.copyWith(emojiCharacters: updated),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _update(BuildContext context, DoodleSettings settings) {
    context.read<ScreenshotEditorCubit>().updateDoodleSettings(settings);
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _stringListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _CompactColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onEditStart;
  final VoidCallback? onEditEnd;
  const _CompactColorPicker({
    required this.color,
    required this.onColorChanged,
    this.onEditStart,
    this.onEditEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AppColorPicker(
      color: color,
      onColorChanged: onColorChanged,
      onEditStart: onEditStart,
      onEditEnd: onEditEnd,
    );
  }
}
