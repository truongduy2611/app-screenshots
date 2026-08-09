import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';

/// `appshots board` — one canvas sliced into screenshots by crop zones.
///
/// Background and overlay editing stays on `appshots editor`: a board's
/// background is an ordinary design, so those commands already apply. Only
/// what is board-specific lives here.
class BoardCommand extends Command<int> {
  @override
  String get name => 'board';

  @override
  String get description =>
      'Manage board designs — crop zones, frames, layouts, export';

  BoardCommand() {
    addSubcommand(_BoardOpenCommand());
    addSubcommand(_BoardStateCommand());
    addSubcommand(_BoardAddZoneCommand());
    addSubcommand(_BoardRemoveZoneCommand());
    addSubcommand(_BoardUpdateZoneCommand());
    addSubcommand(_BoardSpacingCommand());
    addSubcommand(_BoardArrangeCommand());
    addSubcommand(_BoardTemplatesCommand());
    addSubcommand(_BoardApplyTemplateCommand());
    addSubcommand(_BoardAddFrameCommand());
    addSubcommand(_BoardRemoveFrameCommand());
    addSubcommand(_BoardUpdateFrameCommand());
    addSubcommand(_BoardSetFrameImageCommand());
    addSubcommand(_BoardImportCommand());
    addSubcommand(_BoardExportCommand());
    addSubcommand(_BoardSaveCommand());
  }
}

/// Shared plumbing: discover the app, call, print, map ok → exit code.
Future<int> _send(
  Command<int> cmd,
  String path, {
  Map<String, dynamic>? body,
  bool get = false,
}) async {
  final client = await AppClient.discover(
    portOverride: cmd.globalResults?['port'] as String?,
  );
  final result =
      get ? await client.get(path) : await client.post(path, body ?? const {});
  Output.print(result, json: Output.isJson(cmd.globalResults));
  client.close();
  return result['ok'] == true ? 0 : 1;
}

class _BoardOpenCommand extends Command<int> {
  @override
  String get name => 'open';
  @override
  String get description => 'Open the board editor for a device type';

  _BoardOpenCommand() {
    argParser
      ..addOption(
        'display-type',
        abbr: 'd',
        help: 'ASC display type (e.g. APP_IPHONE_67)',
        defaultsTo: 'APP_IPHONE_67',
      )
      ..addOption(
        'zones',
        abbr: 'z',
        help: 'Number of crop zones to start with',
        defaultsTo: '3',
      );
  }

  @override
  Future<int> run() => _send(this, BoardAction.open.path, body: {
        'displayType': argResults!['display-type'],
        'zoneCount': int.parse(argResults!['zones'] as String),
      });
}

class _BoardStateCommand extends Command<int> {
  @override
  String get name => 'state';
  @override
  String get description => 'Show board state — zones, frames, spacing, limits';

  @override
  Future<int> run() => _send(this, BoardAction.state.path, get: true);
}

class _BoardAddZoneCommand extends Command<int> {
  @override
  String get name => 'add-zone';
  @override
  String get description => 'Add a crop zone (one more exported screenshot)';

  _BoardAddZoneCommand() {
    argParser
      ..addOption('display-type', abbr: 'd', help: 'Export format for the zone')
      ..addOption('orientation', help: 'portrait or landscape');
  }

  @override
  Future<int> run() => _send(this, BoardAction.addZone.path, body: {
        if (argResults!['display-type'] != null)
          'displayType': argResults!['display-type'],
        if (argResults!['orientation'] != null)
          'orientation': argResults!['orientation'],
      });
}

class _BoardRemoveZoneCommand extends Command<int> {
  @override
  String get name => 'remove-zone';
  @override
  String get description => 'Remove a crop zone by id or index';

  _BoardRemoveZoneCommand() {
    argParser
      ..addOption('id', help: 'Zone id')
      ..addOption('index', abbr: 'i', help: 'Zone index (0-based)');
  }

  @override
  Future<int> run() => _send(this, BoardAction.removeZone.path, body: {
        if (argResults!['id'] != null) 'id': argResults!['id'],
        if (argResults!['index'] != null)
          'index': int.parse(argResults!['index'] as String),
      });
}

class _BoardUpdateZoneCommand extends Command<int> {
  @override
  String get name => 'update-zone';
  @override
  String get description =>
      'Change a zone — include/exclude from export, lock, format, name';

  _BoardUpdateZoneCommand() {
    argParser
      ..addOption('id', help: 'Zone id')
      ..addOption('index', abbr: 'i', help: 'Zone index (0-based)')
      ..addOption('display-type', abbr: 'd', help: 'Export format')
      ..addOption('orientation', help: 'portrait or landscape')
      ..addOption('name', help: 'Zone label')
      ..addFlag('included', help: 'Include this zone in exports')
      ..addFlag('locked', help: 'Pin the zone to its format size');
  }

  @override
  Future<int> run() {
    final r = argResults!;
    return _send(this, BoardAction.updateZone.path, body: {
      if (r['id'] != null) 'id': r['id'],
      if (r['index'] != null) 'index': int.parse(r['index'] as String),
      if (r['display-type'] != null) 'displayType': r['display-type'],
      if (r['orientation'] != null) 'orientation': r['orientation'],
      if (r['name'] != null) 'name': r['name'],
      if (r.wasParsed('included')) 'included': r['included'],
      if (r.wasParsed('locked')) 'locked': r['locked'],
    });
  }
}

class _BoardSpacingCommand extends Command<int> {
  @override
  String get name => 'spacing';
  @override
  String get description =>
      'Set the gap between zones (0 = one continuous panorama)';

  _BoardSpacingCommand() {
    argParser.addOption(
      'gap',
      abbr: 'g',
      help: 'Gap in board pixels; 0 butts the zones together',
      mandatory: true,
    );
  }

  @override
  Future<int> run() => _send(this, BoardAction.setZoneSpacing.path, body: {
        'gap': double.parse(argResults!['gap'] as String),
      });
}

class _BoardArrangeCommand extends Command<int> {
  @override
  String get name => 'arrange';
  @override
  String get description => 'Re-lay the zones out in a row';

  _BoardArrangeCommand() {
    argParser.addOption('gap', abbr: 'g', help: 'Override the spacing');
  }

  @override
  Future<int> run() => _send(this, BoardAction.arrangeZones.path, body: {
        if (argResults!['gap'] != null)
          'gap': double.parse(argResults!['gap'] as String),
      });
}

class _BoardTemplatesCommand extends Command<int> {
  @override
  String get name => 'templates';
  @override
  String get description => 'List the built-in board layouts';

  @override
  Future<int> run() => _send(this, BoardAction.listTemplates.path, get: true);
}

class _BoardApplyTemplateCommand extends Command<int> {
  @override
  String get name => 'apply-template';
  @override
  String get description =>
      'Apply a board layout (background + frame placement)';

  _BoardApplyTemplateCommand() {
    argParser.addOption(
      'id',
      help: 'Template id — see `board templates`',
      mandatory: true,
    );
  }

  @override
  Future<int> run() => _send(this, BoardAction.applyTemplate.path, body: {
        'id': argResults!['id'],
      });
}

class _BoardAddFrameCommand extends Command<int> {
  @override
  String get name => 'add-frame';
  @override
  String get description => 'Add a device frame to the board';

  _BoardAddFrameCommand() {
    argParser
      ..addOption('zone-id', help: 'Place it inside this zone')
      ..addOption('image', help: 'Screenshot to put in the frame');
  }

  @override
  Future<int> run() => _send(this, BoardAction.addFrame.path, body: {
        if (argResults!['zone-id'] != null) 'zoneId': argResults!['zone-id'],
        if (argResults!['image'] != null) 'imagePath': argResults!['image'],
      });
}

class _BoardRemoveFrameCommand extends Command<int> {
  @override
  String get name => 'remove-frame';
  @override
  String get description => 'Remove a device frame';

  _BoardRemoveFrameCommand() {
    argParser.addOption('id', help: 'Frame id', mandatory: true);
  }

  @override
  Future<int> run() => _send(this, BoardAction.removeFrame.path, body: {
        'id': argResults!['id'],
      });
}

class _BoardUpdateFrameCommand extends Command<int> {
  @override
  String get name => 'update-frame';
  @override
  String get description => 'Move, resize, rotate, or restack a frame';

  _BoardUpdateFrameCommand() {
    argParser
      ..addOption('id', help: 'Frame id', mandatory: true)
      ..addOption('x', help: 'Left, in board pixels')
      ..addOption('y', help: 'Top, in board pixels')
      ..addOption('width', help: 'Width, in board pixels')
      ..addOption('height', help: 'Height, in board pixels')
      ..addOption('rotation', abbr: 'r', help: 'Rotation in degrees')
      ..addOption('z-index', help: 'Paint order');
  }

  @override
  Future<int> run() {
    final r = argResults!;
    double? num_(String k) =>
        r[k] == null ? null : double.parse(r[k] as String);
    return _send(this, BoardAction.updateFrame.path, body: {
      'id': r['id'],
      if (num_('x') != null) 'x': num_('x'),
      if (num_('y') != null) 'y': num_('y'),
      if (num_('width') != null) 'width': num_('width'),
      if (num_('height') != null) 'height': num_('height'),
      if (num_('rotation') != null) 'rotationDegrees': num_('rotation'),
      if (r['z-index'] != null) 'zIndex': int.parse(r['z-index'] as String),
    });
  }
}

class _BoardSetFrameImageCommand extends Command<int> {
  @override
  String get name => 'set-frame-image';
  @override
  String get description => 'Put a screenshot inside a frame';

  _BoardSetFrameImageCommand() {
    argParser
      ..addOption('id', help: 'Frame id', mandatory: true)
      ..addOption('path', abbr: 'p', help: 'Image file', mandatory: true);
  }

  @override
  Future<int> run() => _send(this, BoardAction.setFrameImage.path, body: {
        'id': argResults!['id'],
        'path': argResults!['path'],
      });
}

class _BoardImportCommand extends Command<int> {
  @override
  String get name => 'import';
  @override
  String get description =>
      'Import screenshots — fills empty frames first, then adds more';

  _BoardImportCommand() {
    argParser.addMultiOption(
      'path',
      abbr: 'p',
      help: 'Image file (repeat for several)',
    );
  }

  @override
  Future<int> run() => _send(this, BoardAction.importImages.path, body: {
        'paths': argResults!['path'],
      });
}

class _BoardExportCommand extends Command<int> {
  @override
  String get name => 'export';
  @override
  String get description => 'Export crop zones to PNG';

  _BoardExportCommand() {
    argParser
      ..addFlag(
        'all',
        help: 'Every zone marked for export (default: the selected one)',
      )
      ..addOption('zone-id', help: 'Export just this zone')
      ..addOption('out', abbr: 'o', help: 'Output directory');
  }

  @override
  Future<int> run() {
    final all = argResults!['all'] == true;
    return _send(
      this,
      all ? BoardAction.exportAll.path : BoardAction.export_.path,
      body: {
        if (argResults!['zone-id'] != null) 'zoneId': argResults!['zone-id'],
        if (argResults!['out'] != null) 'outputDir': argResults!['out'],
      },
    );
  }
}

class _BoardSaveCommand extends Command<int> {
  @override
  String get name => 'save';
  @override
  String get description => 'Save the board to the library';

  _BoardSaveCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Design name')
      ..addFlag('override', help: 'Overwrite the existing saved design');
  }

  @override
  Future<int> run() => _send(this, BoardAction.saveDesign.path, body: {
        if (argResults!['name'] != null) 'name': argResults!['name'],
        'override': argResults!['override'] == true,
      });
}
