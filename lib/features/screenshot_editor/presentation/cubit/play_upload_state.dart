part of 'play_upload_cubit.dart';

enum PlayUploadStatus { initial, ready, uploading, done, error }

enum PlayUploadFailure { autoSubmitRequired, declarationRequired }

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
  ];
}
