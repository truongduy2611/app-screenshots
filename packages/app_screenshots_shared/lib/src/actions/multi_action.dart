/// All multi-design actions supported by the CommandServer.
enum MultiAction {
  open,
  state,
  switchDesign,
  addDesign,
  removeDesign,
  duplicateDesign,
  reorder,
  applyPreset,
  batch,
  setImage,
  saveDesign;

  /// Convert enum name to kebab-case action name.
  String get actionName => name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '-${m[0]!.toLowerCase()}',
  );

  /// Full API path, e.g. `/api/multi/switch-design`.
  String get path => '/api/multi/$actionName';

  /// Look up an action by its kebab-case name.
  static MultiAction? fromActionName(String name) {
    for (final action in MultiAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
