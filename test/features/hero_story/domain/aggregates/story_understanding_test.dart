import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  final english = LanguageCode('en');
  final analyzedAt = DateTime.utc(2026, 9, 12);

  UnderstandingProvenance buildProvenance({
    required List<StoryRepresentationId> sourceRepresentationIds,
    String providerLabel = 'in_memory',
    String processingVersion = 'hs4-v1',
  }) {
    return UnderstandingProvenance(
      sourceRepresentationIds: sourceRepresentationIds,
      analyzedAt: analyzedAt,
      providerLabel: providerLabel,
      processingVersion: processingVersion,
    );
  }

  StoryUnderstanding createProposed({
    StoryUnderstandingId? id,
    StoryId? storyId,
    List<StoryRepresentationId>? sourceRepresentationIds,
    UnderstandingProvenance? provenance,
    CandidateStoryClassification? candidateClassification,
    CandidateContentSuitability? candidateContentSuitability,
    CandidateSpiritualityClassification? candidateSpirituality,
    Iterable<StoryObservation>? observations,
    String processingVersion = 'hs4-v1',
  }) {
    final sources =
        sourceRepresentationIds ?? [StoryRepresentationId.generate()];
    return StoryUnderstanding.createProposed(
      id: id ?? StoryUnderstandingId.generate(),
      storyId: storyId ?? StoryId.generate(),
      sourceRepresentationIds: sources,
      analysisLanguage: english,
      provenance: provenance ?? buildProvenance(sourceRepresentationIds: sources),
      processingVersion: processingVersion,
      createdAt: analyzedAt,
      candidateClassification:
          candidateClassification ??
          CandidateStoryClassification(subjects: [StorySubject.military]),
      candidateContentSuitability: candidateContentSuitability,
      candidateSpirituality: candidateSpirituality,
      observations: observations,
    );
  }

  UnderstandingReview acceptReview({DateTime? decidedAt}) {
    return UnderstandingReview(
      decision: UnderstandingReviewDecision.accept,
      decidedAt: decidedAt ?? analyzedAt,
      acceptClassification: true,
      acceptSuitability: true,
      acceptSpirituality: true,
    );
  }

  group('StoryUnderstanding.createProposed', () {
    test('requires StoryId and at least one sourceRepresentationId', () {
      final storyId = StoryId.generate();
      final sourceId = StoryRepresentationId.generate();

      final understanding = createProposed(
        storyId: storyId,
        sourceRepresentationIds: [sourceId],
      );

      expect(understanding.storyId, storyId);
      expect(understanding.sourceRepresentationIds, [sourceId]);

      expect(
        () => StoryUnderstanding.createProposed(
          id: StoryUnderstandingId.generate(),
          storyId: StoryId.generate(),
          sourceRepresentationIds: const [],
          analysisLanguage: english,
          provenance: buildProvenance(
            sourceRepresentationIds: [StoryRepresentationId.generate()],
          ),
          processingVersion: 'hs4-v1',
          createdAt: analyzedAt,
          candidateClassification: CandidateStoryClassification(
            subjects: [StorySubject.military],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('raises StoryUnderstandingProposed', () {
      final understanding = createProposed();
      final events = understanding.pullDomainEvents();

      expectEventRaised<StoryUnderstandingProposed>(events);
      expectEventCount(events, 1);

      final proposed = expectSingleEvent<StoryUnderstandingProposed>(events);
      expect(proposed.understandingId, understanding.id);
      expect(proposed.storyId, understanding.storyId);
    });

    test('status starts as proposed', () {
      final understanding = createProposed();
      expect(understanding.status, UnderstandingStatus.proposed);
      expect(understanding.review, isNull);
      expect(understanding.reviewedAt, isNull);
    });
  });

  group('StoryUnderstanding.recordReview', () {
    test('accept → approved and raises StoryUnderstandingReviewed', () {
      final understanding = createProposed();
      understanding.pullDomainEvents();

      understanding.recordReview(acceptReview());

      expect(understanding.status, UnderstandingStatus.approved);
      expect(understanding.reviewedAt, analyzedAt);
      expect(understanding.review?.decision, UnderstandingReviewDecision.accept);

      final events = understanding.pullDomainEvents();
      final reviewed = expectSingleEvent<StoryUnderstandingReviewed>(events);
      expect(reviewed.decision, UnderstandingReviewDecision.accept);
      expect(reviewed.status, UnderstandingStatus.approved);
      expect(reviewed.understandingId, understanding.id);
      expect(reviewed.storyId, understanding.storyId);
    });

    test('reject → rejected', () {
      final understanding = createProposed();
      understanding.pullDomainEvents();

      understanding.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.reject,
          decidedAt: analyzedAt,
        ),
      );

      expect(understanding.status, UnderstandingStatus.rejected);
      expectEventRaised<StoryUnderstandingReviewed>(
        understanding.pullDomainEvents(),
      );
    });

    test('partial → partiallyReviewed', () {
      final understanding = createProposed();
      understanding.pullDomainEvents();

      understanding.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.partial,
          decidedAt: analyzedAt,
          acceptClassification: true,
        ),
      );

      expect(understanding.status, UnderstandingStatus.partiallyReviewed);
      expectEventRaised<StoryUnderstandingReviewed>(
        understanding.pullDomainEvents(),
      );
    });

    test('modify with partial accepts → partiallyReviewed', () {
      final understanding = createProposed();
      understanding.pullDomainEvents();

      understanding.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.modify,
          decidedAt: analyzedAt,
          acceptClassification: true,
          acceptSuitability: false,
          acceptSpirituality: false,
          modifiedClassification: CandidateStoryClassification(
            subjects: [StorySubject.leadership],
          ),
        ),
      );

      expect(understanding.status, UnderstandingStatus.partiallyReviewed);
      expect(
        understanding.review?.decision,
        UnderstandingReviewDecision.modify,
      );
      expectEventRaised<StoryUnderstandingReviewed>(
        understanding.pullDomainEvents(),
      );
    });

    test('cannot review superseded, rejected, or approved understandings', () {
      final approved = createProposed();
      approved.recordReview(acceptReview());
      expect(
        () => approved.recordReview(acceptReview()),
        throwsStateError,
      );

      final rejected = createProposed();
      rejected.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.reject,
          decidedAt: analyzedAt,
        ),
      );
      expect(
        () => rejected.recordReview(acceptReview()),
        throwsStateError,
      );

      final superseded = createProposed();
      superseded.markSupersededBy(StoryUnderstandingId.generate());
      expect(
        () => superseded.recordReview(acceptReview()),
        throwsStateError,
      );
    });
  });

  group('StoryUnderstanding.markSupersededBy', () {
    test('→ superseded and raises StoryUnderstandingSuperseded', () {
      final understanding = createProposed();
      understanding.pullDomainEvents();
      final newerId = StoryUnderstandingId.generate();

      understanding.markSupersededBy(newerId);

      expect(understanding.status, UnderstandingStatus.superseded);

      final events = understanding.pullDomainEvents();
      final superseded =
          expectSingleEvent<StoryUnderstandingSuperseded>(events);
      expect(superseded.understandingId, understanding.id);
      expect(superseded.storyId, understanding.storyId);
      expect(superseded.supersededByUnderstandingId, newerId);
    });
  });

  group('StoryUnderstanding payload immutability', () {
    test('observations, candidates, and provenance are final after create', () {
      final sourceId = StoryRepresentationId.generate();
      final observation = StoryObservation(
        kind: ObservationKind.contentMention,
        content: 'Mentions military service.',
        supportLevel: AnalysisSupportLevel.moderate,
      );
      final classification = CandidateStoryClassification(
        subjects: [StorySubject.military],
      );
      final provenance = buildProvenance(sourceRepresentationIds: [sourceId]);

      final understanding = createProposed(
        sourceRepresentationIds: [sourceId],
        provenance: provenance,
        candidateClassification: classification,
        observations: [observation],
      );

      expect(understanding.observations, [observation]);
      expect(understanding.candidateClassification, classification);
      expect(understanding.provenance, provenance);
      expect(
        () => understanding.sourceRepresentationIds.add(
          StoryRepresentationId.generate(),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => understanding.observations.add(
          StoryObservation(
            kind: ObservationKind.other,
            content: 'Extra note',
          ),
        ),
        throwsUnsupportedError,
      );

      understanding.assertPayloadImmutable();
    });
  });

  group('StoryObservation', () {
    test('rejects empty content', () {
      expect(
        () => StoryObservation(
          kind: ObservationKind.other,
          content: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects forbidden Hero identity claim content', () {
      expect(
        () => StoryObservation(
          kind: ObservationKind.contentMention,
          content: 'Hero is Christian',
        ),
        throwsArgumentError,
      );
      expect(
        () => StoryObservation(
          kind: ObservationKind.contentMention,
          content: 'The hero is a Muslim according to the transcript.',
        ),
        throwsArgumentError,
      );
    });
  });

  group('UnderstandingProvenance', () {
    test('requires non-empty sourceRepresentationIds and providerLabel', () {
      expect(
        () => UnderstandingProvenance(
          sourceRepresentationIds: const [],
          analyzedAt: analyzedAt,
          providerLabel: 'in_memory',
          processingVersion: 'hs4-v1',
        ),
        throwsArgumentError,
      );

      expect(
        () => UnderstandingProvenance(
          sourceRepresentationIds: [StoryRepresentationId.generate()],
          analyzedAt: analyzedAt,
          providerLabel: '  ',
          processingVersion: 'hs4-v1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('CandidateSpiritualityClassification', () {
    test('rejects tradition when not religious', () {
      expect(
        () => CandidateSpiritualityClassification(
          category: SpiritualityCategory.spiritual,
          tradition: ReligiousTradition.christianity,
        ),
        throwsArgumentError,
      );
      expect(
        () => CandidateSpiritualityClassification(
          category: SpiritualityCategory.nonSpiritual,
          tradition: ReligiousTradition.islam,
        ),
        throwsArgumentError,
      );

      final religious = CandidateSpiritualityClassification(
        category: SpiritualityCategory.religious,
        tradition: ReligiousTradition.christianity,
      );
      expect(religious.tradition, ReligiousTradition.christianity);
    });
  });

  group('StoryUnderstanding.isStaleRelativeTo', () {
    test('is stale when a source representation is missing', () {
      final sourceA = StoryRepresentationId.generate();
      final sourceB = StoryRepresentationId.generate();
      final understanding = createProposed(
        sourceRepresentationIds: [sourceA, sourceB],
      );

      expect(understanding.isStaleRelativeTo([sourceA, sourceB]), isFalse);
      expect(understanding.isStaleRelativeTo([sourceA]), isTrue);
      expect(understanding.isStaleRelativeTo(const []), isTrue);
    });
  });

  group('StoryUnderstanding.markAppliedToStory', () {
    test('requires applicable reviewed status', () {
      final proposed = createProposed();
      expect(
        () => proposed.markAppliedToStory(at: analyzedAt),
        throwsStateError,
      );

      final rejected = createProposed();
      rejected.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.reject,
          decidedAt: analyzedAt,
        ),
      );
      expect(
        () => rejected.markAppliedToStory(at: analyzedAt),
        throwsStateError,
      );

      final approved = createProposed();
      approved.recordReview(acceptReview());
      approved.markAppliedToStory(at: DateTime.utc(2026, 9, 13));
      expect(
        approved.review?.appliedToStoryAt,
        DateTime.utc(2026, 9, 13),
      );

      final partial = createProposed();
      partial.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.partial,
          decidedAt: analyzedAt,
          acceptClassification: true,
        ),
      );
      partial.markAppliedToStory(at: DateTime.utc(2026, 9, 14));
      expect(
        partial.review?.appliedToStoryAt,
        DateTime.utc(2026, 9, 14),
      );
    });
  });

  group('StoryUnderstanding.effectiveClassification', () {
    test('uses modifiedClassification when present', () {
      final original = CandidateStoryClassification(
        subjects: [StorySubject.military],
      );
      final modified = CandidateStoryClassification(
        subjects: [StorySubject.leadership],
      );
      final understanding = createProposed(candidateClassification: original);

      expect(understanding.effectiveClassification, original);

      understanding.recordReview(
        UnderstandingReview(
          decision: UnderstandingReviewDecision.modify,
          decidedAt: analyzedAt,
          acceptClassification: true,
          acceptSuitability: true,
          acceptSpirituality: true,
          modifiedClassification: modified,
        ),
      );

      expect(understanding.effectiveClassification, modified);
      expect(understanding.candidateClassification, original);
    });
  });

  group('UnderstandingStatus and AnalysisSupportLevel', () {
    test('UnderstandingStatus.canTransitionTo helpers', () {
      expect(
        UnderstandingStatus.proposed.canTransitionTo(
          UnderstandingStatus.approved,
        ),
        isTrue,
      );
      expect(
        UnderstandingStatus.proposed.canTransitionTo(
          UnderstandingStatus.partiallyReviewed,
        ),
        isTrue,
      );
      expect(
        UnderstandingStatus.proposed.canTransitionTo(
          UnderstandingStatus.rejected,
        ),
        isTrue,
      );
      expect(
        UnderstandingStatus.proposed.canTransitionTo(
          UnderstandingStatus.superseded,
        ),
        isTrue,
      );

      expect(
        UnderstandingStatus.approved.canTransitionTo(
          UnderstandingStatus.superseded,
        ),
        isTrue,
      );
      expect(
        UnderstandingStatus.approved.canTransitionTo(
          UnderstandingStatus.proposed,
        ),
        isFalse,
      );
      expect(
        UnderstandingStatus.approved.canTransitionTo(
          UnderstandingStatus.rejected,
        ),
        isFalse,
      );

      expect(
        UnderstandingStatus.rejected.canTransitionTo(
          UnderstandingStatus.superseded,
        ),
        isTrue,
      );
      expect(
        UnderstandingStatus.rejected.canTransitionTo(
          UnderstandingStatus.approved,
        ),
        isFalse,
      );

      expect(
        UnderstandingStatus.superseded.canTransitionTo(
          UnderstandingStatus.proposed,
        ),
        isFalse,
      );
      expect(
        UnderstandingStatus.superseded.canTransitionTo(
          UnderstandingStatus.superseded,
        ),
        isFalse,
      );

      expect(UnderstandingStatus.proposed.isReviewable, isTrue);
      expect(UnderstandingStatus.partiallyReviewed.isReviewable, isTrue);
      expect(UnderstandingStatus.approved.isReviewable, isFalse);
      expect(UnderstandingStatus.rejected.isReviewable, isFalse);
      expect(UnderstandingStatus.superseded.isReviewable, isFalse);

      expect(UnderstandingStatus.approved.isApplicable, isTrue);
      expect(UnderstandingStatus.partiallyReviewed.isApplicable, isTrue);
      expect(UnderstandingStatus.proposed.isApplicable, isFalse);
      expect(UnderstandingStatus.rejected.isApplicable, isFalse);
    });

    test('AnalysisSupportLevel enum values are available for observations', () {
      expect(AnalysisSupportLevel.values, contains(AnalysisSupportLevel.unknown));
      expect(AnalysisSupportLevel.values, contains(AnalysisSupportLevel.weak));
      expect(
        AnalysisSupportLevel.values,
        contains(AnalysisSupportLevel.moderate),
      );
      expect(AnalysisSupportLevel.values, contains(AnalysisSupportLevel.strong));

      final observation = StoryObservation(
        kind: ObservationKind.uncertainty,
        content: 'Ambiguous reference to service branch.',
        supportLevel: AnalysisSupportLevel.weak,
      );
      expect(observation.supportLevel, AnalysisSupportLevel.weak);
    });
  });
}
