/// Lightweight config persisted per design so repeat uploads skip app selection.
class AscAppConfig {
  /// App Store Connect app ID.
  final String appId;

  /// Human-readable app name.
  final String appName;

  /// Bundle identifier, e.g. `com.example.app`.
  final String bundleId;

  /// Screenshot display-type key, e.g. `APP_IPHONE_67`.
  final String displayType;

  /// Platform tab key, e.g. `IOS`, `MAC_OS`, `WATCH_OS`.
  final String platform;

  const AscAppConfig({
    required this.appId,
    required this.appName,
    required this.bundleId,
    this.displayType = 'APP_IPHONE_67',
    this.platform = 'IOS',
  });

  AscAppConfig copyWith({
    String? appId,
    String? appName,
    String? bundleId,
    String? displayType,
    String? platform,
  }) {
    return AscAppConfig(
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      bundleId: bundleId ?? this.bundleId,
      displayType: displayType ?? this.displayType,
      platform: platform ?? this.platform,
    );
  }

  Map<String, dynamic> toJson() => {
    'appId': appId,
    'appName': appName,
    'bundleId': bundleId,
    'displayType': displayType,
    'platform': platform,
  };

  factory AscAppConfig.fromJson(Map<String, dynamic> json) {
    return AscAppConfig(
      appId: json['appId'] as String,
      appName: json['appName'] as String,
      bundleId: json['bundleId'] as String,
      displayType: (json['displayType'] as String?) ?? 'APP_IPHONE_67',
      platform: (json['platform'] as String?) ?? 'IOS',
    );
  }
}
