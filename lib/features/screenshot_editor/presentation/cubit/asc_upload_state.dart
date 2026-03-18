part of 'asc_upload_cubit.dart';

enum AscUploadStatus {
  initial,
  loadingApps,
  appsLoaded,
  loadingVersion,
  readyToUpload,
  uploading,
  done,
  error,
}

class AscUploadState extends Equatable {
  final AscUploadStatus status;
  final List<App> apps;
  final App? selectedApp;
  final AppStoreVersion? version;
  final String displayType;
  final String platform;
  final AscUploadProgress? progress;
  final AscUploadResult? result;
  final String? errorMessage;
  final bool hasCredentials;
  final AscAppConfig? ascAppConfig;
  final Set<String> selectedLocales;
  final bool deleteExisting;
  final bool rememberApp;

  const AscUploadState({
    this.status = AscUploadStatus.initial,
    this.apps = const [],
    this.selectedApp,
    this.version,
    this.displayType = 'APP_IPHONE_67',
    this.platform = 'IOS',
    this.progress,
    this.result,
    this.errorMessage,
    this.hasCredentials = false,
    this.ascAppConfig,
    this.selectedLocales = const {},
    this.deleteExisting = true,
    this.rememberApp = false,
  });

  AscUploadState copyWith({
    AscUploadStatus? status,
    List<App>? apps,
    App? selectedApp,
    AppStoreVersion? version,
    String? displayType,
    String? platform,
    AscUploadProgress? progress,
    AscUploadResult? result,
    String? errorMessage,
    bool? hasCredentials,
    AscAppConfig? ascAppConfig,
    Set<String>? selectedLocales,
    bool? deleteExisting,
    bool? rememberApp,
  }) {
    return AscUploadState(
      status: status ?? this.status,
      apps: apps ?? this.apps,
      selectedApp: selectedApp ?? this.selectedApp,
      version: version ?? this.version,
      displayType: displayType ?? this.displayType,
      platform: platform ?? this.platform,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage,
      hasCredentials: hasCredentials ?? this.hasCredentials,
      ascAppConfig: ascAppConfig ?? this.ascAppConfig,
      selectedLocales: selectedLocales ?? this.selectedLocales,
      deleteExisting: deleteExisting ?? this.deleteExisting,
      rememberApp: rememberApp ?? this.rememberApp,
    );
  }

  @override
  List<Object?> get props => [
    status,
    apps,
    selectedApp,
    version,
    displayType,
    platform,
    progress,
    result,
    errorMessage,
    hasCredentials,
    ascAppConfig,
    selectedLocales,
    deleteExisting,
    rememberApp,
  ];
}
