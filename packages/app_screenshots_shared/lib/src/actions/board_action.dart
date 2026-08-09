/// Actions on the board editor — one canvas sliced into screenshots by crop
/// zones.
///
/// Separate from [MultiAction] because the two model a project differently: a
/// multi design is a list of independent artboards, whereas a board is a single
/// canvas whose frames float freely and whose exports are defined by crop
/// zones. Background and overlay editing on a board still goes through
/// [EditorAction], since a board's background is an ordinary design.
enum BoardAction {
  open,
  state,
  addZone,
  removeZone,
  updateZone,
  setZoneSpacing,
  arrangeZones,
  listTemplates,
  applyTemplate,
  addFrame,
  removeFrame,
  updateFrame,
  setFrameImage,
  importImages,
  export_, // trailing underscore to avoid the Dart keyword
  exportAll,
  saveDesign;

  /// Convert enum name to kebab-case action name.
  String get actionName {
    final base = name.endsWith('_') ? name.substring(0, name.length - 1) : name;
    return base.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );
  }

  /// Full API path, e.g. `/api/board/set-zone-spacing`.
  String get path => '/api/board/$actionName';

  /// Look up an action by its kebab-case name.
  static BoardAction? fromActionName(String name) {
    for (final action in BoardAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
