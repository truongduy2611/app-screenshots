part of 'screenshot_library_cubit.dart';

const _notSet = Object();

sealed class ScreenshotLibraryState extends Equatable {
  const ScreenshotLibraryState();

  @override
  List<Object?> get props => [];
}

class ScreenshotLibraryInitial extends ScreenshotLibraryState {}

class ScreenshotLibraryLoading extends ScreenshotLibraryState {}

class ScreenshotLibraryLoaded extends ScreenshotLibraryState {
  /// Designs filtered to the current folder level.
  final List<SavedDesign> designs;

  /// Folders filtered to the current folder level.
  final List<DesignFolder> folders;

  /// All designs across all folders (for hierarchical list view).
  final List<SavedDesign> allDesigns;

  /// All folders across all levels (for hierarchical list view).
  final List<DesignFolder> allFolders;
  final String? currentFolderId;
  final String searchQuery;
  final bool isSelectionMode;
  final Set<String> selectedDesignIds;
  final Set<String> selectedFolderIds;

  const ScreenshotLibraryLoaded({
    required this.designs,
    required this.folders,
    this.allDesigns = const [],
    this.allFolders = const [],
    this.currentFolderId,
    this.searchQuery = '',
    this.isSelectionMode = false,
    this.selectedDesignIds = const {},
    this.selectedFolderIds = const {},
  });

  ScreenshotLibraryLoaded copyWith({
    List<SavedDesign>? designs,
    List<DesignFolder>? folders,
    List<SavedDesign>? allDesigns,
    List<DesignFolder>? allFolders,
    Object? currentFolderId = _notSet,
    String? searchQuery,
    bool? isSelectionMode,
    Set<String>? selectedDesignIds,
    Set<String>? selectedFolderIds,
  }) {
    return ScreenshotLibraryLoaded(
      designs: designs ?? this.designs,
      folders: folders ?? this.folders,
      allDesigns: allDesigns ?? this.allDesigns,
      allFolders: allFolders ?? this.allFolders,
      currentFolderId: currentFolderId == _notSet
          ? this.currentFolderId
          : currentFolderId as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedDesignIds: selectedDesignIds ?? this.selectedDesignIds,
      selectedFolderIds: selectedFolderIds ?? this.selectedFolderIds,
    );
  }

  /// Returns designs filtered by the current search query (searches all levels).
  List<SavedDesign> get filteredDesigns => searchQuery.isEmpty
      ? designs
      : allDesigns
            .where(
              (d) => d.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

  /// Returns folders filtered by the current search query (searches all levels).
  List<DesignFolder> get filteredFolders => searchQuery.isEmpty
      ? folders
      : allFolders
            .where(
              (f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

  @override
  List<Object?> get props => [
    designs,
    folders,
    allDesigns,
    allFolders,
    currentFolderId,
    searchQuery,
    isSelectionMode,
    selectedDesignIds,
    selectedFolderIds,
  ];
}

class ScreenshotLibraryError extends ScreenshotLibraryState {
  final String message;

  const ScreenshotLibraryError({required this.message});

  @override
  List<Object?> get props => [message];
}
