/// App Store Connect operations exposed by the local command server.
enum AscAction {
  apps,
  customProductPages,
  upload;

  String get actionName => name.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '-${match[0]!.toLowerCase()}',
      );

  String get path => '/api/asc/$actionName';

  static AscAction? fromActionName(String name) {
    for (final action in AscAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
