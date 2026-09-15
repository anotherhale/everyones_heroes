import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:path/path.dart' as p;

/// Durable JSON transcription job store under `{root}/transcription_jobs/` (HS.11).
final class FileStoryTranscriptionJobStore
    implements StoryTranscriptionJobStore {
  FileStoryTranscriptionJobStore({required Directory rootDirectory})
      : _jobsDirectory = Directory(
          p.join(rootDirectory.path, 'transcription_jobs'),
        ) {
    if (!_jobsDirectory.existsSync()) {
      _jobsDirectory.createSync(recursive: true);
    }
    _loadFromDisk();
  }

  final Directory _jobsDirectory;
  final Map<String, StoryTranscriptionJob> _byKey = {};

  @override
  StoryTranscriptionJob? find({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
  }) {
    return _byKey[StoryTranscriptionJob.jobKey(storyId, sourceRepresentationId)];
  }

  @override
  List<StoryTranscriptionJob> findByStory(StoryId storyId) {
    return _byKey.values
        .where((job) => job.storyId == storyId)
        .toList(growable: false);
  }

  @override
  void save(StoryTranscriptionJob job) {
    _byKey[job.storageKey] = job;
    _persistJob(job);
  }

  @override
  void remove({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
  }) {
    final key = StoryTranscriptionJob.jobKey(storyId, sourceRepresentationId);
    _byKey.remove(key);
    final file = _fileForKey(key);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  void _loadFromDisk() {
    if (!_jobsDirectory.existsSync()) {
      return;
    }
    for (final entity in _jobsDirectory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      try {
        final raw = entity.readAsStringSync();
        if (raw.trim().isEmpty) {
          continue;
        }
        final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final job = _fromJson(json);
        _byKey[job.storageKey] = job;
      } catch (_) {
        // Skip corrupt job files; do not fail app startup.
      }
    }
  }

  void _persistJob(StoryTranscriptionJob job) {
    if (!_jobsDirectory.existsSync()) {
      _jobsDirectory.createSync(recursive: true);
    }
    final file = _fileForKey(job.storageKey);
    file.writeAsStringSync(jsonEncode(_toJson(job)), flush: true);
  }

  File _fileForKey(String key) {
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File(p.join(_jobsDirectory.path, '$safe.json'));
  }

  Map<String, dynamic> _toJson(StoryTranscriptionJob job) {
    return {
      'storyId': job.storyId.value,
      'sourceRepresentationId': job.sourceRepresentationId.value,
      'status': job.status.name,
      'requestId': job.requestId,
      'transcriptRepresentationId': job.transcriptRepresentationId?.value,
      'errorMessage': job.errorMessage,
      'failureKind': job.failureKind,
      'startedAt': job.startedAt?.toIso8601String(),
      'completedAt': job.completedAt?.toIso8601String(),
      'updatedAt': job.updatedAt.toIso8601String(),
      'attempt': job.attempt,
    };
  }

  StoryTranscriptionJob _fromJson(Map<String, dynamic> json) {
    return StoryTranscriptionJob(
      storyId: StoryId(json['storyId'] as String),
      sourceRepresentationId: StoryRepresentationId(
        json['sourceRepresentationId'] as String,
      ),
      status: StoryTranscriptionJobStatus.values.byName(
        json['status'] as String,
      ),
      requestId: json['requestId'] as String,
      transcriptRepresentationId: json['transcriptRepresentationId'] == null
          ? null
          : StoryRepresentationId(json['transcriptRepresentationId'] as String),
      errorMessage: json['errorMessage'] as String?,
      failureKind: json['failureKind'] as String?,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attempt: json['attempt'] as int? ?? 1,
    );
  }
}
