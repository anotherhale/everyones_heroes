import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Provider-independent Story Proposal shaping boundary (SB.10).
///
/// Shaping may organize, order, select, and tighten existing proposal material.
/// It must not invent facts or silently replace Hero-authored content.
///
/// AI-agnostic: implementations may be deterministic (SB.10) or AI-backed
/// (future SB.11). Callers must not assume network or provider availability.
///
/// Separate from [StoryAuthoringPort] (Story representation prose) and
/// [StoryBuilderUnderstandingPort] (session interpretation).
abstract interface class StoryShaperPort {
  /// Returns a new shaped [StoryProposal]. Must not mutate [proposal].
  ///
  /// Does not create a [Story], mutate a [StoryBuilderSession], or persist.
  Future<StoryProposal> shape(StoryProposal proposal);
}

/// Thrown when shaping cannot proceed safely.
final class StoryShaperException implements Exception {
  const StoryShaperException(this.message);

  final String message;

  @override
  String toString() => 'StoryShaperException: $message';
}
