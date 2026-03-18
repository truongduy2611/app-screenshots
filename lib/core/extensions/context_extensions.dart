import 'package:flutter/material.dart';
import 'package:app_screenshots/l10n/output/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
