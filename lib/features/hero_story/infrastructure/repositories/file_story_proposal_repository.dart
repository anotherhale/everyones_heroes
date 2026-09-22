import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_proposal_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [StoryProposalRepository] with lazy in-memory cache (SB.9).
///
/// Files under `{root}/story_proposals/{id}.json`.
/// Mirrors [FileStoryBuilderSessionRepository] conventions.
final class FileStoryProposalRepository implements StoryProposalRepository {
  FileStoryProposalRepository({required Directory rootDirectory})
    : _proposalsDirectory = Directory(
        p.join(rootDirectory.path, 'story_proposals'),
      );

  final Directory _proposalsDirectory;
  final Map<StoryProposalId, StoryProposal> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _proposalsDirectory.exists()) {
      await _proposalsDirectory.create(recursive: true);
    }

    await for (final entity in _proposalsDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      final raw = await entity.readAsString();
      late final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException catch (e) {
        throw FormatException(
          'Corrupt Story Proposal file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt Story Proposal file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final proposal = StoryProposalSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[proposal.id] = proposal;
    }

    _loaded = true;
  }

  File _fileFor(StoryProposalId id) =>
      File(p.join(_proposalsDirectory.path, '${id.value}.json'));

  @override
  Future<void> save(StoryProposal proposal) async {
    await _ensureLoaded();
    if (!await _proposalsDirectory.exists()) {
      await _proposalsDirectory.create(recursive: true);
    }
    final file = _fileFor(proposal.id);
    await file.writeAsString(
      jsonEncode(StoryProposalSnapshotMapper.toJson(proposal)),
      flush: true,
    );
    _cache[proposal.id] = proposal;
  }

  @override
  Future<StoryProposal?> findById(StoryProposalId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<bool> exists(StoryProposalId id) async {
    await _ensureLoaded();
    return _cache.containsKey(id);
  }

  @override
  Future<void> delete(StoryProposalId id) async {
    await _ensureLoaded();
    _cache.remove(id);
    final file = _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<StoryProposal>> findBySessionId(
    StoryBuilderSessionId sessionId,
  ) async {
    await _ensureLoaded();
    final matches = _cache.values
        .where((p) => p.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(matches);
  }
}
