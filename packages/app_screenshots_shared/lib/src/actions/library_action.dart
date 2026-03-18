/// All library actions supported by the CommandServer.
enum LibraryAction {
  list,
  folders,
  get,
  delete,
  rename,
  search,
  createFolder,
  deleteFolder,
  move,
  import_,   // trailing underscore to avoid Dart keyword
  export_;   // trailing underscore to avoid Dart keyword

  /// Convert enum name to kebab-case action name.
  String get actionName {
    final base = name.endsWith('_') ? name.substring(0, name.length - 1) : name;
    return base.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );
  }

  /// Full API path, e.g. `/api/library/create-folder`.
  String get path => '/api/library/$actionName';

  /// Look up an action by its kebab-case name.
  static LibraryAction? fromActionName(String name) {
    for (final action in LibraryAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
