part of 'command_server.dart';

// =============================================================================
// Response helpers
// =============================================================================

/// Uniform JSON response constructors — replaces scattered Map literals.
class ServerResponse {
  const ServerResponse._();

  static Map<String, dynamic> ok([dynamic data]) => {
    'ok': true,
    if (data != null) 'data': data,
  };

  static Map<String, dynamic> error(String message) => {
    'ok': false,
    'error': message,
  };

  static Map<String, dynamic> notReady(String what) =>
      error('No active $what. Open a design first.');
}

// =============================================================================
// Colour utilities
// =============================================================================

/// Parse a hex colour string (`#RRGGBB` or `#AARRGGBB`) to a [Color].
Color? parseHexColor(String hex) {
  try {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return null;
  }
}

/// Convert a [Color] to uppercase hex (`#RRGGBB`).
String colorToHex(Color? color) {
  if (color == null) return '#000000';
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
