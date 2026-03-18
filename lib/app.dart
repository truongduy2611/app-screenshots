import 'dart:io';

import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/services/menu_callbacks.dart';
import 'package:app_screenshots/core/theme/app_theme.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/app_icon_cubit.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:app_screenshots/features/settings/presentation/pages/settings_page.dart';
import 'package:app_screenshots/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_screenshots/l10n/output/app_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      MenuCallbacks.onSettings = _openSettings;
      MenuCallbacks.onAbout = _showAbout;
    }
  }

  @override
  void dispose() {
    if (Platform.isMacOS) {
      MenuCallbacks.onSettings = null;
      MenuCallbacks.onAbout = null;
    }
    super.dispose();
  }

  void _openSettings() {
    if (_isSettingsOpen) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx != null) {
      _isSettingsOpen = true;
      SettingsDialog.show(ctx).whenComplete(() => _isSettingsOpen = false);
    }
  }

  void _showAbout() {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    final l10n = AppLocalizations.of(ctx)!;
    showAboutDialog(
      context: ctx,
      applicationName: l10n.appTitle,
      applicationVersion: l10n.version('1.0.0'),
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset('main-icon.png', width: 64, height: 64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()..loadTheme()),
        BlocProvider<AppIconCubit>.value(value: sl<AppIconCubit>()),
        BlocProvider<BackupCubit>.value(value: sl<BackupCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final app = MaterialApp(
            navigatorKey: _navigatorKey,
            onGenerateTitle: (context) => context.l10n.appTitle,
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          );

          if (!Platform.isMacOS) return app;

          return PlatformMenuBar(
            menus: [
              PlatformMenu(
                label: '', // App name is auto-filled by macOS
                menus: [
                  PlatformMenuItemGroup(
                    members: [
                      PlatformMenuItem(
                        label: 'About App Screenshots',
                        onSelected: () => MenuCallbacks.onAbout?.call(),
                      ),
                    ],
                  ),
                  PlatformMenuItemGroup(
                    members: [
                      PlatformMenuItem(
                        label: 'Settings…',
                        shortcut: const SingleActivator(
                          LogicalKeyboardKey.comma,
                          meta: true,
                        ),
                        onSelected: () => MenuCallbacks.onSettings?.call(),
                      ),
                    ],
                  ),
                  if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.quit,
                  ))
                    const PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.quit,
                    ),
                ],
              ),
              PlatformMenu(
                label: 'Edit',
                menus: [
                  PlatformMenuItemGroup(
                    members: [
                      PlatformMenuItem(
                        label: 'Undo',
                        shortcut: const SingleActivator(
                          LogicalKeyboardKey.keyZ,
                          meta: true,
                        ),
                        onSelected: () => MenuCallbacks.onUndo?.call(),
                      ),
                      PlatformMenuItem(
                        label: 'Redo',
                        shortcut: const SingleActivator(
                          LogicalKeyboardKey.keyZ,
                          meta: true,
                          shift: true,
                        ),
                        onSelected: () => MenuCallbacks.onRedo?.call(),
                      ),
                    ],
                  ),
                ],
              ),
              PlatformMenu(
                label: 'View',
                menus: [
                  if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.toggleFullScreen,
                  ))
                    const PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.toggleFullScreen,
                    ),
                ],
              ),
              PlatformMenu(
                label: 'Window',
                menus: [
                  if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.minimizeWindow,
                  ))
                    const PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.minimizeWindow,
                    ),
                  if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.zoomWindow,
                  ))
                    const PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.zoomWindow,
                    ),
                ],
              ),
            ],
            child: app,
          );
        },
      ),
    );
  }
}
