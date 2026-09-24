/// Hero & Story module boundary (PF-ADR-002 / J.2 Slice 4).
///
/// Owns: Hero, Story, representations, builder, catalog (when migrated);
/// adaptive Story candidate eligibility, projection, retrieval, and relevance.
/// Does not own: BehavioralEvidence, BehaviorPatterns, DiscoveryProfile,
/// NarrativeTheme vocabulary (Discovery owns the catalog).
///
/// J.2 Slice 4 wires a **live** PostgreSQL discoverable-candidate projection
/// behind [DiscoverableStoryCandidatePort]. The Slice 3 architectural seed is
/// retained only as an explicit test fixture — never production default.
///
/// Full Story aggregate / Postgres authority remains deferred (Phase 7).
library;

import 'package:eh_platform/src/experience/application/ports/discoverable_story_candidate_port.dart';
import 'package:eh_platform/src/hero_story/application/ports/discoverable_story_candidate_projection.dart';
import 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/application/services/discoverable_story_candidate_adapter.dart';
import 'package:eh_platform/src/hero_story/application/use_cases/project_discoverable_story_candidate_use_case.dart';
import 'package:eh_platform/src/hero_story/infrastructure/postgres_story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/infrastructure/seeded_story_candidate_catalog.dart';
import 'package:eh_platform/src/persistence/database.dart';

export 'package:eh_platform/src/hero_story/application/ports/discoverable_story_candidate_projection.dart';
export 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
export 'package:eh_platform/src/hero_story/application/services/deterministic_story_relevance_ranker.dart';
export 'package:eh_platform/src/hero_story/application/services/discoverable_story_candidate_adapter.dart';
export 'package:eh_platform/src/hero_story/application/use_cases/project_discoverable_story_candidate_use_case.dart';
export 'package:eh_platform/src/hero_story/domain/models/story_candidate_eligibility_facts.dart';
export 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';
export 'package:eh_platform/src/hero_story/domain/services/adaptive_story_candidate_eligibility_policy.dart';
export 'package:eh_platform/src/hero_story/infrastructure/postgres_story_candidate_source.dart';
export 'package:eh_platform/src/hero_story/infrastructure/seeded_story_candidate_catalog.dart';

final class HeroStoryModule {
  const HeroStoryModule();

  static const String name = 'hero_story';

  /// Production composition: live PostgreSQL candidate projection.
  ///
  /// Does **not** default to [SeededStoryCandidateCatalog.architecturalSeed].
  static HeroStoryComponents composePostgres({
    required PlatformDatabase database,
  }) {
    final source = PostgresStoryCandidateSource(database);
    return _compose(
      candidateSource: source,
      projection: source,
    );
  }

  /// Test / local composition with an explicit [StoryCandidateSource].
  ///
  /// When [candidateSource] is omitted, uses an empty in-memory projection
  /// (fail-closed) — **not** the Slice 3 architectural seed.
  ///
  /// Pass [SeededStoryCandidateCatalog.architecturalSeed] explicitly only for
  /// isolated fixture tests.
  static HeroStoryComponents compose({
    StoryCandidateSource? candidateSource,
    DiscoverableStoryCandidateProjection? projection,
  }) {
    if (candidateSource != null) {
      return _compose(
        candidateSource: candidateSource,
        projection: projection,
      );
    }

    final memory = InMemoryDiscoverableStoryCandidateProjection();
    return _compose(
      candidateSource: memory,
      projection: memory,
    );
  }

  static HeroStoryComponents _compose({
    required StoryCandidateSource candidateSource,
    DiscoverableStoryCandidateProjection? projection,
  }) {
    final port = DiscoverableStoryCandidateAdapter(
      candidateSource: candidateSource,
    );
    final effectiveProjection = projection;
    final projectUseCase = effectiveProjection == null
        ? null
        : ProjectDiscoverableStoryCandidateUseCase(
            projection: effectiveProjection,
          );
    return HeroStoryComponents(
      candidateSource: candidateSource,
      storyCandidatePort: port,
      projection: effectiveProjection,
      projectCandidate: projectUseCase,
    );
  }
}

/// Wired Hero & Story capabilities for composition / tests.
final class HeroStoryComponents {
  const HeroStoryComponents({
    required this.candidateSource,
    required this.storyCandidatePort,
    this.projection,
    this.projectCandidate,
  });

  /// Replaceable candidate store (live Postgres in production).
  final StoryCandidateSource candidateSource;

  /// Experience-facing seam — do not bypass from API/UI.
  final DiscoverableStoryCandidatePort storyCandidatePort;

  /// Projection writer when available (live / in-memory). Null for seed-only.
  final DiscoverableStoryCandidateProjection? projection;

  /// Transitional upsert/invalidate use case. Null when no projection writer.
  final ProjectDiscoverableStoryCandidateUseCase? projectCandidate;
}
