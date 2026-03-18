/// All translation actions supported by the CommandServer.
enum TranslateAction {
  state,
  getTexts,
  all,
  preview,
  edit,
  applyManual,
  removeLocale,
  setPrompt,
  overrideOverlay,
  setLocaleImage;

  /// Convert enum name to kebab-case action name.
  String get actionName => name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '-${m[0]!.toLowerCase()}',
  );

  /// Full API path, e.g. `/api/translate/get-texts`.
  String get path => '/api/translate/$actionName';

  /// Look up an action by its kebab-case name.
  static TranslateAction? fromActionName(String name) {
    for (final action in TranslateAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
