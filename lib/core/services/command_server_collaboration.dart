part of 'command_server.dart';

extension _CollaborationRoutes on CommandServer {
  Future<Map<String, dynamic>> handleCollaboration(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final collaborationAction = CollaborationAction.fromActionName(action);
    if (collaborationAction == null) {
      return ServerResponse.error('Unknown collaboration action: $action');
    }
    if (!ICloudCollaborationService.isSupported) {
      return ServerResponse.error(
        'iCloud collaboration is only available on iOS and macOS',
      );
    }

    final body = await _readBody(request);
    switch (collaborationAction) {
      case CollaborationAction.share:
        final filePath = body['file'] as String?;
        if (filePath == null || filePath.isEmpty) {
          return ServerResponse.error('Missing "file"');
        }
        final file = File(filePath);
        if (!await file.exists()) {
          return ServerResponse.error('File not found: $filePath');
        }
        final fileName =
            body['fileName'] as String? ?? file.uri.pathSegments.last;
        final cloudPath = await ICloudCollaborationService.shareDocument(
          localPath: file.absolute.path,
          fileName: fileName,
        );
        if (cloudPath == null) {
          return ServerResponse.error('iCloud collaboration is unavailable');
        }
        return ServerResponse.ok({'cloudPath': cloudPath});
      case CollaborationAction.save:
        final localPath = body['localPath'] as String?;
        final workingPath = body['workingPath'] as String?;
        if (localPath == null || workingPath == null) {
          return ServerResponse.error(
            'Missing "localPath" and/or "workingPath"',
          );
        }
        final saved = await ICloudCollaborationService.saveOpenedDocument(
          localPath: localPath,
          workingPath: workingPath,
        );
        return ServerResponse.ok({'saved': saved});
    }
  }
}
