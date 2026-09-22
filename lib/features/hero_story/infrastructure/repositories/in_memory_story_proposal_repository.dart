import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

class InMemoryStoryProposalRepository implements StoryProposalRepository {
  final Map<StoryProposalId, StoryProposal> _store = {};

  @override
  Future<void> save(StoryProposal proposal) async {
    _store[proposal.id] = proposal;
  }

  @override
  Future<StoryProposal?> findById(StoryProposalId id) async {
    return _store[id];
  }

  @override
  Future<bool> exists(StoryProposalId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(StoryProposalId id) async {
    _store.remove(id);
  }

  @override
  Future<List<StoryProposal>> findBySessionId(
    StoryBuilderSessionId sessionId,
  ) async {
    final matches = _store.values
        .where((p) => p.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(matches);
  }
}
