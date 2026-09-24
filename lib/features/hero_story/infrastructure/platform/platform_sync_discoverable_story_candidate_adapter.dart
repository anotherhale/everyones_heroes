import 'package:everyonesheroes/features/hero_story/application/dto/story_candidate_eligibility_facts_payload.dart';
import 'package:everyonesheroes/features/hero_story/application/ports/sync_discoverable_story_candidate_port.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_client.dart';

/// Infrastructure adapter: Flutter → EH Platform candidate projection ingest.
///
/// HTTP / URL / JSON details stay here. Application use cases depend only on
/// [SyncDiscoverableStoryCandidatePort].
final class PlatformSyncDiscoverableStoryCandidateAdapter
    implements SyncDiscoverableStoryCandidatePort {
  const PlatformSyncDiscoverableStoryCandidateAdapter({
    required EhPlatformClient client,
  }) : _client = client;

  final EhPlatformClient _client;

  @override
  Future<SyncDiscoverableStoryCandidateResult> sync(
    StoryCandidateEligibilityFactsPayload facts,
  ) async {
    final response = await _client.projectDiscoverableStoryCandidate(
      storyId: facts.storyId,
      facts: facts.toJson(),
    );
    return SyncDiscoverableStoryCandidateResult(
      storyId: response['storyId']?.toString() ?? facts.storyId,
      wasUpserted: response['wasUpserted'] == true,
      reason: response['reason']?.toString(),
    );
  }
}
