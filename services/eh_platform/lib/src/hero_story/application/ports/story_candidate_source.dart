import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';

/// Internal Hero & Story candidate source behind the Experience port.
///
/// Experience depends only on [DiscoverableStoryCandidatePort]. This source
/// is the replaceable HS-side store (seed today; Postgres Story catalog later).
abstract interface class StoryCandidateSource {
  /// All discoverable candidates (already catalog-theme validated).
  Future<List<StoryCandidateRecord>> listCandidates();
}
