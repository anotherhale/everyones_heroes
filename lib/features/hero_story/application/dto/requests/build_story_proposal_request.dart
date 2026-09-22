import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';

/// Request to build a reviewable [StoryProposal] from a Story Builder session.
final class BuildStoryProposalRequest {
  const BuildStoryProposalRequest({
    required this.sessionId,
    this.createdAt,
  });

  final StoryBuilderSessionId sessionId;

  /// Optional fixed timestamp for deterministic tests.
  final DateTime? createdAt;
}
