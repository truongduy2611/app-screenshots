import 'dart:ui';

/// Global callback registry for macOS menu bar actions.
///
/// Pages register/unregister their callbacks so the app-level
/// [PlatformMenuBar] can dispatch to the active page's cubit.
class MenuCallbacks {
  MenuCallbacks._();

  static VoidCallback? onUndo;
  static VoidCallback? onRedo;
  static VoidCallback? onSettings;
  static VoidCallback? onAbout;
}
