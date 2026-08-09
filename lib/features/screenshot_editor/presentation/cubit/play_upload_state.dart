part of 'play_upload_cubit.dart';

enum PlayUploadStatus { initial, ready, uploading, done, exported, error }

enum PlayUploadFailure { autoSubmitRequired, declarationRequired }

/// Where the selected screenshots are headed.
///
/// Google Play's API only addresses the main listing, so a custom store
/// listing can't be uploaded — it is exported to disk for a manual Play
/// Console upload instead.
enum PlayDestination { mainListing, customStoreListing }

class PlayUploadState extends Equatable {
  final PlayUploadStatus status;
  final bool hasCredentials;
  final String packageName;
  final String imageType;
  final Set<String> selectedLocales;
  final bool deleteExisting;
  final bool commitAsDraft;
  final PlayDestination destination;
  final String listingName;
  final String targetingNote;
  final AscUploadProgress? progress;
  final AscUploadResult? result;
  final PlayCslExportResult? exportResult;
  final String? errorMessage;
  final PlayUploadFailure? failure;

  const PlayUploadState({
    this.status = PlayUploadStatus.initial,
    this.hasCredentials = false,
    this.packageName = '',
    this.imageType = 'phoneScreenshots',
    this.selectedLocales = const {},
    this.deleteExisting = true,
    this.commitAsDraft = true,
    this.destination = PlayDestination.mainListing,
    this.listingName = '',
    this.targetingNote = '',
    this.progress,
    this.result,
    this.exportResult,
    this.errorMessage,
    this.failure,
  });

  bool get isCustomStoreListing =>
      destination == PlayDestination.customStoreListing;

  PlayUploadState copyWith({
    PlayUploadStatus? status,
    bool? hasCredentials,
    String? packageName,
    String? imageType,
    Set<String>? selectedLocales,
    bool? deleteExisting,
    bool? commitAsDraft,
    PlayDestination? destination,
    String? listingName,
    String? targetingNote,
    AscUploadProgress? progress,
    AscUploadResult? result,
    PlayCslExportResult? exportResult,
    String? errorMessage,
    PlayUploadFailure? failure,
  }) {
    return PlayUploadState(
      status: status ?? this.status,
      hasCredentials: hasCredentials ?? this.hasCredentials,
      packageName: packageName ?? this.packageName,
      imageType: imageType ?? this.imageType,
      selectedLocales: selectedLocales ?? this.selectedLocales,
      deleteExisting: deleteExisting ?? this.deleteExisting,
      commitAsDraft: commitAsDraft ?? this.commitAsDraft,
      destination: destination ?? this.destination,
      listingName: listingName ?? this.listingName,
      targetingNote: targetingNote ?? this.targetingNote,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      exportResult: exportResult ?? this.exportResult,
      errorMessage: errorMessage,
      failure: failure ?? this.failure,
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
    destination,
    listingName,
    targetingNote,
    progress,
    result,
    exportResult,
    errorMessage,
    failure,
  ];
}
