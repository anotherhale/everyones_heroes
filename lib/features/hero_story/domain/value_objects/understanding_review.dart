import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_review_decision.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_story_classification.dart';

/// Human review decision recorded against a StoryUnderstanding proposal.
final class UnderstandingReview extends ValueObject {
  const UnderstandingReview({
    required this.decision,
    required this.decidedAt,
    this.reviewerActorId,
    this.notes,
    this.acceptClassification = false,
    this.acceptSuitability = false,
    this.acceptSpirituality = false,
    this.modifiedClassification,
    this.modifiedSuitability,
    this.modifiedSpirituality,
    this.appliedToStoryAt,
  });

  final UnderstandingReviewDecision decision;
  final DateTime decidedAt;
  final String? reviewerActorId;
  final String? notes;
  final bool acceptClassification;
  final bool acceptSuitability;
  final bool acceptSpirituality;
  final CandidateStoryClassification? modifiedClassification;
  final CandidateContentSuitability? modifiedSuitability;
  final CandidateSpiritualityClassification? modifiedSpirituality;
  final DateTime? appliedToStoryAt;

  UnderstandingReview markApplied({required DateTime at}) {
    return UnderstandingReview(
      decision: decision,
      decidedAt: decidedAt,
      reviewerActorId: reviewerActorId,
      notes: notes,
      acceptClassification: acceptClassification,
      acceptSuitability: acceptSuitability,
      acceptSpirituality: acceptSpirituality,
      modifiedClassification: modifiedClassification,
      modifiedSuitability: modifiedSuitability,
      modifiedSpirituality: modifiedSpirituality,
      appliedToStoryAt: at,
    );
  }

  @override
  List<Object?> get equalityProps => [
    decision,
    decidedAt,
    reviewerActorId,
    notes,
    acceptClassification,
    acceptSuitability,
    acceptSpirituality,
    modifiedClassification,
    modifiedSuitability,
    modifiedSpirituality,
    appliedToStoryAt,
  ];
}
