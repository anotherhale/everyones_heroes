import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Persistence boundary for reviewable [StoryProposal] artifacts (SB.9).
///
/// Proposals are derived from durable [StoryBuilderSession]s. Do not store a
/// duplicate of the full session — only proposal fields + session provenance.
abstract interface class StoryProposalRepository {
  Future<void> save(StoryProposal proposal);

  Future<StoryProposal?> findById(StoryProposalId id);

  Future<bool> exists(StoryProposalId id);

  Future<void> delete(StoryProposalId id);

  /// Proposals derived from a given Story Builder session (newest first).
  Future<List<StoryProposal>> findBySessionId(StoryBuilderSessionId sessionId);
}
