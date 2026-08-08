/// Background-job operations exposed by the local command server.
enum JobAction {
  list,
  status;

  String get actionName => name;
  String get path => '/api/jobs/$actionName';

  static JobAction? fromActionName(String name) {
    for (final action in JobAction.values) {
      if (action.actionName == name) return action;
    }
    return null;
  }
}
