import 'package:eh_platform/src/hero_story/application/ports/discoverable_story_candidate_projection.dart';
import 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_eligibility_facts.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';
import 'package:eh_platform/src/hero_story/domain/services/adaptive_story_candidate_eligibility_policy.dart';

/// Transitional sync: authoritative Story/Hero facts → candidate projection.
///
/// **Not** a general Story synchronization framework.
/// **Not** a second Story aggregate.
///
/// Flow:
/// 1. Accept eligibility facts (exported from Flutter Story/Hero today)
/// 2. Evaluate [AdaptiveStoryCandidateEligibilityPolicy]
/// 3. Upsert [StoryCandidateRecord] when eligible
/// 4. Remove projection membership when ineligible
///
/// Phase 7 replaces this with platform Story/Hero authority + event reactors
/// (`StoryPublished`, visibility/archive changes, etc.).
final class ProjectDiscoverableStoryCandidateUseCase {
  const ProjectDiscoverableStoryCandidateUseCase({
    required DiscoverableStoryCandidateProjection projection,
  }) : _projection = projection;

  final DiscoverableStoryCandidateProjection _projection;

  /// Project or invalidate a candidate based on current eligibility facts.
  Future<ProjectDiscoverableStoryCandidateResult> execute(
    StoryCandidateEligibilityFacts facts,
  ) async {
    final evaluation =
        AdaptiveStoryCandidateEligibilityPolicy.evaluate(facts);

    if (!evaluation.isEligible) {
      await _projection.remove(facts.storyId);
      return ProjectDiscoverableStoryCandidateResult.removed(
        storyId: facts.storyId,
        reason: evaluation.reason ?? 'ineligible',
      );
    }

    final record = StoryCandidateRecord(
      storyId: facts.storyId,
      heroId: facts.heroId,
      title: facts.title,
      themeIds: evaluation.catalogThemeIds,
      updatedAt: facts.updatedAt.toUtc(),
    );
    await _projection.upsert(record);
    return ProjectDiscoverableStoryCandidateResult.upserted(
      storyId: facts.storyId,
      record: record,
    );
  }
}

/// Outcome of a transitional candidate projection sync.
final class ProjectDiscoverableStoryCandidateResult {
  const ProjectDiscoverableStoryCandidateResult._({
    required this.storyId,
    required this.wasUpserted,
    this.reason,
    this.record,
  });

  factory ProjectDiscoverableStoryCandidateResult.upserted({
    required String storyId,
    required StoryCandidateRecord record,
  }) {
    return ProjectDiscoverableStoryCandidateResult._(
      storyId: storyId,
      wasUpserted: true,
      record: record,
    );
  }

  factory ProjectDiscoverableStoryCandidateResult.removed({
    required String storyId,
    required String reason,
  }) {
    return ProjectDiscoverableStoryCandidateResult._(
      storyId: storyId,
      wasUpserted: false,
      reason: reason,
    );
  }

  final String storyId;
  final bool wasUpserted;
  final String? reason;
  final StoryCandidateRecord? record;
}

/// Combined in-memory projection store + [StoryCandidateSource] for tests.
final class InMemoryDiscoverableStoryCandidateProjection
    implements DiscoverableStoryCandidateProjection, StoryCandidateSource {
  final Map<String, StoryCandidateRecord> _byId = {};

  List<StoryCandidateRecord> get records =>
      List.unmodifiable(_byId.values.toList());

  @override
  Future<void> upsert(StoryCandidateRecord record) async {
    _byId[record.storyId] = record;
  }

  @override
  Future<void> remove(String storyId) async {
    _byId.remove(storyId);
  }

  @override
  Future<bool> exists(String storyId) async => _byId.containsKey(storyId);

  @override
  Future<List<StoryCandidateRecord>> listCandidates() async {
    final list = _byId.values.toList()
      ..sort((a, b) {
        final updated = b.updatedAt.compareTo(a.updatedAt);
        if (updated != 0) return updated;
        return a.storyId.compareTo(b.storyId);
      });
    return List.unmodifiable(list);
  }

  void clear() => _byId.clear();
}
