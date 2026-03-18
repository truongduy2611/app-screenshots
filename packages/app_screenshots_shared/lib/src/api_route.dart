/// Top-level API route groups.
///
/// Each route has a [prefix] used to match incoming request paths and
/// construct outgoing request URLs.
enum ApiRoute {
  status('/api/status'),
  editor('/api/editor/'),
  library('/api/library/'),
  translate('/api/translate/'),
  preset('/api/preset/'),
  multi('/api/multi/');

  const ApiRoute(this.prefix);

  /// The URL prefix for this route group.
  final String prefix;

  /// Match a request path to a route, or `null` if unrecognised.
  static ApiRoute? fromPath(String path) {
    if (path == ApiRoute.status.prefix) return ApiRoute.status;
    for (final route in ApiRoute.values) {
      if (route != ApiRoute.status && path.startsWith(route.prefix)) {
        return route;
      }
    }
    return null;
  }

  /// Extract the action suffix from a path.
  ///
  /// Example: `/api/editor/set-background` → `set-background`.
  String actionFrom(String path) => path.substring(prefix.length);
}
