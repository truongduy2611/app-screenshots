part of 'translation_cubit.dart';

/// Status of a single locale's translation progress.
enum TranslationStatus { idle, translating, done, error }

/// State for the translation cubit.
class TranslationState extends Equatable {
  /// The current translation bundle (null if no translations yet).
  final TranslationBundle? bundle;

  /// Locale currently being previewed in the editor canvas.
  /// `null` means showing the original source text.
  final String? previewLocale;

  /// Per-locale translation progress status.
  final Map<String, TranslationStatus> localeStatuses;

  /// Last error message, if any.
  final String? errorMessage;

  const TranslationState({
    this.bundle,
    this.previewLocale,
    this.localeStatuses = const {},
    this.errorMessage,
  });

  /// Whether any locale is currently being translated.
  bool get isTranslating =>
      localeStatuses.values.any((s) => s == TranslationStatus.translating);

  /// Number of locales that have completed translation.
  int get completedCount =>
      localeStatuses.values.where((s) => s == TranslationStatus.done).length;

  TranslationState copyWith({
    TranslationBundle? bundle,
    String? previewLocale,
    Map<String, TranslationStatus>? localeStatuses,
    String? errorMessage,
    bool clearBundle = false,
    bool clearPreviewLocale = false,
    bool clearError = false,
  }) {
    return TranslationState(
      bundle: clearBundle ? null : (bundle ?? this.bundle),
      previewLocale: clearPreviewLocale
          ? null
          : (previewLocale ?? this.previewLocale),
      localeStatuses: localeStatuses ?? this.localeStatuses,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    bundle,
    previewLocale,
    localeStatuses,
    errorMessage,
  ];
}
