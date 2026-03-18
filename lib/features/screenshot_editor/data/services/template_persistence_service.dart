import 'dart:convert';
import 'dart:io';

import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:path_provider/path_provider.dart';

class TemplatePersistenceService {
  static const String _templatesDirName = 'screenshot_templates';

  final String? _storageRootOverride;

  TemplatePersistenceService({String? storageRoot})
    : _storageRootOverride = storageRoot;

  Future<Directory> get _templatesDir async {
    if (_storageRootOverride != null) {
      final dir = Directory(_storageRootOverride);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_templatesDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> saveTemplate(ScreenshotPreset preset) async {
    try {
      final dir = await _templatesDir;
      final file = File('${dir.path}/${preset.id}.json');
      final jsonStr = jsonEncode(preset.toJson());
      await file.writeAsString(jsonStr);
      AppLogger.i(
        'Saved custom template: ${preset.id}',
        tag: 'TemplatePersistence',
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to save custom template',
        error: e,
        stackTrace: st,
        tag: 'TemplatePersistence',
      );
      rethrow;
    }
  }

  Future<List<ScreenshotPreset>> loadTemplates() async {
    try {
      final dir = await _templatesDir;
      final files = await dir.list().toList();
      final templates = <ScreenshotPreset>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            templates.add(ScreenshotPreset.fromJson(json));
          } catch (e, st) {
            AppLogger.error(
              'Failed to load template ${file.path}',
              tag: 'TemplatePersistence',
              error: e,
              stackTrace: st,
            );
          }
        }
      }

      // Sort templates alphabetically
      templates.sort((a, b) => a.name.compareTo(b.name));
      return templates;
    } catch (e, st) {
      AppLogger.error(
        'Failed to load custom templates',
        error: e,
        stackTrace: st,
        tag: 'TemplatePersistence',
      );
      return [];
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      final dir = await _templatesDir;
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
        AppLogger.i('Deleted custom template: $id', tag: 'TemplatePersistence');
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete custom template',
        error: e,
        stackTrace: st,
        tag: 'TemplatePersistence',
      );
      rethrow;
    }
  }
}
