part of 'command_server.dart';

// =============================================================================
// Multi-design routes — manage multiple screenshots in a single project
// =============================================================================

extension _MultiRoutes on CommandServer {
  Future<Map<String, dynamic>> handleMulti(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final multiAction = MultiAction.fromActionName(action);
    if (multiAction == null) {
      return ServerResponse.error('Unknown multi action: $action');
    }

    // ── open: navigate to multi-screenshot editor ──────────────────────────
    // This must be handled before the cubit null-check because the purpose
    // of this command is to open the page when it doesn't exist yet.
    if (multiAction == MultiAction.open) {
      final body = method == 'POST' ? await _readBody(request) : <String, dynamic>{};
      final displayType = body['displayType'] as String? ?? 'APP_IPHONE_67';

      if (_navigateToMultiCallback == null) {
        return ServerResponse.error(
          'Navigation callback not registered. '
          'Make sure the app is on the library/studio page.',
        );
      }

      // Trigger navigation on the main thread
      await _navigateToMultiCallback!(displayType);

      // Poll until the multi cubit is registered (page mounted and ready)
      const maxWait = Duration(seconds: 10);
      const pollInterval = Duration(milliseconds: 200);
      final deadline = DateTime.now().add(maxWait);
      while (_multiCubit == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(pollInterval);
      }

      if (_multiCubit == null) {
        return ServerResponse.error('Timed out waiting for multi-editor to initialize');
      }

      return ServerResponse.ok({
        'displayType': displayType,
        'designCount': _multiCubit!.state.designs.length,
      });
    }

    // ── All other actions require the cubit ────────────────────────────────
    if (_multiCubit == null) {
      return ServerResponse.notReady('multi-editor');
    }

    final cubit = _multiCubit!;

    switch (multiAction) {
      case MultiAction.open:
        throw StateError('unreachable');  // handled above
      case MultiAction.state:
        return ServerResponse.ok({
          'activeIndex': cubit.state.activeIndex,
          'designCount': cubit.state.designs.length,
          'canAddMore': cubit.state.canAddMore,
          'savedDesignId': cubit.state.savedDesignId,
          'savedDesignName': cubit.state.savedDesignName,
          'designs': cubit.state.designs.asMap().entries.map((e) => {
            'index': e.key,
            'displayType': e.value.displayType,
            'backgroundColor': colorToHex(e.value.backgroundColor),
            'deviceFrame': e.value.deviceFrame?.name,
            'overlayCount': e.value.overlays.length,
            'hasImage': e.key < cubit.state.imageFiles.length && cubit.state.imageFiles[e.key] != null,
          }).toList(),
        });

      case MultiAction.switchDesign:
        final body = await _readBody(request);
        final index = body['index'] as int?;
        if (index == null) return ServerResponse.error('Missing "index" (int)');
        if (index < 0 || index >= cubit.state.designs.length) {
          return ServerResponse.error('Index out of range (0-${cubit.state.designs.length - 1})');
        }
        cubit.setActiveIndex(index);
        return ServerResponse.ok({'activeIndex': index});

      case MultiAction.addDesign:
        if (!cubit.state.canAddMore) {
          return ServerResponse.error('Maximum design limit reached (10)');
        }
        cubit.addDesign();
        return ServerResponse.ok({'designCount': cubit.state.designs.length});

      case MultiAction.removeDesign:
        final body = await _readBody(request);
        final index = body['index'] as int? ?? cubit.state.activeIndex;
        cubit.removeDesign(index);
        return ServerResponse.ok({'designCount': cubit.state.designs.length});

      case MultiAction.duplicateDesign:
        final body = await _readBody(request);
        final index = body['index'] as int? ?? cubit.state.activeIndex;
        cubit.duplicateDesign(index);
        return ServerResponse.ok({'designCount': cubit.state.designs.length});

      case MultiAction.reorder:
        final body = await _readBody(request);
        final from = body['from'] as int?;
        final to = body['to'] as int?;
        if (from == null || to == null) return ServerResponse.error('Missing "from" and "to" (int)');
        cubit.reorderDesigns(from, to);
        return ServerResponse.ok();

      case MultiAction.applyPreset:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id" (preset ID)');
        final preset = ScreenshotPresets.all.where((p) => p.id == id).firstOrNull;
        if (preset == null) return ServerResponse.error('Preset not found: $id');
        cubit.applyPreset(preset);
        return ServerResponse.ok({'preset': id, 'designCount': cubit.state.designs.length});

      case MultiAction.batch:
        if (_editorCubit == null) {
          return ServerResponse.notReady('editor for batch operations');
        }
        final body = await _readBody(request);
        final batchAction = body['action'] as String?;
        if (batchAction == null) return ServerResponse.error('Missing "action"');
        final originalIndex = cubit.state.activeIndex;
        final results = <Map<String, dynamic>>[];
        for (int i = 0; i < cubit.state.designs.length; i++) {
          cubit.setActiveIndex(i);
          final design = cubit.state.designs[i];
          switch (batchAction) {
            case 'set-background':
              final colorStr = body['color'] as String?;
              if (colorStr != null) {
                final color = parseHexColor(colorStr);
                if (color != null) {
                  cubit.updateDesignForSlot(i, design.copyWith(backgroundColor: color));
                  results.add({'index': i, 'ok': true});
                }
              }
            case 'set-padding':
              final padding = (body['padding'] as num?)?.toDouble();
              if (padding != null) {
                cubit.updateDesignForSlot(i, design.copyWith(padding: padding));
                results.add({'index': i, 'ok': true});
              }
            case 'set-corner-radius':
              final radius = (body['radius'] as num?)?.toDouble();
              if (radius != null) {
                cubit.updateDesignForSlot(i, design.copyWith(cornerRadius: radius));
                results.add({'index': i, 'ok': true});
              }
            default:
              results.add({'index': i, 'ok': false, 'error': 'Unsupported batch action: $batchAction'});
          }
        }
        cubit.setActiveIndex(originalIndex);
        return ServerResponse.ok({'results': results});

      case MultiAction.setImage:
        final body = await _readBody(request);
        final index = body['index'] as int? ?? cubit.state.activeIndex;
        final filePath = body['file'] as String?;
        final base64Data = body['data'] as String?;
        File? imageFile;
        if (base64Data != null) {
          final bytes = base64Decode(base64Data);
          final tempDir = Directory.systemTemp;
          final fileName = 'cli_multi_${index}_${DateTime.now().millisecondsSinceEpoch}.png';
          imageFile = File('${tempDir.path}/$fileName');
          await imageFile.writeAsBytes(bytes);
        } else if (filePath != null) {
          imageFile = File(filePath);
          if (!await imageFile.exists()) return ServerResponse.error('File not found: $filePath');
        } else {
          return ServerResponse.error('Missing "file" (path) or "data" (base64)');
        }
        cubit.setActiveIndex(index);
        cubit.syncActiveImage(imageFile);
        return ServerResponse.ok({'index': index, 'file': imageFile.path});

      case MultiAction.saveDesign:
        final body = method == 'POST' ? await _readBody(request) : <String, dynamic>{};
        final name = body['name'] as String? ?? 'Multi Design ${DateTime.now().toIso8601String().substring(0, 16)}';
        // Capture thumbnail if callback available
        Uint8List thumbnailBytes = Uint8List(0);
        if (_captureCallback != null) {
          _syncCallback?.call();
          await Future.delayed(const Duration(milliseconds: 100));
          final captured = await _captureCallback!();
          if (captured != null) thumbnailBytes = Uint8List.fromList(captured);
        }
        final override = body['override'] == true;
        await cubit.saveDesign(
          name, 
          thumbnailBytes, 
          override: override,
          translationBundle: _translationCubit?.state.bundle,
          ascAppConfig: cubit.state.ascAppConfig,
        );
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({
          'savedDesignId': cubit.state.savedDesignId,
          'savedDesignName': cubit.state.savedDesignName,
        });
    }
  }
}
