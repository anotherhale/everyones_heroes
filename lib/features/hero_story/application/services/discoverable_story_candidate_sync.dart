import 'package:everyonesheroes/features/hero_story/application/mappers/story_candidate_eligibility_facts_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/ports/sync_discoverable_story_candidate_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';

/// Application collaboration: soft-fail candidate projection sync after
/// Story/Hero mutations (J.2 Slice 5).
///
/// Story publish/archive remains authoritative and is never rolled back when
/// projection sync fails. Errors are returned for observability; callers must
/// not treat sync failure as Story mutation failure.
final class DiscoverableStoryCandidateSync {
  DiscoverableStoryCandidateSync({
    required SyncDiscoverableStoryCandidatePort port,
    StoryCandidateEligibilityFactsMapper mapper =
        const StoryCandidateEligibilityFactsMapper(),
  })  : _port = port,
        _mapper = mapper;

  final SyncDiscoverableStoryCandidatePort _port;
  final StoryCandidateEligibilityFactsMapper _mapper;

  /// Best-effort sync. Never throws.
  Future<DiscoverableStoryCandidateSyncOutcome> sync({
    required Story story,
    required Hero hero,
  }) async {
    final facts = _mapper.fromStoryAndHero(story: story, hero: hero);
    try {
      final result = await _port.sync(facts);
      return DiscoverableStoryCandidateSyncOutcome.ok(result);
    } catch (e) {
      return DiscoverableStoryCandidateSyncOutcome.failed(
        storyId: facts.storyId,
        error: e,
      );
    }
  }
}

final class DiscoverableStoryCandidateSyncOutcome {
  const DiscoverableStoryCandidateSyncOutcome._({
    required this.storyId,
    required this.succeeded,
    this.result,
    this.error,
  });

  factory DiscoverableStoryCandidateSyncOutcome.ok(
    SyncDiscoverableStoryCandidateResult result,
  ) {
    return DiscoverableStoryCandidateSyncOutcome._(
      storyId: result.storyId,
      succeeded: true,
      result: result,
    );
  }

  factory DiscoverableStoryCandidateSyncOutcome.failed({
    required String storyId,
    required Object error,
  }) {
    return DiscoverableStoryCandidateSyncOutcome._(
      storyId: storyId,
      succeeded: false,
      error: error,
    );
  }

  final String storyId;
  final bool succeeded;
  final SyncDiscoverableStoryCandidateResult? result;
  final Object? error;
}
