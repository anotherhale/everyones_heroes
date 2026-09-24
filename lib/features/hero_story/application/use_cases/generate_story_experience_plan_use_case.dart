import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_experience_plan_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_experience_plan_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';

/// Generates a persisted, typed Story Experience Plan (HS.12.4).
///
/// Does not mutate the canonical Story or CapturedStoryReading.
/// Does not regenerate transcription or understanding.
final class GenerateStoryExperiencePlanUseCase
    implements
        UseCase<
          GenerateStoryExperiencePlanAppRequest,
          GenerateStoryExperiencePlanResponse
        > {
  const GenerateStoryExperiencePlanUseCase({
    required StoryRepository storyRepository,
    required CapturedStoryReadingRepository readingRepository,
    required StoryExperiencePlannerPort planner,
    required StoryExperiencePlanRepository planRepository,
  })  : _storyRepository = storyRepository,
        _readingRepository = readingRepository,
        _planner = planner,
        _planRepository = planRepository;

  final StoryRepository _storyRepository;
  final CapturedStoryReadingRepository _readingRepository;
  final StoryExperiencePlannerPort _planner;
  final StoryExperiencePlanRepository _planRepository;

  @override
  Future<Result<GenerateStoryExperiencePlanResponse>> execute(
    GenerateStoryExperiencePlanAppRequest request,
  ) async {
    final at = request.occurredAt ?? DateTime.now();

    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      final reading =
          await _readingRepository.findByStoryId(request.storyId);
      if (reading == null) {
        return Failure(
          'CapturedStoryReading not found for story: '
          '${request.storyId.value}',
        );
      }

      if (reading.storyId != story.id) {
        return const Failure(
          'CapturedStoryReading storyId does not match Story.',
        );
      }

      if (!request.forceRegenerate) {
        final existing = await _planRepository.findByStoryId(story.id);
        if (existing != null) {
          return Success(
            GenerateStoryExperiencePlanResponse(
              plan: existing,
              idempotentReplay: true,
            ),
          );
        }
      }

      final transcript = story.findRepresentation(
        reading.transcriptRepresentationId,
      );
      final transcriptText = transcript?.textContent?.trim() ?? '';
      if (transcriptText.isEmpty) {
        return const Failure(
          'Transcript text is required to generate a Story Experience Plan. '
          'Understand the story first so a transcript exists.',
        );
      }

      final StoryExperiencePlanDraft draft;
      try {
        draft = await _planner.generate(
          story: story,
          reading: reading,
          transcriptText: transcriptText,
        );
      } on StoryExperiencePlannerException catch (e) {
        return Failure(e.message);
      }

      final plan = _mapDraft(
        draft: draft,
        storyId: story.id,
        transcriptRepresentationId: reading.transcriptRepresentationId,
        transcriptText: transcriptText,
        at: at,
        processingVersion: request.processingVersion,
      );

      await _planRepository.save(plan);

      return Success(GenerateStoryExperiencePlanResponse(plan: plan));
    } catch (e) {
      return Failure('Failed to generate Story Experience Plan: $e');
    }
  }

  StoryExperiencePlan _mapDraft({
    required StoryExperiencePlanDraft draft,
    required StoryId storyId,
    required StoryRepresentationId transcriptRepresentationId,
    required String transcriptText,
    required DateTime at,
    required String processingVersion,
  }) {
    final plan = StoryExperiencePlan(
      id: StoryExperiencePlanId.generate(),
      storyId: storyId,
      transcriptRepresentationId: transcriptRepresentationId,
      intention: draft.intention,
      coreMessage: draft.coreMessage,
      emotionalArc: draft.emotionalArc,
      keyMoments: [
        for (final moment in draft.keyMoments)
          StoryExperienceMoment(
            id: moment.id,
            description: moment.description,
            sourceSpan: SourceSpanReference(
              representationId: transcriptRepresentationId,
              startOffset: moment.startOffset,
              endOffset: moment.endOffset,
              startTimestampMs: moment.startTimestampMs,
              endTimestampMs: moment.endTimestampMs,
            ),
          ),
      ],
      musicDirection: StoryExperienceMusicDirection(
        mood: draft.musicDirection.mood,
        energy: draft.musicDirection.energy,
        style: draft.musicDirection.style,
        rationale: draft.musicDirection.rationale,
      ),
      reflectionPrompt: draft.reflectionPrompt,
      sequence: [
        for (final step in draft.sequence)
          StoryExperienceStep(
            type: step.type,
            referenceId: step.referenceId,
          ),
      ],
      createdAt: at,
      providerLabel: draft.providerLabel,
      processingVersion:
          draft.processingVersion?.trim().isNotEmpty == true
              ? draft.processingVersion!.trim()
              : processingVersion,
    );

    plan.assertSpansWithinTranscript(transcriptText);
    return plan;
  }
}
