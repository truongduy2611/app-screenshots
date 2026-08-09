import 'dart:convert';
import 'dart:io';

/// Reads locale subdirectories and returns their ordered image files.
///
/// Shared by the upload commands (which base64 the bytes for the app server)
/// and the custom store listing export (which copies files directly).
Future<Map<String, List<File>>> readLocaleScreenshots(
  String sourceDirectory, {
  List<String> selectedLocales = const [],
}) async {
  final root = Directory(sourceDirectory);
  if (!await root.exists()) {
    throw ArgumentError('Source directory not found: $sourceDirectory');
  }
  final selected =
      selectedLocales.map((locale) => locale.toLowerCase()).toSet();
  final result = <String, List<File>>{};

  await for (final entity in root.list(followLinks: false)) {
    if (entity is! Directory) continue;
    final locale =
        entity.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
    if (selected.isNotEmpty && !selected.contains(locale.toLowerCase())) {
      continue;
    }
    final files = <File>[];
    await for (final child in entity.list(followLinks: false)) {
      if (child is! File) continue;
      final lower = child.path.toLowerCase();
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg')) {
        files.add(child);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    if (files.isEmpty) continue;
    result[locale] = files;
  }
  return result;
}

/// Reads locale subdirectories and produces a sandbox-safe upload payload.
Future<Map<String, List<Map<String, String>>>> encodeLocaleScreenshots(
  String sourceDirectory, {
  List<String> selectedLocales = const [],
}) async {
  final byLocale = await readLocaleScreenshots(
    sourceDirectory,
    selectedLocales: selectedLocales,
  );
  final result = <String, List<Map<String, String>>>{};
  for (final entry in byLocale.entries) {
    result[entry.key] = [
      for (final file in entry.value)
        {
          'name': file.uri.pathSegments.last,
          'data': base64Encode(await file.readAsBytes()),
        },
    ];
  }
  return result;
}
