import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/review_story_understanding_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_understanding.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_review_decision.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_understanding_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understanding_review.dart';

/// Records human review of a StoryUnderstanding proposal.
///
/// Does not mutate canonical Story catalog state.
final class ReviewStoryUnderstandingUseCase
    implements UseCase<ReviewStoryUnderstandingRequest, StoryUnderstanding> {
  const ReviewStoryUnderstandingUseCase({
    required this._understandingRepository,
    required this._eventBus,
  });

  final StoryUnderstandingRepository _understandingRepository;
  final EventBus _eventBus;

  @override
  Future<Result<StoryUnderstanding>> execute(
    ReviewStoryUnderstandingRequest request,
  ) async {
    try {
      final understanding = await _understandingRepository.findById(
        request.understandingId,
      );
      if (understanding == null) {
        return Failure(
          'StoryUnderstanding not found: ${request.understandingId.value}',
        );
      }

      final at = request.at ?? DateTime.now();
      var acceptClassification = request.acceptClassification;
      var acceptSuitability = request.acceptSuitability;
      var acceptSpirituality = request.acceptSpirituality;

      switch (request.decision) {
        case UnderstandingReviewDecision.accept:
          acceptClassification = true;
          acceptSuitability = true;
          acceptSpirituality = true;
        case UnderstandingReviewDecision.reject:
          acceptClassification = false;
          acceptSuitability = false;
          acceptSpirituality = false;
        case UnderstandingReviewDecision.partial:
        case UnderstandingReviewDecision.modify:
          break;
      }

      final review = UnderstandingReview(
        decision: request.decision,
        decidedAt: at,
        reviewerActorId: request.reviewerActorId,
        notes: request.notes,
        acceptClassification: acceptClassification,
        acceptSuitability: acceptSuitability,
        acceptSpirituality: acceptSpirituality,
        modifiedClassification: request.modifiedClassification,
        modifiedSuitability: request.modifiedSuitability,
        modifiedSpirituality: request.modifiedSpirituality,
      );

      understanding.recordReview(review);
      await _understandingRepository.save(understanding);

      for (final event in understanding.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(understanding);
    } catch (e) {
      return Failure('Failed to review story understanding: $e');
    }
  }
}
