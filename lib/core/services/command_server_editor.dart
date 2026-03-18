part of 'command_server.dart';

// =============================================================================
// Editor routes — design manipulation, overlays, export
// =============================================================================

extension _EditorRoutes on CommandServer {
  /// Read-only editor actions that don't need to sync back to multi cubit.
  static const _readOnlyActions = {
    EditorAction.state,
    EditorAction.listOverlays,
    EditorAction.listDevices,
    EditorAction.listFonts,
    EditorAction.listIcons,
  };

  Future<Map<String, dynamic>> handleEditor(
    String action,
    String method,
    HttpRequest request,
  ) async {
    if (_editorCubit == null) {
      return ServerResponse.notReady('editor');
    }

    final editorAction = EditorAction.fromActionName(action);
    if (editorAction == null) {
      return ServerResponse.error('Unknown editor action: $action');
    }

    final cubit = _editorCubit!;
    final result = await _handleEditorAction(
      editorAction,
      method,
      request,
      cubit,
    );

    // Auto-sync editor changes back to multi cubit for mutating actions,
    // so CLI-driven edits (delete-overlay, set-rotation, etc.) are
    // persisted when switching between design slots.
    if (!_readOnlyActions.contains(editorAction) && _multiCubit != null) {
      _syncCallback?.call();
    }

    return result;
  }

  Future<Map<String, dynamic>> _handleEditorAction(
    EditorAction editorAction,
    String method,
    HttpRequest request,
    ScreenshotEditorCubit cubit,
  ) async {
    switch (editorAction) {
      case EditorAction.state:
        return ServerResponse.ok({
          'design': cubit.state.design.toJson(),
          'selectedOverlayId': cubit.state.selectedOverlayId,
          'canUndo': cubit.state.canUndo,
          'canRedo': cubit.state.canRedo,
          'savedDesignId': cubit.state.savedDesignId,
          'savedDesignName': cubit.state.savedDesignName,
        });

      case EditorAction.setBackground:
        final body = await _readBody(request);
        final colorStr = body['color'] as String?;
        if (colorStr == null)
          return ServerResponse.error(
            'Missing "color" (hex string e.g. "#FF5733")',
          );
        final color = parseHexColor(colorStr);
        if (color == null)
          return ServerResponse.error('Invalid color format: $colorStr');
        cubit.updateBackgroundColor(color);
        return ServerResponse.ok({'color': colorStr});

      case EditorAction.setGradient:
        final body = await _readBody(request);
        final gradientJson = body['gradient'] as Map<String, dynamic>?;
        if (gradientJson == null) {
          cubit.updateBackgroundGradient(null);
          return ServerResponse.ok({'gradient': null});
        }
        final gradient = ScreenshotDesign.fromJson({
          'backgroundGradient': gradientJson,
        }).backgroundGradient;
        cubit.updateBackgroundGradient(gradient);
        return ServerResponse.ok({'gradient': 'set'});

      case EditorAction.setTransparent:
        final body = await _readBody(request);
        final value = body['transparent'] as bool? ?? false;
        cubit.updateTransparentBackground(value);
        return ServerResponse.ok({'transparent': value});

      case EditorAction.setFrame:
        final body = await _readBody(request);
        final deviceName = body['device'] as String?;
        if (deviceName == null) {
          cubit.updateDeviceFrame(null);
          return ServerResponse.ok({'device': null});
        }
        final device = Devices.all
            .where(
              (d) => d.name.toLowerCase().contains(deviceName.toLowerCase()),
            )
            .firstOrNull;
        if (device == null) {
          return {
            'ok': false,
            'error': 'Device not found: $deviceName',
            'available': Devices.all.map((d) => d.name).toList(),
          };
        }
        cubit.updateDeviceFrame(device);
        return ServerResponse.ok({'device': device.name});

      case EditorAction.listDevices:
        return ServerResponse.ok(
          Devices.all
              .map(
                (d) => {
                  'name': d.name,
                  'platform': d.identifier.platform.name,
                  'type': d.identifier.type.name,
                },
              )
              .toList(),
        );

      case EditorAction.listFonts:
        final body = method == 'POST'
            ? await _readBody(request)
            : <String, dynamic>{};
        final query = (body['query'] as String?)?.toLowerCase();
        final limit = (body['limit'] as int?) ?? 50;
        var allFonts = GoogleFonts.asMap().keys.toList();
        if (query != null && query.isNotEmpty) {
          allFonts = allFonts
              .where((f) => f.toLowerCase().contains(query))
              .toList();
        }
        final fontsInUse = <String>{};
        for (final overlay in cubit.state.design.overlays) {
          if (overlay.googleFont != null) fontsInUse.add(overlay.googleFont!);
        }
        return ServerResponse.ok({
          'total': allFonts.length,
          'showing': allFonts.length > limit ? limit : allFonts.length,
          'fontsInUse': fontsInUse.toList(),
          'fonts': allFonts.take(limit).toList(),
        });

      case EditorAction.setPadding:
        final body = await _readBody(request);
        final padding = (body['padding'] as num?)?.toDouble();
        if (padding == null)
          return ServerResponse.error('Missing "padding" (number)');
        cubit.updatePadding(padding);
        return ServerResponse.ok({'padding': padding});

      case EditorAction.setCornerRadius:
        final body = await _readBody(request);
        final radius = (body['radius'] as num?)?.toDouble();
        if (radius == null)
          return ServerResponse.error('Missing "radius" (number)');
        cubit.updateCornerRadius(radius);
        return ServerResponse.ok({'radius': radius});

      case EditorAction.setRotation:
        final body = await _readBody(request);
        final x = (body['x'] as num?)?.toDouble();
        final y = (body['y'] as num?)?.toDouble();
        final z = (body['z'] as num?)?.toDouble();
        if (x != null) cubit.updateFrameRotationX(x);
        if (y != null) cubit.updateFrameRotationY(y);
        if (z != null) cubit.updateFrameRotation(z);
        return ServerResponse.ok({'x': x, 'y': y, 'z': z});

      case EditorAction.setOrientation:
        cubit.toggleOrientation();
        return ServerResponse.ok({
          'orientation': cubit.state.design.orientation.name,
        });

      case EditorAction.setImage:
        final body = await _readBody(request);
        final filePath = body['file'] as String?;
        if (filePath == null)
          return ServerResponse.error('Missing "file" (path)');
        final file = File(filePath);
        if (!await file.exists())
          return ServerResponse.error('File not found: $filePath');
        cubit.updateImageFile(file);
        return ServerResponse.ok({'file': filePath});

      case EditorAction.setImagePosition:
        final body = await _readBody(request);
        final x = (body['x'] as num?)?.toDouble() ?? 0;
        final y = (body['y'] as num?)?.toDouble() ?? 0;
        cubit.updateImagePosition(Offset(x, y));
        return ServerResponse.ok({'x': x, 'y': y});

      case EditorAction.setImageBase64:
        final body = await _readBody(request);
        final base64Data = body['data'] as String?;
        if (base64Data == null)
          return ServerResponse.error('Missing "data" (base64 PNG/JPG)');
        try {
          final bytes = base64Decode(base64Data);
          final tempDir = Directory.systemTemp;
          final fileName =
              'cli_upload_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          cubit.updateImageFile(file);
          return ServerResponse.ok({
            'file': file.path,
            'sizeBytes': bytes.length,
          });
        } catch (e) {
          return ServerResponse.error('Failed to decode base64: $e');
        }

      case EditorAction.addText:
        final body = await _readBody(request);
        cubit.addTextOverlay();
        final newOverlay = cubit.state.design.overlays.last;
        final text = body['text'] as String? ?? 'New Text';
        final fontSize = (body['fontSize'] as num?)?.toDouble() ?? 40;
        final colorStr = body['color'] as String?;
        final fontName = body['font'] as String?;
        final x = (body['x'] as num?)?.toDouble();
        final y = (body['y'] as num?)?.toDouble();
        final scale = (body['scale'] as num?)?.toDouble();
        final width = (body['width'] as num?)?.toDouble();
        final alignStr = body['align'] as String?;
        final textAlign = alignStr == 'left'
            ? TextAlign.left
            : alignStr == 'right'
            ? TextAlign.right
            : TextAlign.center;

        final updated = TextOverlay(
          id: newOverlay.id,
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: colorStr != null
                ? (parseHexColor(colorStr) ?? Colors.white)
                : Colors.white,
          ),
          position: Offset(
            x ?? newOverlay.position.dx,
            y ?? newOverlay.position.dy,
          ),
          googleFont: fontName,
          scale: scale ?? newOverlay.scale,
          width: width,
          textAlign: textAlign,
        );
        cubit.updateTextOverlay(newOverlay.id, updated);
        return ServerResponse.ok({'overlayId': newOverlay.id, 'text': text});

      case EditorAction.updateText:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null)
          return ServerResponse.error('Missing "id" (overlay ID)');
        final existing = cubit.state.design.overlays
            .where((o) => o.id == id)
            .firstOrNull;
        if (existing == null)
          return ServerResponse.error('Overlay not found: $id');

        var updated = existing;
        if (body.containsKey('text'))
          updated = updated.copyWith(text: body['text'] as String);
        if (body.containsKey('fontSize')) {
          updated = updated.copyWith(
            style: updated.style.copyWith(
              fontSize: (body['fontSize'] as num).toDouble(),
            ),
          );
        }
        if (body.containsKey('color')) {
          final c = parseHexColor(body['color'] as String);
          if (c != null)
            updated = updated.copyWith(style: updated.style.copyWith(color: c));
        }
        if (body.containsKey('font'))
          updated = updated.copyWith(googleFont: body['font'] as String);
        if (body.containsKey('x') || body.containsKey('y')) {
          updated = updated.copyWith(
            position: Offset(
              (body['x'] as num?)?.toDouble() ?? updated.position.dx,
              (body['y'] as num?)?.toDouble() ?? updated.position.dy,
            ),
          );
        }
        if (body.containsKey('scale')) {
          updated = updated.copyWith(scale: (body['scale'] as num).toDouble());
        }
        if (body.containsKey('rotation')) {
          updated = updated.copyWith(
            rotation: (body['rotation'] as num).toDouble(),
          );
        }
        if (body.containsKey('width')) {
          updated = updated.copyWith(width: (body['width'] as num).toDouble());
        }
        if (body.containsKey('align')) {
          final alignStr = body['align'] as String;
          final textAlign = alignStr == 'left'
              ? TextAlign.left
              : alignStr == 'right'
              ? TextAlign.right
              : TextAlign.center;
          updated = updated.copyWith(textAlign: textAlign);
        }
        cubit.updateTextOverlay(id, updated);
        return ServerResponse.ok({'overlayId': id});

      case EditorAction.addImage:
        final body = await _readBody(request);
        final filePath = body['file'] as String?;
        if (filePath == null)
          return ServerResponse.error('Missing "file" (path)');
        final file = File(filePath);
        if (!await file.exists())
          return ServerResponse.error('File not found: $filePath');
        final success = cubit.addImageOverlay(file);
        if (!success)
          return ServerResponse.error('Image overlay limit reached (max 10)');
        final overlay = cubit.state.design.imageOverlays.last;
        if (body.containsKey('x') ||
            body.containsKey('y') ||
            body.containsKey('width') ||
            body.containsKey('height')) {
          cubit.updateImageOverlay(
            overlay.id,
            overlay.copyWith(
              position: Offset(
                (body['x'] as num?)?.toDouble() ?? overlay.position.dx,
                (body['y'] as num?)?.toDouble() ?? overlay.position.dy,
              ),
              width: (body['width'] as num?)?.toDouble() ?? overlay.width,
              height: (body['height'] as num?)?.toDouble() ?? overlay.height,
            ),
          );
        }
        return ServerResponse.ok({'overlayId': overlay.id});

      case EditorAction.updateImage:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id"');
        final existing = cubit.state.design.imageOverlays
            .where((o) => o.id == id)
            .firstOrNull;
        if (existing == null)
          return ServerResponse.error('Image overlay not found: $id');
        var updated = existing;
        if (body.containsKey('x') || body.containsKey('y')) {
          updated = updated.copyWith(
            position: Offset(
              (body['x'] as num?)?.toDouble() ?? updated.position.dx,
              (body['y'] as num?)?.toDouble() ?? updated.position.dy,
            ),
          );
        }
        if (body.containsKey('width'))
          updated = updated.copyWith(width: (body['width'] as num).toDouble());
        if (body.containsKey('height'))
          updated = updated.copyWith(
            height: (body['height'] as num).toDouble(),
          );
        if (body.containsKey('scale'))
          updated = updated.copyWith(scale: (body['scale'] as num).toDouble());
        if (body.containsKey('rotation'))
          updated = updated.copyWith(
            rotation: (body['rotation'] as num).toDouble(),
          );
        if (body.containsKey('opacity'))
          updated = updated.copyWith(
            opacity: (body['opacity'] as num).toDouble(),
          );
        if (body.containsKey('cornerRadius'))
          updated = updated.copyWith(
            cornerRadius: (body['cornerRadius'] as num).toDouble(),
          );
        cubit.updateImageOverlay(id, updated);
        return ServerResponse.ok({'overlayId': id});

      case EditorAction.addIcon:
        final body = await _readBody(request);
        final codePoint = body['codePoint'] as int?;
        if (codePoint == null)
          return ServerResponse.error('Missing "codePoint" (int)');
        final fontFamily = body['fontFamily'] as String? ?? 'MaterialIcons';
        final fontPackage = body['fontPackage'] as String? ?? '';
        final colorStr = body['color'] as String?;
        final color = colorStr != null
            ? (parseHexColor(colorStr) ?? Colors.white)
            : Colors.white;
        cubit.addIconOverlay(codePoint, fontFamily, fontPackage, color: color);
        final overlay = cubit.state.design.iconOverlays.last;
        return ServerResponse.ok({
          'overlayId': overlay.id,
          'codePoint': codePoint,
        });

      case EditorAction.listIcons:
        final body = method == 'POST'
            ? await _readBody(request)
            : <String, dynamic>{};
        final query = body['query'] as String?;
        final style = body['style'] as String?;
        final catalog = getIconCatalog(query: query, style: style);
        return ServerResponse.ok({'total': catalog.length, 'icons': catalog});

      case EditorAction.addMagnifier:
        cubit.addMagnifierOverlay();
        final overlay = cubit.state.design.magnifierOverlays.last;
        return ServerResponse.ok({'overlayId': overlay.id});

      case EditorAction.setDisplayType:
        final body = await _readBody(request);
        final displayType = body['displayType'] as String?;
        if (displayType == null)
          return ServerResponse.error(
            'Missing "displayType" (e.g. APP_IPHONE_69)',
          );
        final design = cubit.state.design.copyWith(displayType: displayType);
        cubit.replaceDesign(design);
        return ServerResponse.ok({'displayType': displayType});

      case EditorAction.selectOverlay:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        cubit.selectOverlay(id);
        return ServerResponse.ok({'selectedOverlayId': id});

      case EditorAction.deleteOverlay:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) {
          cubit.deleteSelectedOverlay();
        } else {
          cubit.selectOverlay(id);
          cubit.deleteSelectedOverlay();
        }
        return ServerResponse.ok();

      case EditorAction.moveOverlay:
        final body = await _readBody(request);
        final dx = (body['dx'] as num?)?.toDouble() ?? 0;
        final dy = (body['dy'] as num?)?.toDouble() ?? 0;
        cubit.moveSelectedOverlay(Offset(dx, dy));
        return ServerResponse.ok({'dx': dx, 'dy': dy});

      case EditorAction.listOverlays:
        return ServerResponse.ok({
          'textOverlays': cubit.state.design.overlays
              .map(
                (o) => {
                  'id': o.id,
                  'text': o.text,
                  'position': {'x': o.position.dx, 'y': o.position.dy},
                  'fontSize': o.style.fontSize,
                  'font': o.googleFont,
                  'zIndex': o.zIndex,
                },
              )
              .toList(),
          'imageOverlays': cubit.state.design.imageOverlays
              .map(
                (o) => {
                  'id': o.id,
                  'filePath': o.filePath,
                  'position': {'x': o.position.dx, 'y': o.position.dy},
                  'width': o.width,
                  'height': o.height,
                  'zIndex': o.zIndex,
                },
              )
              .toList(),
          'iconOverlays': cubit.state.design.iconOverlays
              .map(
                (o) => {
                  'id': o.id,
                  'codePoint': o.codePoint,
                  'position': {'x': o.position.dx, 'y': o.position.dy},
                  'size': o.size,
                  'zIndex': o.zIndex,
                },
              )
              .toList(),
          'magnifierOverlays': cubit.state.design.magnifierOverlays
              .map(
                (o) => {
                  'id': o.id,
                  'position': {'x': o.position.dx, 'y': o.position.dy},
                  'width': o.width,
                  'height': o.height,
                  'zIndex': o.zIndex,
                },
              )
              .toList(),
        });

      case EditorAction.applyPreset:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id" (preset ID)');
        final preset = ScreenshotPresets.all
            .where((p) => p.id == id)
            .firstOrNull;
        if (preset == null)
          return ServerResponse.error('Preset not found: $id');
        cubit.applyPreset(preset);
        return ServerResponse.ok({'preset': id, 'name': preset.name});

      case EditorAction.undo:
        cubit.undo();
        return ServerResponse.ok();

      case EditorAction.redo:
        cubit.redo();
        return ServerResponse.ok();

      case EditorAction.setMeshGradient:
        final body = await _readBody(request);
        if (body.isEmpty || body['mesh'] == null) {
          cubit.updateMeshGradient(null);
          return ServerResponse.ok({'meshGradient': null});
        }
        final mesh = MeshGradientSettings.fromJson(
          body['mesh'] as Map<String, dynamic>,
        );
        cubit.updateMeshGradient(mesh);
        return ServerResponse.ok({
          'meshGradient': 'set',
          'pointCount': mesh.points.length,
        });

      case EditorAction.setDoodle:
        final body = await _readBody(request);
        if (body.isEmpty || body['enabled'] == false) {
          cubit.updateDoodleSettings(null);
          return ServerResponse.ok({'doodle': null});
        }
        final doodle = DoodleSettings.fromJson(body);
        cubit.updateDoodleSettings(doodle);
        return ServerResponse.ok({'doodle': body});

      case EditorAction.setGrid:
        final body = await _readBody(request);
        final grid = GridSettings.fromJson(body);
        cubit.updateGridSettings(grid);
        return ServerResponse.ok({'grid': body});

      case EditorAction.updateIcon:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id"');
        final existing = cubit.state.design.iconOverlays
            .where((o) => o.id == id)
            .firstOrNull;
        if (existing == null)
          return ServerResponse.error('Icon overlay not found: $id');
        var updated = existing;
        if (body.containsKey('x') || body.containsKey('y')) {
          updated = updated.copyWith(
            position: Offset(
              (body['x'] as num?)?.toDouble() ?? updated.position.dx,
              (body['y'] as num?)?.toDouble() ?? updated.position.dy,
            ),
          );
        }
        if (body.containsKey('size'))
          updated = updated.copyWith(size: (body['size'] as num).toDouble());
        if (body.containsKey('color')) {
          final c = parseHexColor(body['color'] as String);
          if (c != null) updated = updated.copyWith(color: c);
        }
        if (body.containsKey('rotation'))
          updated = updated.copyWith(
            rotation: (body['rotation'] as num).toDouble(),
          );
        if (body.containsKey('opacity'))
          updated = updated.copyWith(
            opacity: (body['opacity'] as num).toDouble(),
          );
        cubit.updateIconOverlay(id, updated);
        return ServerResponse.ok({'overlayId': id});

      case EditorAction.updateMagnifier:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id"');
        final existing = cubit.state.design.magnifierOverlays
            .where((o) => o.id == id)
            .firstOrNull;
        if (existing == null)
          return ServerResponse.error('Magnifier overlay not found: $id');
        var updated = existing;
        if (body.containsKey('x') || body.containsKey('y')) {
          updated = updated.copyWith(
            position: Offset(
              (body['x'] as num?)?.toDouble() ?? updated.position.dx,
              (body['y'] as num?)?.toDouble() ?? updated.position.dy,
            ),
          );
        }
        if (body.containsKey('width'))
          updated = updated.copyWith(width: (body['width'] as num).toDouble());
        if (body.containsKey('height'))
          updated = updated.copyWith(
            height: (body['height'] as num).toDouble(),
          );
        if (body.containsKey('zoomLevel'))
          updated = updated.copyWith(
            zoomLevel: (body['zoomLevel'] as num).toDouble(),
          );
        if (body.containsKey('cornerRadius'))
          updated = updated.copyWith(
            cornerRadius: (body['cornerRadius'] as num).toDouble(),
          );
        cubit.updateMagnifierOverlay(id, updated);
        return ServerResponse.ok({'overlayId': id});

      case EditorAction.copyOverlay:
        final success = cubit.copySelectedOverlay();
        return success
            ? ServerResponse.ok({'copied': cubit.state.selectedOverlayId})
            : ServerResponse.error('No overlay selected to copy');

      case EditorAction.pasteOverlay:
        final success = cubit.pasteOverlay();
        return success
            ? ServerResponse.ok({'pasted': true})
            : ServerResponse.error('No overlay in clipboard to paste');

      case EditorAction.bringForward:
        if (cubit.state.selectedOverlayId == null) {
          return ServerResponse.error('No overlay selected');
        }
        cubit.bringSelectedOverlayForward();
        return ServerResponse.ok({'overlayId': cubit.state.selectedOverlayId});

      case EditorAction.sendBackward:
        if (cubit.state.selectedOverlayId == null) {
          return ServerResponse.error('No overlay selected');
        }
        cubit.sendSelectedOverlayBackward();
        return ServerResponse.ok({'overlayId': cubit.state.selectedOverlayId});

      case EditorAction.saveDesign:
        final body = method == 'POST'
            ? await _readBody(request)
            : <String, dynamic>{};
        final name =
            body['name'] as String? ??
            'CLI Design ${DateTime.now().toIso8601String().substring(0, 16)}';
        // Capture thumbnail if callback available, otherwise use empty bytes
        Uint8List thumbnailBytes = Uint8List(0);
        if (_captureCallback != null) {
          _syncCallback?.call();
          await Future.delayed(const Duration(milliseconds: 100));
          final captured = await _captureCallback!();
          if (captured != null) thumbnailBytes = Uint8List.fromList(captured);
        }
        await cubit.saveDesign(name, thumbnailBytes);
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({
          'savedDesignId': cubit.state.savedDesignId,
          'savedDesignName': cubit.state.savedDesignName,
        });

      case EditorAction.loadDesign:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null)
          return ServerResponse.error('Missing "id" (saved design ID)');
        final savedDesign = await _persistenceService.getDesignById(id);
        if (savedDesign == null)
          return ServerResponse.error('Design not found: $id');
        cubit.loadDesignIntoEditor(savedDesign);
        return ServerResponse.ok({'id': id, 'name': savedDesign.name});

      case EditorAction.export_:
        if (_captureCallback == null) {
          return ServerResponse.error(
            'No capture callback registered. Is the editor UI visible?',
          );
        }
        final body = method == 'POST'
            ? await _readBody(request)
            : <String, dynamic>{};
        _syncCallback?.call();
        await Future.delayed(const Duration(milliseconds: 100));
        final bytes = await _captureCallback!();
        if (bytes == null) {
          return ServerResponse.error(
            'Capture failed — no image data returned',
          );
        }
        var outputPath = body['path'] as String?;
        if (outputPath == null || outputPath.isEmpty) {
          final tempDir = Directory.systemTemp;
          outputPath =
              '${tempDir.path}/appshots_export_${DateTime.now().millisecondsSinceEpoch}.png';
        }
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
        return ServerResponse.ok({
          'path': file.path,
          'sizeBytes': bytes.length,
        });

      case EditorAction.exportAll:
        if (_captureCallback == null || _multiCubit == null) {
          return ServerResponse.error(
            'Capture callback or multi cubit not registered',
          );
        }
        final body = method == 'POST'
            ? await _readBody(request)
            : <String, dynamic>{};
        final outputDir = body['dir'] as String?;
        _syncCallback?.call();
        await Future.delayed(const Duration(milliseconds: 100));

        final multiCubit = _multiCubit!;
        final editorCubit = _editorCubit!;
        final designCount = multiCubit.state.designs.length;
        final exportDir =
            outputDir ??
            '${Directory.systemTemp.path}/appshots_export_${DateTime.now().millisecondsSinceEpoch}';
        await Directory(exportDir).create(recursive: true);

        final results = <Map<String, dynamic>>[];
        final originalIndex = multiCubit.state.activeIndex;

        for (int i = 0; i < designCount; i++) {
          multiCubit.setActiveIndex(i);
          editorCubit.loadDesignForMultiMode(
            multiCubit.state.designs[i],
            imageFile: i < multiCubit.state.imageFiles.length
                ? multiCubit.state.imageFiles[i]
                : null,
          );
          await Future.delayed(const Duration(milliseconds: 300));
          final imgBytes = await _captureCallback!();
          if (imgBytes != null) {
            final filePath = '$exportDir/screenshot_${i + 1}.png';
            await File(filePath).writeAsBytes(imgBytes);
            results.add({
              'index': i,
              'path': filePath,
              'sizeBytes': imgBytes.length,
            });
          } else {
            results.add({'index': i, 'error': 'capture failed'});
          }
        }

        multiCubit.setActiveIndex(originalIndex);
        editorCubit.loadDesignForMultiMode(
          multiCubit.state.designs[originalIndex],
          imageFile: originalIndex < multiCubit.state.imageFiles.length
              ? multiCubit.state.imageFiles[originalIndex]
              : null,
        );

        return ServerResponse.ok({'dir': exportDir, 'files': results});
    }
  }
}
