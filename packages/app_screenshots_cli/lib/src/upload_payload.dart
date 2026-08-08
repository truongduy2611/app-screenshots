import 'dart:convert';
import 'dart:io';

/// Reads locale subdirectories and produces a sandbox-safe upload payload.
Future<Map<String, List<Map<String, String>>>> encodeLocaleScreenshots(
  String sourceDirectory, {
  List<String> selectedLocales = const [],
}) async {
  final root = Directory(sourceDirectory);
  if (!await root.exists()) {
    throw ArgumentError('Source directory not found: $sourceDirectory');
  }
  final selected =
      selectedLocales.map((locale) => locale.toLowerCase()).toSet();
  final result = <String, List<Map<String, String>>>{};

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
    result[locale] = [
      for (final file in files)
        {
          'name': file.uri.pathSegments.last,
          'data': base64Encode(await file.readAsBytes()),
        },
    ];
  }
  return result;
}
