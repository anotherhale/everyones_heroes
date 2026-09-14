import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// Durable [CaptureCompletionStore] using sync file IO (HS.9).
///
/// Embeds a full [Story] snapshot in the index so [find] works after process
/// restart without async repository access. [storyRepository] is retained for
/// constructor symmetry with the HS.9 wiring plan.
final class FileCaptureCompletionStore implements CaptureCompletionStore {
  FileCaptureCompletionStore({
    required Directory rootDirectory,
    required this._storyRepository,
  }) : _indexFile = File(
         p.join(rootDirectory.path, 'capture_completions.json'),
       ) {
    _loadFromDisk();
  }

  /// Retained for HS.9 wiring symmetry; hydration uses embedded story snapshots.
  // ignore: unused_field
  final StoryRepository _storyRepository;
  final File _indexFile;
  final Map<String, CompleteStoryCaptureResponse> _bySession = {};

  @override
  CompleteStoryCaptureResponse? find(String sessionId) => _bySession[sessionId];

  @override
  void save(String sessionId, CompleteStoryCaptureResponse response) {
    _bySession[sessionId] = response;
    _persistIndex();
  }

  @override
  void remove(String sessionId) {
    _bySession.remove(sessionId);
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
      final sessionId = entry.key as String;
      final value = Map<String, dynamic>.from(entry.value as Map);
      final storyJson = Map<String, dynamic>.from(value['story'] as Map);
      final story = StorySnapshotMapper.fromJson(storyJson);

      _bySession[sessionId] = CompleteStoryCaptureResponse(
        story: story,
        storyId: StoryId(value['storyId'] as String),
        representationId: StoryRepresentationId(
          value['representationId'] as String,
        ),
        mediaReference: MediaReference(value['mediaUri'] as String),
        createdStory: value['createdStory'] as bool? ?? false,
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
    for (final entry in _bySession.entries) {
      final response = entry.value;
      payload[entry.key] = {
        'storyId': response.storyId.value,
        'representationId': response.representationId.value,
        'mediaUri': response.mediaReference.uri,
        'createdStory': response.createdStory,
        'idempotentReplay': response.idempotentReplay,
        'story': StorySnapshotMapper.toJson(response.story),
      };
    }

    _indexFile.writeAsStringSync(jsonEncode(payload), flush: true);
  }
}
