import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_review_decision.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_understanding_proposed.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_understanding_reviewed.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_understanding_superseded.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_observation.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understanding_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understanding_review.dart';

/// Non-canonical AI-assisted interpretation of a Story (HS-ADR-022/023).
///
/// AI proposals never silently become authoritative Story catalog state.
final class StoryUnderstanding extends AggregateRoot<StoryUnderstandingId> {
  StoryUnderstanding({
    required StoryUnderstandingId id,
    required this.storyId,
    required UnderstandingStatus status,
    required Iterable<StoryRepresentationId> sourceRepresentationIds,
    required this.analysisLanguage,
    required this.provenance,
    required this.processingVersion,
    required DateTime createdAt,
    this.detectedLanguage,
    CandidateStoryClassification? candidateClassification,
    CandidateContentSuitability? candidateContentSuitability,
    CandidateSpiritualityClassification? candidateSpirituality,
    Iterable<StoryObservation>? observations,
    DateTime? reviewedAt,
    this.supersedesUnderstandingId,
    UnderstandingReview? review,
  }) : _status = status,
       sourceRepresentationIds = List.unmodifiable(
         sourceRepresentationIds.toList(),
       ),
       candidateClassification = candidateClassification,
       candidateContentSuitability = candidateContentSuitability,
       candidateSpirituality = candidateSpirituality,
       observations = List.unmodifiable(observations ?? const []),
       _createdAt = createdAt,
       _reviewedAt = reviewedAt,
       _review = review,
       super(id) {
    if (this.sourceRepresentationIds.isEmpty) {
      throw ArgumentError(
        'StoryUnderstanding requires at least one source representation.',
      );
    }
    if (processingVersion.trim().isEmpty) {
      throw ArgumentError('Processing version cannot be empty.');
    }
  }

  factory StoryUnderstanding.createProposed({
    required StoryUnderstandingId id,
    required StoryId storyId,
    required Iterable<StoryRepresentationId> sourceRepresentationIds,
    required LanguageCode analysisLanguage,
    required UnderstandingProvenance provenance,
    required String processingVersion,
    LanguageCode? detectedLanguage,
    CandidateStoryClassification? candidateClassification,
    CandidateContentSuitability? candidateContentSuitability,
    CandidateSpiritualityClassification? candidateSpirituality,
    Iterable<StoryObservation>? observations,
    StoryUnderstandingId? supersedesUnderstandingId,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final understanding = StoryUnderstanding(
      id: id,
      storyId: storyId,
      status: UnderstandingStatus.proposed,
      sourceRepresentationIds: sourceRepresentationIds,
      analysisLanguage: analysisLanguage,
      detectedLanguage: detectedLanguage,
      candidateClassification: candidateClassification,
      candidateContentSuitability: candidateContentSuitability,
      candidateSpirituality: candidateSpirituality,
      observations: observations,
      provenance: provenance,
      processingVersion: processingVersion,
      createdAt: now,
      supersedesUnderstandingId: supersedesUnderstandingId,
    );

    understanding.raise(
      StoryUnderstandingProposed(
        understandingId: id,
        storyId: storyId,
      ),
    );
    return understanding;
  }

  final StoryId storyId;
  UnderstandingStatus _status;
  final List<StoryRepresentationId> sourceRepresentationIds;
  final LanguageCode analysisLanguage;
  final LanguageCode? detectedLanguage;
  final CandidateStoryClassification? candidateClassification;
  final CandidateContentSuitability? candidateContentSuitability;
  final CandidateSpiritualityClassification? candidateSpirituality;
  final List<StoryObservation> observations;
  final UnderstandingProvenance provenance;
  final String processingVersion;
  final DateTime _createdAt;
  DateTime? _reviewedAt;
  final StoryUnderstandingId? supersedesUnderstandingId;
  UnderstandingReview? _review;

  UnderstandingStatus get status => _status;
  DateTime get createdAt => _createdAt;
  DateTime? get reviewedAt => _reviewedAt;
  UnderstandingReview? get review => _review;

  /// Effective classification candidate after optional review modification.
  CandidateStoryClassification? get effectiveClassification =>
      _review?.modifiedClassification ?? candidateClassification;

  CandidateContentSuitability? get effectiveSuitability =>
      _review?.modifiedSuitability ?? candidateContentSuitability;

  CandidateSpiritualityClassification? get effectiveSpirituality =>
      _review?.modifiedSpirituality ?? candidateSpirituality;

  /// Whether any referenced source representation is missing from [presentIds].
  bool isStaleRelativeTo(Iterable<StoryRepresentationId> presentIds) {
    final present = presentIds.toSet();
    return sourceRepresentationIds.any((id) => !present.contains(id));
  }

  void recordReview(UnderstandingReview review) {
    if (!_status.isReviewable) {
      throw StateError(
        'Cannot review a ${_status.name} understanding.',
      );
    }

    final nextStatus = switch (review.decision) {
      UnderstandingReviewDecision.accept => UnderstandingStatus.approved,
      UnderstandingReviewDecision.reject => UnderstandingStatus.rejected,
      UnderstandingReviewDecision.partial =>
        UnderstandingStatus.partiallyReviewed,
      UnderstandingReviewDecision.modify => _statusForModify(review),
    };

    _transitionTo(nextStatus);
    _review = review;
    _reviewedAt = review.decidedAt;

    raise(
      StoryUnderstandingReviewed(
        understandingId: id,
        storyId: storyId,
        decision: review.decision,
        status: _status,
      ),
    );
  }

  UnderstandingStatus _statusForModify(UnderstandingReview review) {
    final acceptedAny =
        review.acceptClassification ||
        review.acceptSuitability ||
        review.acceptSpirituality;
    if (!acceptedAny) {
      return UnderstandingStatus.rejected;
    }
    final allAccepted =
        review.acceptClassification &&
        review.acceptSuitability &&
        review.acceptSpirituality;
    if (allAccepted) {
      return UnderstandingStatus.approved;
    }
    return UnderstandingStatus.partiallyReviewed;
  }

  void markSupersededBy(StoryUnderstandingId newerId) {
    if (_status == UnderstandingStatus.superseded) {
      return;
    }
    if (!_status.canTransitionTo(UnderstandingStatus.superseded)) {
      throw StateError(
        'Cannot supersede understanding in status ${_status.name}.',
      );
    }

    _transitionTo(UnderstandingStatus.superseded);
    raise(
      StoryUnderstandingSuperseded(
        understandingId: id,
        storyId: storyId,
        supersededByUnderstandingId: newerId,
      ),
    );
  }

  void markAppliedToStory({required DateTime at}) {
    if (!_status.isApplicable) {
      throw StateError(
        'Only approved or partially reviewed understandings may be applied.',
      );
    }
    final current = _review;
    if (current == null) {
      throw StateError(
        'Understanding must be reviewed before it can be applied.',
      );
    }
    _review = current.markApplied(at: at);
  }

  /// AI proposal payload fields are immutable after creation.
  void assertPayloadImmutable() {
    // Guaranteed by final fields on the aggregate; method exists for tests.
  }

  void _transitionTo(UnderstandingStatus next) {
    if (!_status.canTransitionTo(next)) {
      throw StateError(
        'Invalid understanding status transition: '
        '${_status.name} -> ${next.name}',
      );
    }
    _status = next;
  }
}
