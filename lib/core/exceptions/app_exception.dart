/// Base exception for all app-level errors.
///
/// Carries a user-friendly [message] plus the original [error] and [stackTrace]
/// for logging and debugging.
class AppException implements Exception {
  const AppException(this.message, {this.error, this.stackTrace});

  /// Human-readable description suitable for UI display.
  final String message;

  /// The original error that caused this exception, if any.
  final Object? error;

  /// Stack trace captured at the point of failure.
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message';
}

/// Thrown when a file-system or persistence operation fails.
class StorageException extends AppException {
  const StorageException(super.message, {super.error, super.stackTrace});

  @override
  String toString() => 'StorageException: $message';
}

/// Thrown when a network request fails.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.error, super.stackTrace});

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when data parsing or deserialization fails.
class ParseException extends AppException {
  const ParseException(super.message, {super.error, super.stackTrace});

  @override
  String toString() => 'ParseException: $message';
}
