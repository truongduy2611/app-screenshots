part of 'play_upload_cubit.dart';

enum PlayUploadStatus { initial, ready, uploading, done, error }

enum PlayUploadFailure {
  autoSubmitRequired,
  declarationRequired,
}

enum PlayUploadTargetType {
  mainListing,
  customListing,
}

class PlayUploadState extends Equatable {
  final PlayUploadStatus status;
  final bool hasCredentials;
  final String packageName;
  final String imageType;
  final Set<String> selectedLocales;
  final bool deleteExisting;
  final bool commitAsDraft;
  final AscUploadProgress? progress;
  final AscUploadResult? result;
  final String? errorMessage;
  final PlayUploadFailure? failure;
  final PlayUploadTargetType targetType;
  final List<PlayCustomStoreListing> customStoreListings;
  final PlayCustomStoreListing? selectedCustomStoreListing;
  final bool loadingCustomStoreListings;

  const PlayUploadState({
    this.status = PlayUploadStatus.initial,
    this.hasCredentials = false,
    this.packageName = '',
    this.imageType = 'phoneScreenshots',
    this.selectedLocales = const {},
    this.deleteExisting = true,
    this.commitAsDraft = true,
    this.progress,
    this.result,
    this.errorMessage,
    this.failure,
    this.targetType = PlayUploadTargetType.mainListing,
    this.customStoreListings = const [],
    this.selectedCustomStoreListing,
    this.loadingCustomStoreListings = false,
  });

  PlayUploadState copyWith({
    PlayUploadStatus? status,
    bool? hasCredentials,
    String? packageName,
    String? imageType,
    Set<String>? selectedLocales,
    bool? deleteExisting,
    bool? commitAsDraft,
    AscUploadProgress? progress,
    AscUploadResult? result,
    String? errorMessage,
    PlayUploadFailure? failure,
    PlayUploadTargetType? targetType,
    List<PlayCustomStoreListing>? customStoreListings,
    PlayCustomStoreListing? selectedCustomStoreListing,
    bool? loadingCustomStoreListings,
  }) {
    return PlayUploadState(
      status: status ?? this.status,
      hasCredentials: hasCredentials ?? this.hasCredentials,
      packageName: packageName ?? this.packageName,
      imageType: imageType ?? this.imageType,
      selectedLocales: selectedLocales ?? this.selectedLocales,
      deleteExisting: deleteExisting ?? this.deleteExisting,
      commitAsDraft: commitAsDraft ?? this.commitAsDraft,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage,
      failure: failure ?? this.failure,
      targetType: targetType ?? this.targetType,
      customStoreListings: customStoreListings ?? this.customStoreListings,
      selectedCustomStoreListing:
          selectedCustomStoreListing ?? this.selectedCustomStoreListing,
      loadingCustomStoreListings:
          loadingCustomStoreListings ?? this.loadingCustomStoreListings,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hasCredentials,
    packageName,
    imageType,
    selectedLocales,
    deleteExisting,
    commitAsDraft,
    progress,
    result,
    errorMessage,
    failure,
    targetType,
    customStoreListings,
    selectedCustomStoreListing,
    loadingCustomStoreListings,
  ];
}
