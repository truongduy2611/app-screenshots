/// Shared constants between the app and CLI.
class AppConstants {
  const AppConstants._();

  /// Default server port.
  static const int defaultPort = 19222;

  /// Config directory name (under $HOME).
  static const String configDirName = '.config/app-screenshots';

  /// Port file name within the config directory.
  static const String portFileName = 'server.port';
}
