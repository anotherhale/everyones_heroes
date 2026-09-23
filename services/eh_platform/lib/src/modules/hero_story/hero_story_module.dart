/// Hero & Story module boundary (PF-ADR-002 / J.2 Slice 3).
///
/// Owns: Hero, Story, representations, builder, catalog (when migrated).
/// Does not own: BehavioralEvidence, BehaviorPatterns, DiscoveryProfile,
/// NarrativeTheme vocabulary (Discovery owns the catalog).
///
/// J.2 Slice 3 provides a **transitional** seeded Story candidate source so
/// Experience can exercise HS.8 adaptive Story selection through
/// [DiscoverableStoryCandidatePort] without migrating full Hero & Story
/// persistence to the platform.
///
/// Full Story aggregate / Postgres authority remains deferred (Phase 7).
library;

import 'package:eh_platform/src/experience/application/ports/discoverable_story_candidate_port.dart';
import 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/application/services/seeded_discoverable_story_candidate_adapter.dart';
import 'package:eh_platform/src/hero_story/infrastructure/seeded_story_candidate_catalog.dart';

export 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
export 'package:eh_platform/src/hero_story/application/services/deterministic_story_relevance_ranker.dart';
export 'package:eh_platform/src/hero_story/application/services/seeded_discoverable_story_candidate_adapter.dart';
export 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';
export 'package:eh_platform/src/hero_story/infrastructure/seeded_story_candidate_catalog.dart';

final class HeroStoryModule {
  const HeroStoryModule();

  static const String name = 'hero_story';

  /// Compose transitional Story candidate capabilities for Experience.
  ///
  /// Defaults to [SeededStoryCandidateCatalog.architecturalSeed].
  /// Pass [SeededStoryCandidateCatalog.empty] (or a custom source) in tests
  /// to verify fail-closed behavior.
  static HeroStoryComponents compose({
    StoryCandidateSource? candidateSource,
  }) {
    final source =
        candidateSource ?? SeededStoryCandidateCatalog.architecturalSeed();
    final port = SeededDiscoverableStoryCandidateAdapter(
      candidateSource: source,
    );
    return HeroStoryComponents(
      candidateSource: source,
      storyCandidatePort: port,
    );
  }
}

/// Wired Hero & Story capabilities for composition / tests.
final class HeroStoryComponents {
  const HeroStoryComponents({
    required this.candidateSource,
    required this.storyCandidatePort,
  });

  /// Replaceable candidate store (seed today).
  final StoryCandidateSource candidateSource;

  /// Experience-facing seam — do not bypass from API/UI.
  final DiscoverableStoryCandidatePort storyCandidatePort;
}
