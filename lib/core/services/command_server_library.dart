part of 'command_server.dart';

// =============================================================================
// Library routes — saved designs, folders, import/export
// =============================================================================

extension _LibraryRoutes on CommandServer {
  Future<Map<String, dynamic>> handleLibrary(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final libraryAction = LibraryAction.fromActionName(action);
    if (libraryAction == null) {
      return ServerResponse.error('Unknown library action: $action');
    }

    switch (libraryAction) {
      case LibraryAction.list:
        final designs = await _persistenceService.getAllDesigns();
        return ServerResponse.ok(
          designs
              .map(
                (d) => {
                  'id': d.id,
                  'name': d.name,
                  'lastModified': d.lastModified.toIso8601String(),
                  'isMulti': d.isMulti,
                  'folderId': d.folderId,
                  'designCount': d.isMulti ? (d.multiDesigns?.length ?? 0) : 1,
                  'hasTranslation': d.translationBundle != null,
                },
              )
              .toList(),
        );

      case LibraryAction.folders:
        final folders = await _persistenceService.getAllFolders();
        return ServerResponse.ok(
          folders
              .map(
                (f) => {
                  'id': f.id,
                  'name': f.name,
                  'createdAt': f.createdAt.toIso8601String(),
                  'parentId': f.parentId,
                },
              )
              .toList(),
        );

      case LibraryAction.get:
        final body = await _readBody(request);
        final id = body['id'] as String? ?? request.uri.queryParameters['id'];
        if (id == null) return ServerResponse.error('Missing "id"');
        final design = await _persistenceService.getDesignById(id);
        if (design == null) {
          return ServerResponse.error('Design not found: $id');
        }
        return ServerResponse.ok(design.toJson());

      case LibraryAction.delete:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id"');
        await _persistenceService.deleteDesign(id);
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({'deleted': id});

      case LibraryAction.rename:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        final name = body['name'] as String?;
        if (id == null || name == null) {
          return ServerResponse.error('Missing "id" and/or "name"');
        }
        await _persistenceService.renameDesign(id, name);
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({'id': id, 'name': name});

      case LibraryAction.createFolder:
        final body = await _readBody(request);
        final name = body['name'] as String?;
        if (name == null) return ServerResponse.error('Missing "name"');
        final parentId = body['parentId'] as String?;
        final folder = await _persistenceService.createFolder(
          name,
          parentId: parentId,
        );
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({'id': folder.id, 'name': folder.name});

      case LibraryAction.deleteFolder:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id"');
        final withDesigns = body['withDesigns'] as bool? ?? false;
        if (withDesigns) {
          await _persistenceService.deleteFolderWithDesigns(id);
        } else {
          await _persistenceService.deleteFolder(id);
        }
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({'deleted': id});

      case LibraryAction.move:
        final body = await _readBody(request);
        final designId = body['designId'] as String?;
        final folderId = body['folderId'] as String?;
        if (designId == null) return ServerResponse.error('Missing "designId"');
        await _persistenceService.moveDesignToFolder(designId, folderId);
        _libraryCubit?.loadDesigns();
        return ServerResponse.ok({'designId': designId, 'folderId': folderId});

      case LibraryAction.import_:
        final body = await _readBody(request);
        final filePath = body['file'] as String?;
        if (filePath == null) {
          return ServerResponse.error('Missing "file" (path to .appshots)');
        }
        final file = File(filePath);
        if (!await file.exists()) {
          return ServerResponse.error('File not found: $filePath');
        }
        final imported = await _designFileService.parseExportFile(file);
        if (imported == null) {
          return ServerResponse.error('Failed to parse .appshots file');
        }
        return ServerResponse.ok({'name': imported.name, 'id': imported.id});

      case LibraryAction.export_:
        final body = await _readBody(request);
        final id = body['id'] as String?;
        if (id == null) return ServerResponse.error('Missing "id"');
        final design = await _persistenceService.getDesignById(id);
        if (design == null) {
          return ServerResponse.error('Design not found: $id');
        }
        final exportFile = await _designFileService.createExportFile(design);
        return ServerResponse.ok({'file': exportFile.path});

      case LibraryAction.search:
        final body = method == 'POST'
            ? await _readBody(request)
            : <String, dynamic>{};
        final query =
            body['query'] as String? ??
            request.uri.queryParameters['query'] ??
            '';
        final allDesigns = await _persistenceService.getAllDesigns();
        final filtered = allDesigns
            .where((d) => d.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return ServerResponse.ok({
          'query': query,
          'total': filtered.length,
          'designs': filtered
              .map(
                (d) => {
                  'id': d.id,
                  'name': d.name,
                  'lastModified': d.lastModified.toIso8601String(),
                  'isMulti': d.isMulti,
                  'folderId': d.folderId,
                },
              )
              .toList(),
        });
    }
  }
}
