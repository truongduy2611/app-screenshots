import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import '../app_client.dart';
import '../output.dart';

/// `appshots translate` — manage translations for text overlays.
class TranslateCommand extends Command<int> {
  @override
  String get name => 'translate';

  @override
  String get description => 'Translate text overlays across screenshots';

  TranslateCommand() {
    addSubcommand(_TranslateStateCommand());
    addSubcommand(_TranslateGetTextsCommand());
    addSubcommand(_TranslateAllCommand());
    addSubcommand(_TranslatePreviewCommand());
    addSubcommand(_TranslateEditCommand());
    addSubcommand(_TranslateApplyManualCommand());
    addSubcommand(_TranslateRemoveLocaleCommand());
    addSubcommand(_TranslateSetPromptCommand());
    addSubcommand(_TranslateOverrideOverlayCommand());
    addSubcommand(_TranslateSetLocaleImageCommand());
  }
}

class _TranslateStateCommand extends Command<int> {
  @override
  String get name => 'state';
  @override
  String get description =>
      'Show current translation state (bundle, locales, statuses)';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(TranslateAction.state.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateGetTextsCommand extends Command<int> {
  @override
  String get name => 'get-texts';
  @override
  String get description =>
      'Get all text overlays from all designs (for translation)';

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.get(TranslateAction.getTexts.path);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateAllCommand extends Command<int> {
  @override
  String get name => 'all';
  @override
  String get description => 'AI-translate all text overlays to target locales';

  _TranslateAllCommand() {
    argParser.addOption('from', help: 'Source locale', defaultsTo: 'en');
    argParser.addOption('to',
        help: 'Comma-separated target locales (e.g. ja,ko,de)',
        mandatory: true);
  }

  @override
  Future<int> run() async {
    final to = argResults!['to'] as String;
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.all.path, {
      'from': argResults!['from'],
      'to': to.split(',').map((s) => s.trim()).toList(),
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslatePreviewCommand extends Command<int> {
  @override
  String get name => 'preview';
  @override
  String get description =>
      'Preview a locale in the editor (pass "none" to clear)';

  _TranslatePreviewCommand() {
    argParser.addOption('locale',
        abbr: 'l', help: 'Locale to preview (or "none")', mandatory: true);
  }

  @override
  Future<int> run() async {
    final locale = argResults!['locale'] as String;
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.preview.path, {
      'locale': locale == 'none' ? null : locale,
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateEditCommand extends Command<int> {
  @override
  String get name => 'edit';
  @override
  String get description => 'Edit a single overlay translation for a locale';

  _TranslateEditCommand() {
    argParser.addOption('locale',
        abbr: 'l', help: 'Target locale', mandatory: true);
    argParser.addOption('overlay-id',
        help: 'Overlay ID to update', mandatory: true);
    argParser.addOption('text',
        abbr: 't', help: 'Translated text', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.edit.path, {
      'locale': argResults!['locale'],
      'overlayId': argResults!['overlay-id'],
      'text': argResults!['text'],
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateApplyManualCommand extends Command<int> {
  @override
  String get name => 'apply-manual';
  @override
  String get description =>
      'Apply manual translations for a locale (JSON map of overlayId→text)';

  _TranslateApplyManualCommand() {
    argParser.addOption('locale',
        abbr: 'l', help: 'Target locale', mandatory: true);
    argParser.addOption('translations',
        abbr: 't',
        help: 'JSON map: {"overlayId": "translated text", ...}',
        mandatory: true);
  }

  @override
  Future<int> run() async {
    final translationsJson = argResults!['translations'] as String;
    Map<String, dynamic> translations;
    try {
      translations = jsonDecode(translationsJson) as Map<String, dynamic>;
    } catch (e) {
      usageException('Invalid JSON for --translations: $e');
    }
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.applyManual.path, {
      'locale': argResults!['locale'],
      'translations': translations.cast<String, String>(),
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateRemoveLocaleCommand extends Command<int> {
  @override
  String get name => 'remove-locale';
  @override
  String get description =>
      'Remove all translations and overrides for a locale';

  _TranslateRemoveLocaleCommand() {
    argParser.addOption('locale',
        abbr: 'l', help: 'Locale to remove', mandatory: true);
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.removeLocale.path, {
      'locale': argResults!['locale'],
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateSetPromptCommand extends Command<int> {
  @override
  String get name => 'set-prompt';
  @override
  String get description => 'Set custom context/prompt for AI translations';

  _TranslateSetPromptCommand() {
    argParser.addOption('prompt',
        abbr: 'p', help: 'Custom prompt text (empty to clear)');
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.setPrompt.path, {
      'prompt': argResults?['prompt'],
    });
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateOverrideOverlayCommand extends Command<int> {
  @override
  String get name => 'override-overlay';
  @override
  String get description => 'Set per-locale overlay style/position override';

  _TranslateOverrideOverlayCommand() {
    argParser.addOption('locale',
        help: 'Target locale (e.g. de, ja)', mandatory: true);
    argParser.addOption('overlay-id', help: 'Overlay ID', mandatory: true);
    argParser.addOption('font', help: 'Override Google Font name');
    argParser.addOption('font-size', help: 'Override font size');
    argParser.addOption('x', help: 'Override X position');
    argParser.addOption('y', help: 'Override Y position');
    argParser.addOption('scale', help: 'Override scale');
    argParser.addOption('rotation', help: 'Override rotation');
    argParser.addOption('width', help: 'Override width');
    argParser.addOption('color', help: 'Override text color (hex)');
    argParser.addOption('font-weight',
        help: 'Override font weight index (0-8)');
  }

  @override
  Future<int> run() async {
    final body = <String, dynamic>{
      'locale': argResults!['locale'],
      'overlayId': argResults!['overlay-id'],
    };
    if (argResults?['font'] != null) body['font'] = argResults!['font'];
    if (argResults?['font-size'] != null)
      body['fontSize'] = double.parse(argResults!['font-size']);
    if (argResults?['x'] != null) body['x'] = double.parse(argResults!['x']);
    if (argResults?['y'] != null) body['y'] = double.parse(argResults!['y']);
    if (argResults?['scale'] != null)
      body['scale'] = double.parse(argResults!['scale']);
    if (argResults?['rotation'] != null)
      body['rotation'] = double.parse(argResults!['rotation']);
    if (argResults?['width'] != null)
      body['width'] = double.parse(argResults!['width']);
    if (argResults?['color'] != null) body['color'] = argResults!['color'];
    if (argResults?['font-weight'] != null)
      body['fontWeightIndex'] = int.parse(argResults!['font-weight']);
    final client = await AppClient.discover();
    final result =
        await client.post(TranslateAction.overrideOverlay.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

class _TranslateSetLocaleImageCommand extends Command<int> {
  @override
  String get name => 'set-locale-image';
  @override
  String get description => 'Set a per-locale screenshot image';

  _TranslateSetLocaleImageCommand() {
    argParser.addOption('locale',
        help: 'Target locale (e.g. de, ja)', mandatory: true);
    argParser.addOption('file',
        abbr: 'f', help: 'Path to the screenshot image file', mandatory: true);
  }

  @override
  Future<int> run() async {
    final filePath = argResults!['file'] as String;
    final file = File(filePath);
    if (!file.existsSync()) {
      stderr.writeln('❌ File not found: $filePath');
      return 1;
    }
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final body = <String, dynamic>{
      'locale': argResults!['locale'],
      'data': base64Data,
    };
    final client = await AppClient.discover();
    final result = await client.post(TranslateAction.setLocaleImage.path, body);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}
