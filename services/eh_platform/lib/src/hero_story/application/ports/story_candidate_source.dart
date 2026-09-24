import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';

/// Internal Hero & Story candidate source behind the Experience port.
///
/// Experience depends only on [DiscoverableStoryCandidatePort]. This source
/// is the replaceable HS-side store (live Postgres projection in production;
/// in-memory / seed fixtures for tests).
abstract interface class StoryCandidateSource {
  /// All discoverable candidates (already eligibility-gated + catalog-theme
  /// validated). Does not read Reflection, Journey, or Flutter state.
  Future<List<StoryCandidateRecord>> listCandidates();
}
