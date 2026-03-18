/// All editor actions supported by the CommandServer.
enum EditorAction {
  state,
  setBackground,
  setGradient,
  setMeshGradient,
  setTransparent,
  setFrame,
  listDevices,
  listFonts,
  listIcons,
  setPadding,
  setCornerRadius,
  setRotation,
  setOrientation,
  setImage,
  setImagePosition,
  setImageBase64,
  setDisplayType,
  setDoodle,
  setGrid,
  addText,
  updateText,
  addImage,
  updateImage,
  addIcon,
  updateIcon,
  addMagnifier,
  updateMagnifier,
  selectOverlay,
  deleteOverlay,
  moveOverlay,
  copyOverlay,
  pasteOverlay,
  bringForward,
  sendBackward,
  listOverlays,
  applyPreset,
  undo,
  redo,
  saveDesign,
  loadDesign,
  export_, // trailing underscore to avoid Dart keyword
  exportAll;

  /// Convert enum name to kebab-case action name.
  ///
  /// `setBackground` → `set-background`, `export_` → `export`.
  String get actionName {
    final base = name.endsWith('_') ? name.substring(0, name.length - 1) : name;
    return base.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );
  }

  /// Full API path, e.g. `/api/editor/set-background`.
  String get path => '/api/editor/$actionName';

  /// Look up an action by its kebab-case name (from a URL).
  ///
  /// Returns `null` if not found.
  static EditorAction? fromActionName(String name) {
    for (final action in EditorAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
