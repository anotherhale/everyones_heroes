import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_review_decision.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_story_classification.dart';

final class ReviewStoryUnderstandingRequest {
  const ReviewStoryUnderstandingRequest({
    required this.understandingId,
    required this.decision,
    this.reviewerActorId,
    this.notes,
    this.acceptClassification = false,
    this.acceptSuitability = false,
    this.acceptSpirituality = false,
    this.modifiedClassification,
    this.modifiedSuitability,
    this.modifiedSpirituality,
    this.at,
  });

  final StoryUnderstandingId understandingId;
  final UnderstandingReviewDecision decision;
  final String? reviewerActorId;
  final String? notes;
  final bool acceptClassification;
  final bool acceptSuitability;
  final bool acceptSpirituality;
  final CandidateStoryClassification? modifiedClassification;
  final CandidateContentSuitability? modifiedSuitability;
  final CandidateSpiritualityClassification? modifiedSpirituality;
  final DateTime? at;
}
