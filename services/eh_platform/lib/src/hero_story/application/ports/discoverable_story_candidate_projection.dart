import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';

/// Persistence port for the discoverable Story candidate projection.
///
/// Derived data only — not authoritative Story/Hero state.
/// Transitional until Phase 7 Story platform migration owns projection refresh
/// via domain events.
abstract interface class DiscoverableStoryCandidateProjection {
  /// Upsert a projection row. Caller must already enforce eligibility.
  ///
  /// Optional [storyVisibility] / [heroVisibility] are diagnostic denormalized
  /// fields only — not authoritative Story/Hero state.
  Future<void> upsert(
    StoryCandidateRecord record, {
    String? storyVisibility,
    String? heroVisibility,
  });

  /// Remove a story from the projection (no longer eligible).
  Future<void> remove(String storyId);

  /// Whether a projection row exists for [storyId].
  Future<bool> exists(String storyId);
}
