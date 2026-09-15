import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/transcribe_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// Durable [TranscriptionCompletionStore] using sync file IO (HS.11).
///
/// Mirrors [FileCaptureCompletionStore]: embeds a Story snapshot so idempotent
/// replay works after process restart without async repository access.
final class FileTranscriptionCompletionStore
    implements TranscriptionCompletionStore {
  FileTranscriptionCompletionStore({
    required Directory rootDirectory,
    required this._storyRepository,
  }) : _indexFile = File(
         p.join(rootDirectory.path, 'transcription_completions.json'),
       ) {
    _loadFromDisk();
  }

  /// Retained for wiring symmetry with capture completion store.
  // ignore: unused_field
  final StoryRepository _storyRepository;
  final File _indexFile;
  final Map<String, TranscribeStoryResponse> _byRequest = {};

  @override
  TranscribeStoryResponse? find(String requestId) => _byRequest[requestId];

  @override
  void save(String requestId, TranscribeStoryResponse response) {
    _byRequest[requestId] = response;
    _persistIndex();
  }

  @override
  void remove(String requestId) {
    _byRequest.remove(requestId);
    _persistIndex();
  }

  void _loadFromDisk() {
    if (!_indexFile.existsSync()) {
      return;
    }

    final raw = _indexFile.readAsStringSync();
    if (raw.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return;
    }

    for (final entry in decoded.entries) {
      final requestId = entry.key as String;
      final value = Map<String, dynamic>.from(entry.value as Map);
      final storyJson = Map<String, dynamic>.from(value['story'] as Map);
      final story = StorySnapshotMapper.fromJson(storyJson);
      final mediaUri = value['mediaUri'] as String?;

      _byRequest[requestId] = TranscribeStoryResponse(
        story: story,
        storyId: StoryId(value['storyId'] as String),
        transcriptRepresentationId: StoryRepresentationId(
          value['transcriptRepresentationId'] as String,
        ),
        mediaReference:
            mediaUri == null ? null : MediaReference(mediaUri),
        idempotentReplay: value['idempotentReplay'] as bool? ?? false,
      );
    }
  }

  void _persistIndex() {
    final parent = _indexFile.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    final payload = <String, dynamic>{};
    for (final entry in _byRequest.entries) {
      final response = entry.value;
      payload[entry.key] = {
        'storyId': response.storyId.value,
        'transcriptRepresentationId':
            response.transcriptRepresentationId.value,
        'mediaUri': response.mediaReference?.uri,
        'idempotentReplay': response.idempotentReplay,
        'story': StorySnapshotMapper.toJson(response.story),
      };
    }

    _indexFile.writeAsStringSync(jsonEncode(payload), flush: true);
  }
}
