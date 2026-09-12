import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/apply_story_understanding_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/classify_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_content_suitability_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_spirituality_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/classify_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_content_suitability_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_spirituality_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_understanding_repository.dart';

/// Applies reviewed understanding candidates through authoritative Story paths.
final class ApplyStoryUnderstandingUseCase
    implements UseCase<ApplyStoryUnderstandingRequest, Story> {
  ApplyStoryUnderstandingUseCase({
    required StoryRepository storyRepository,
    required StoryUnderstandingRepository understandingRepository,
    required EventBus eventBus,
    ClassifyStoryUseCase? classifyStoryUseCase,
    UpdateStoryContentSuitabilityUseCase? updateSuitabilityUseCase,
    UpdateStorySpiritualityUseCase? updateSpiritualityUseCase,
  }) : _storyRepository = storyRepository,
       _understandingRepository = understandingRepository,
       _classifyStoryUseCase =
           classifyStoryUseCase ??
           ClassifyStoryUseCase(
             storyRepository: storyRepository,
             eventBus: eventBus,
           ),
       _updateSuitabilityUseCase =
           updateSuitabilityUseCase ??
           UpdateStoryContentSuitabilityUseCase(
             storyRepository: storyRepository,
             eventBus: eventBus,
           ),
       _updateSpiritualityUseCase =
           updateSpiritualityUseCase ??
           UpdateStorySpiritualityUseCase(
             storyRepository: storyRepository,
             eventBus: eventBus,
           );

  final StoryRepository _storyRepository;
  final StoryUnderstandingRepository _understandingRepository;
  final ClassifyStoryUseCase _classifyStoryUseCase;
  final UpdateStoryContentSuitabilityUseCase _updateSuitabilityUseCase;
  final UpdateStorySpiritualityUseCase _updateSpiritualityUseCase;

  @override
  Future<Result<Story>> execute(ApplyStoryUnderstandingRequest request) async {
    try {
      if (!request.applyClassification &&
          !request.applySuitability &&
          !request.applySpirituality) {
        return const Failure(
          'At least one apply dimension must be requested.',
        );
      }

      final understanding = await _understandingRepository.findById(
        request.understandingId,
      );
      if (understanding == null) {
        return Failure(
          'StoryUnderstanding not found: ${request.understandingId.value}',
        );
      }

      if (understanding.status == UnderstandingStatus.rejected) {
        return const Failure(
          'Rejected understanding cannot be applied to Story.',
        );
      }
      if (!understanding.status.isApplicable) {
        return Failure(
          'Understanding status ${understanding.status.name} is not applicable.',
        );
      }

      final review = understanding.review;
      if (review == null) {
        return const Failure(
          'Understanding must be reviewed before apply.',
        );
      }

      final story = await _storyRepository.findById(understanding.storyId);
      if (story == null) {
        return Failure('Story not found: ${understanding.storyId.value}');
      }

      final presentIds = story.representations.map((r) => r.id);
      final stale = understanding.isStaleRelativeTo(presentIds);
      if (stale && !request.acknowledgeStale) {
        return const Failure(
          'Understanding sources are stale relative to Story representations. '
          'Pass acknowledgeStale to apply explicitly.',
        );
      }

      if (request.applyClassification) {
        if (!review.acceptClassification) {
          return const Failure(
            'Classification was not accepted in review.',
          );
        }
        final candidate = understanding.effectiveClassification;
        if (candidate == null || candidate.isEmpty) {
          return const Failure(
            'No classification candidate available to apply.',
          );
        }
        final result = await _classifyStoryUseCase.execute(
          ClassifyStoryRequest(
            storyId: story.id,
            classification: candidate.toAuthoritative(),
          ),
        );
        if (result.isFailure) {
          return Failure((result as Failure).error);
        }
      }

      if (request.applySuitability) {
        if (!review.acceptSuitability) {
          return const Failure(
            'Suitability was not accepted in review.',
          );
        }
        final candidate = understanding.effectiveSuitability;
        if (candidate == null) {
          return const Failure(
            'No suitability candidate available to apply.',
          );
        }
        final result = await _updateSuitabilityUseCase.execute(
          UpdateStoryContentSuitabilityRequest(
            storyId: story.id,
            contentSuitability: candidate.toAuthoritative(),
          ),
        );
        if (result.isFailure) {
          return Failure((result as Failure).error);
        }
      }

      if (request.applySpirituality) {
        if (!review.acceptSpirituality) {
          return const Failure(
            'Spirituality was not accepted in review.',
          );
        }
        final candidate = understanding.effectiveSpirituality;
        if (candidate == null) {
          return const Failure(
            'No spirituality candidate available to apply.',
          );
        }
        final result = await _updateSpiritualityUseCase.execute(
          UpdateStorySpiritualityRequest(
            storyId: story.id,
            spirituality: candidate.toAuthoritative(),
          ),
        );
        if (result.isFailure) {
          return Failure((result as Failure).error);
        }
      }

      final at = request.at ?? DateTime.now();
      understanding.markAppliedToStory(at: at);
      await _understandingRepository.save(understanding);

      final updated = await _storyRepository.findById(story.id);
      if (updated == null) {
        return Failure('Story not found after apply: ${story.id.value}');
      }
      return Success(updated);
    } catch (e) {
      return Failure('Failed to apply story understanding: $e');
    }
  }
}
