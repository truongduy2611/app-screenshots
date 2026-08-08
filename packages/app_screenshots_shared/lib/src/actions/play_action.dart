/// Google Play operations exposed by the local command server.
enum PlayAction {
  upload;

  String get actionName => name;
  String get path => '/api/play/$actionName';

  static PlayAction? fromActionName(String name) {
    for (final action in PlayAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
