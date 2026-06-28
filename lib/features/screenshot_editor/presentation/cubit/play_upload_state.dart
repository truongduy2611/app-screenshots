part of 'play_upload_cubit.dart';

enum PlayUploadStatus { initial, ready, uploading, done, error }

class PlayUploadState extends Equatable {
  final PlayUploadStatus status;
  final bool hasCredentials;
  final String packageName;
  final String imageType;
  final Set<String> selectedLocales;
  final bool deleteExisting;
  final AscUploadProgress? progress;
  final AscUploadResult? result;
  final String? errorMessage;

  const PlayUploadState({
    this.status = PlayUploadStatus.initial,
    this.hasCredentials = false,
    this.packageName = '',
    this.imageType = 'phoneScreenshots',
    this.selectedLocales = const {},
    this.deleteExisting = true,
    this.progress,
    this.result,
    this.errorMessage,
  });

  PlayUploadState copyWith({
    PlayUploadStatus? status,
    bool? hasCredentials,
    String? packageName,
    String? imageType,
    Set<String>? selectedLocales,
    bool? deleteExisting,
    AscUploadProgress? progress,
    AscUploadResult? result,
    String? errorMessage,
  }) {
    return PlayUploadState(
      status: status ?? this.status,
      hasCredentials: hasCredentials ?? this.hasCredentials,
      packageName: packageName ?? this.packageName,
      imageType: imageType ?? this.imageType,
      selectedLocales: selectedLocales ?? this.selectedLocales,
      deleteExisting: deleteExisting ?? this.deleteExisting,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage,
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
    progress,
    result,
    errorMessage,
  ];
}
