/// All preset actions supported by the CommandServer.
enum PresetAction {
  list,
  show;

  /// Convert enum name to kebab-case action name.
  String get actionName => name;

  /// Full API path, e.g. `/api/preset/list`.
  String get path => '/api/preset/$actionName';

  /// Look up an action by its kebab-case name.
  static PresetAction? fromActionName(String name) {
    for (final action in PresetAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
