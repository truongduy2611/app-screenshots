/// Centralised app-wide constants.
///
/// Keep all hard-coded strings, URLs, and identifiers here so they are easy to
/// update and consistent across the entire app.
class AppConstants {
  AppConstants._();

  // ── App Store ──────────────────────────────────────────────────────────────
  /// Replace with the real App Store ID once the app is published.
  static const String appStoreId = '6759480229';

  /// Direct link to the App Store product page.
  static const String appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';

  /// Deep-link that opens the App Store's "Write a Review" sheet.
  static const String appStoreReviewUrl =
      'https://apps.apple.com/app/id$appStoreId?action=write-review';

  // ── Support ────────────────────────────────────────────────────────────────
  static const String feedbackEmail = 'feedback@progressiostudio.com';

  static const String feedbackSubject = 'App Screenshots Feedback';

  /// Support page URL – used on macOS where mailto: doesn't open Mail.app.
  static const String supportUrl =
      'https://appscreenshots.progressiostudio.com/#support';

  // ── Legal ──────────────────────────────────────────────────────────────────
  /// Terms of Service URL. Update when the real page is published.
  static const String termsOfServiceUrl =
      'https://appscreenshots.progressiostudio.com/terms-of-service';

  /// Privacy Policy URL. Update when the real page is published.
  static const String privacyPolicyUrl =
      'https://appscreenshots.progressiostudio.com/privacy-policy';

  // ── Open Source ────────────────────────────────────────────────────────────
  /// GitHub repository URL.
  static const String githubRepoUrl =
      'https://github.com/truongduy2611/app-screenshots';
}
