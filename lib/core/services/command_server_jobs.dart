part of 'command_server.dart';

enum _CommandJobStatus { queued, running, completed, failed }

class _CommandJob {
  final String id;
  final String type;
  final DateTime createdAt;
  DateTime updatedAt;
  _CommandJobStatus status;
  Map<String, dynamic>? progress;
  Map<String, dynamic>? result;
  String? error;

  _CommandJob({required this.id, required this.type})
    : createdAt = DateTime.now(),
      updatedAt = DateTime.now(),
      status = _CommandJobStatus.queued;

  void setProgress(Map<String, dynamic> value) {
    progress = value;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (progress != null) 'progress': progress,
    if (result != null) 'result': result,
    if (error != null) 'error': error,
  };
}

extension _JobRoutes on CommandServer {
  _CommandJob _startJob(
    String type,
    Future<Map<String, dynamic>> Function(_CommandJob job) operation,
  ) {
    final id =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${Random.secure().nextInt(0xFFFFFF).toRadixString(36)}';
    final job = _CommandJob(id: id, type: type);
    _jobs[id] = job;

    if (_jobs.length > 100) {
      final completed =
          _jobs.values
              .where(
                (item) =>
                    item.status == _CommandJobStatus.completed ||
                    item.status == _CommandJobStatus.failed,
              )
              .toList()
            ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      if (completed.isNotEmpty) _jobs.remove(completed.first.id);
    }

    Future<void>(() async {
      job
        ..status = _CommandJobStatus.running
        ..updatedAt = DateTime.now();
      try {
        job.result = await operation(job);
        job.status = _CommandJobStatus.completed;
      } catch (error, stackTrace) {
        job
          ..error = error.toString()
          ..status = _CommandJobStatus.failed;
        AppLogger.error(
          'Command job failed: $type',
          tag: CommandServer._tag,
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        job.updatedAt = DateTime.now();
      }
    });
    return job;
  }

  Future<Map<String, dynamic>> handleJobs(
    String action,
    String method,
    HttpRequest request,
  ) async {
    final jobAction = JobAction.fromActionName(action);
    if (jobAction == null) {
      return ServerResponse.error('Unknown job action: $action');
    }

    switch (jobAction) {
      case JobAction.list:
        final jobs = _jobs.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ServerResponse.ok(jobs.map((job) => job.toJson()).toList());
      case JobAction.status:
        final body = method == 'POST'
            ? await _readBody(request)
            : const <String, dynamic>{};
        final id = body['id'] as String? ?? request.uri.queryParameters['id'];
        if (id == null || id.isEmpty) {
          return ServerResponse.error('Missing "id"');
        }
        final job = _jobs[id];
        if (job == null) return ServerResponse.error('Job not found: $id');
        return ServerResponse.ok(job.toJson());
    }
  }
}
