import 'package:everyonesheroes/features/hero_story/application/dto/story_candidate_eligibility_facts_payload.dart';

/// Application port: request platform discoverable-candidate projection sync.
///
/// Transitional dual-stack seam (J.2 Slice 5). Flutter Story remains
/// authoritative; this port only forwards eligibility facts to EH Platform.
///
/// Implementations must not live in the domain layer.
abstract interface class SyncDiscoverableStoryCandidatePort {
  /// Sync projection membership from current eligibility facts.
  ///
  /// Returns whether a candidate row was upserted (`wasUpserted`) or removed
  /// / left absent when ineligible.
  Future<SyncDiscoverableStoryCandidateResult> sync(
    StoryCandidateEligibilityFactsPayload facts,
  );
}

final class SyncDiscoverableStoryCandidateResult {
  const SyncDiscoverableStoryCandidateResult({
    required this.storyId,
    required this.wasUpserted,
    this.reason,
  });

  final String storyId;
  final bool wasUpserted;
  final String? reason;
}

/// No-op when platform authority is not configured (local/offline).
final class NoOpSyncDiscoverableStoryCandidatePort
    implements SyncDiscoverableStoryCandidatePort {
  const NoOpSyncDiscoverableStoryCandidatePort();

  @override
  Future<SyncDiscoverableStoryCandidateResult> sync(
    StoryCandidateEligibilityFactsPayload facts,
  ) async {
    return SyncDiscoverableStoryCandidateResult(
      storyId: facts.storyId,
      wasUpserted: false,
      reason: 'platform_not_configured',
    );
  }
}
