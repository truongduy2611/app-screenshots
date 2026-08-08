/// iCloud collaboration operations exposed by the local command server.
enum CollaborationAction {
  share,
  save;

  String get actionName => name;
  String get path => '/api/collaboration/$actionName';

  static CollaborationAction? fromActionName(String name) {
    for (final action in CollaborationAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
