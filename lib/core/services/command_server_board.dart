part of 'command_server.dart';

// =============================================================================
// Board routes — one canvas sliced into screenshots by crop zones
// =============================================================================

/// Board-editor routes.
///
/// A board's *background and overlays* are an ordinary [ScreenshotDesign], so
/// those stay on `/api/editor/`; only what is board-specific lives here — crop
/// zones, frame elements, spacing, layouts, and the single-capture export.
extension _BoardRoutes on CommandServer {
  Future<Map<String, dynamic>> handleBoard(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final boardAction = BoardAction.fromActionName(action);
    if (boardAction == null) {
      return ServerResponse.error('Unknown board action: $action');
    }

    // ── Actions that do not need an open board ────────────────────────────

    // Listing layouts is static data — useful before opening anything.
    if (boardAction == BoardAction.listTemplates) {
      return ServerResponse.ok({
        'templates': BoardTemplates.all
            .map(
              (t) => {
                'id': t.id,
                'name': t.name,
                'description': t.description,
                'zoneGap': t.zoneGap,
                'rotations': t.framePattern.map((p) => p.rotation).toList(),
              },
            )
            .toList(),
      });
    }

    // ── open: navigate to the board editor ────────────────────────────────
    // Handled before the cubit null-check: opening the page is the whole point
    // of this command, so the cubit does not exist yet.
    if (boardAction == BoardAction.open) {
      final body = method == 'POST'
          ? await _readBody(request)
          : <String, dynamic>{};
      final displayType = body['displayType'] as String? ?? 'APP_IPHONE_67';
      final zoneCount = (body['zoneCount'] as num?)?.toInt() ?? 3;

      if (_navigateToBoardCallback == null) {
        return ServerResponse.error(
          'Navigation callback not registered. '
          'Make sure the app is on the library/studio page.',
        );
      }

      await _navigateToBoardCallback!(displayType, zoneCount);

      // Poll until the board cubit registers (page mounted and ready).
      const maxWait = Duration(seconds: 10);
      const pollInterval = Duration(milliseconds: 200);
      final deadline = DateTime.now().add(maxWait);
      while (_boardCubit == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(pollInterval);
      }

      if (_boardCubit == null) {
        return ServerResponse.error(
          'Timed out waiting for board editor to initialize',
        );
      }

      return ServerResponse.ok({
        'displayType': displayType,
        'zoneCount': _boardCubit!.state.board.cropZones.length,
      });
    }

    // ── All other actions require the cubit ───────────────────────────────
    if (_boardCubit == null) {
      return ServerResponse.notReady('board editor');
    }

    final cubit = _boardCubit!;
    final body = method == 'POST'
        ? await _readBody(request)
        : <String, dynamic>{};

    switch (boardAction) {
      case BoardAction.open:
      case BoardAction.listTemplates:
        throw StateError('unreachable'); // handled above

      case BoardAction.state:
        final board = cubit.state.board;
        return ServerResponse.ok({
          'boardWidth': board.size.width,
          'boardHeight': board.size.height,
          'zoneGap': board.zoneGap,
          'zoneCount': board.cropZones.length,
          'exportCount': cubit.state.exportCount,
          'canAddZone': board.canAddZone,
          'maxZones': BoardDesign.maxZones,
          'maxPlayZones': BoardDesign.maxPlayZones,
          'exceedsPlayLimit': board.exceedsPlayLimit,
          'savedDesignId': cubit.state.savedDesignId,
          'savedDesignName': cubit.state.savedDesignName,
          'selectedZoneId': cubit.state.selectedZoneId,
          'selectedFrameId': cubit.state.selectedFrameId,
          'zones': board.cropZones
              .asMap()
              .entries
              .map(
                (e) => {
                  'index': e.key,
                  'id': e.value.id,
                  'name': e.value.name,
                  'displayType': e.value.displayType,
                  'x': e.value.position.dx,
                  'y': e.value.position.dy,
                  'width': e.value.size.width,
                  'height': e.value.size.height,
                  'locked': e.value.locked,
                  'included': e.value.included,
                },
              )
              .toList(),
          'frames': board.frames
              .map(
                (f) => {
                  'id': f.id,
                  'device': f.device?.name,
                  'imagePath': f.imagePath,
                  'x': f.position.dx,
                  'y': f.position.dy,
                  'width': f.size.width,
                  'height': f.size.height,
                  'rotationDegrees': f.rotation * 180 / math.pi,
                  'zIndex': f.zIndex,
                },
              )
              .toList(),
        });

      case BoardAction.addZone:
        if (!cubit.state.board.canAddZone) {
          return ServerResponse.error(
            'Maximum of ${BoardDesign.maxZones} crop zones reached '
            '(App Store Connect limit)',
          );
        }
        cubit.addZone(
          displayType: body['displayType'] as String?,
          orientation: _orientationFrom(body['orientation'] as String?),
        );
        return ServerResponse.ok({
          'zoneCount': cubit.state.board.cropZones.length,
          'zoneId': cubit.state.selectedZoneId,
        });

      case BoardAction.removeZone:
        final id = _zoneIdFrom(cubit, body);
        if (id == null) return ServerResponse.error('Missing "id" or "index"');
        if (cubit.state.board.cropZones.length <= 1) {
          return ServerResponse.error('A board must keep at least one zone');
        }
        cubit.removeZone(id);
        return ServerResponse.ok({
          'zoneCount': cubit.state.board.cropZones.length,
        });

      case BoardAction.updateZone:
        final id = _zoneIdFrom(cubit, body);
        if (id == null) return ServerResponse.error('Missing "id" or "index"');
        final zone = cubit.state.board.zoneById(id);
        if (zone == null) return ServerResponse.error('No zone with id $id');

        if (body.containsKey('included')) {
          cubit.setZoneIncluded(id, body['included'] == true);
        }
        if (body.containsKey('locked')) {
          cubit.setZoneLocked(id, body['locked'] == true);
        }
        if (body['displayType'] is String) {
          cubit.setZoneDisplayType(id, body['displayType'] as String);
        }
        if (body['orientation'] is String) {
          final o = _orientationFrom(body['orientation'] as String?);
          if (o != null) cubit.setZoneOrientation(id, o);
        }
        if (body.containsKey('name')) {
          cubit.renameZone(id, body['name'] as String?);
        }
        return ServerResponse.ok({'zoneId': id});

      case BoardAction.setZoneSpacing:
        final gap = (body['gap'] as num?)?.toDouble();
        if (gap == null) return ServerResponse.error('Missing "gap" (number)');
        cubit.setZoneGap(gap);
        return ServerResponse.ok({
          'zoneGap': cubit.state.board.zoneGap,
          'boardWidth': cubit.state.board.size.width,
        });

      case BoardAction.arrangeZones:
        cubit.autoArrangeZones(gap: (body['gap'] as num?)?.toDouble());
        return ServerResponse.ok({
          'zoneGap': cubit.state.board.zoneGap,
          'boardWidth': cubit.state.board.size.width,
        });

      case BoardAction.applyTemplate:
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id" (string)');
        final template = BoardTemplates.byId(id);
        if (template == null) {
          return ServerResponse.error(
            'Unknown template "$id". Use list-templates for valid ids.',
          );
        }
        // Frames and background live in different cubits; apply both so the
        // result matches what the picker produces in the UI.
        cubit.applyTemplate(template);
        _editorCubit?.applyBoardTemplateBackground(template);
        _syncCallback?.call();
        return ServerResponse.ok({
          'templateId': template.id,
          'zoneGap': cubit.state.board.zoneGap,
          'frameCount': cubit.state.board.frames.length,
        });

      case BoardAction.addFrame:
        final zoneId = body['zoneId'] as String?;
        cubit.addFrame(
          nearZone: zoneId == null
              ? cubit.state.selectedZone
              : cubit.state.board.zoneById(zoneId),
          imagePath: body['imagePath'] as String?,
        );
        return ServerResponse.ok({
          'frameId': cubit.state.selectedFrameId,
          'frameCount': cubit.state.board.frames.length,
        });

      case BoardAction.removeFrame:
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id" (string)');
        cubit.removeFrame(id);
        return ServerResponse.ok({
          'frameCount': cubit.state.board.frames.length,
        });

      case BoardAction.updateFrame:
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id" (string)');
        final frame = cubit.state.board.frameById(id);
        if (frame == null) return ServerResponse.error('No frame with id $id');

        final degrees = (body['rotationDegrees'] as num?)?.toDouble();
        cubit.updateFrame(
          frame.copyWith(
            position: Offset(
              (body['x'] as num?)?.toDouble() ?? frame.position.dx,
              (body['y'] as num?)?.toDouble() ?? frame.position.dy,
            ),
            size: Size(
              (body['width'] as num?)?.toDouble() ?? frame.size.width,
              (body['height'] as num?)?.toDouble() ?? frame.size.height,
            ),
            // Degrees over the wire; the model stores radians.
            rotation: degrees != null ? degrees * math.pi / 180 : frame.rotation,
            zIndex: (body['zIndex'] as num?)?.toInt() ?? frame.zIndex,
          ),
        );
        return ServerResponse.ok({'frameId': id});

      case BoardAction.setFrameImage:
        final id = body['id'] as String?;
        final path = body['path'] as String?;
        if (id == null || path == null) {
          return ServerResponse.error('Missing "id" and/or "path"');
        }
        final file = File(path);
        if (!await file.exists()) {
          return ServerResponse.error('File not found: $path');
        }
        await cubit.setFrameImage(id, file);
        return ServerResponse.ok({'frameId': id, 'path': path});

      case BoardAction.importImages:
        final paths = (body['paths'] as List?)?.cast<String>() ?? const [];
        if (paths.isEmpty) {
          return ServerResponse.error('Missing "paths" (array of strings)');
        }
        final files = <File>[];
        for (final path in paths) {
          final file = File(path);
          if (!await file.exists()) {
            return ServerResponse.error('File not found: $path');
          }
          files.add(file);
        }
        await cubit.importImages(files);
        return ServerResponse.ok({
          'imported': files.length,
          'frameCount': cubit.state.board.frames.length,
        });

      case BoardAction.export_:
      case BoardAction.exportAll:
        if (_boardExportCallback == null) {
          return ServerResponse.error(
            'No board export callback registered. Is the board UI visible?',
          );
        }
        final all = boardAction == BoardAction.exportAll;
        final zoneId = body['zoneId'] as String?;
        final outputDir = body['outputDir'] as String?;

        final files = await _boardExportCallback!(
          all ? null : (zoneId ?? cubit.state.selectedZoneId),
          outputDir,
        );
        if (files == null) {
          return ServerResponse.error('Board export failed');
        }
        return ServerResponse.ok({'files': files, 'count': files.length});

      case BoardAction.saveDesign:
        final name =
            body['name'] as String? ??
            cubit.state.savedDesignName ??
            'Board ${DateTime.now().toIso8601String().substring(0, 16)}';

        // Pull the live background/overlays into the board before persisting,
        // exactly as the UI does — otherwise a CLI save writes a board whose
        // background is whatever it had when the page opened.
        _syncCallback?.call();

        Uint8List thumbnailBytes = Uint8List(0);
        if (_captureCallback != null) {
          await Future.delayed(const Duration(milliseconds: 100));
          final captured = await _captureCallback!();
          if (captured != null) thumbnailBytes = Uint8List.fromList(captured);
        }

        await cubit.saveDesign(
          name,
          thumbnailBytes,
          override: body['override'] == true,
          translationBundle: _translationCubit?.state.bundle,
        );
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({
          'savedDesignId': cubit.state.savedDesignId,
          'savedDesignName': cubit.state.savedDesignName,
        });
    }
  }

  /// Resolves a zone from either an explicit `id` or a positional `index`.
  String? _zoneIdFrom(BoardCubit cubit, Map<String, dynamic> body) {
    final id = body['id'] as String?;
    if (id != null) return id;
    final index = (body['index'] as num?)?.toInt();
    if (index == null) return null;
    final zones = cubit.state.board.cropZones;
    if (index < 0 || index >= zones.length) return null;
    return zones[index].id;
  }

  Orientation? _orientationFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'portrait':
        return Orientation.portrait;
      case 'landscape':
        return Orientation.landscape;
      default:
        return null;
    }
  }
}
