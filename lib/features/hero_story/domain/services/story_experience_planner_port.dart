import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';

/// Provider-independent Story Experience Plan boundary (HS.12.4).
///
/// Separate from [CapturedStoryReadingPort], [StoryTranscriptionPort], HS.4
/// [StoryUnderstandingPort], and SB.8 [StoryBuilderUnderstandingPort].
abstract interface class StoryExperiencePlannerPort {
  Future<StoryExperiencePlanDraft> generate({
    required Story story,
    required CapturedStoryReading reading,
    required String transcriptText,
  });
}

/// EH-owned draft mapped into [StoryExperiencePlan] by the use case.
final class StoryExperiencePlanDraft {
  const StoryExperiencePlanDraft({
    required this.intention,
    required this.coreMessage,
    required this.emotionalArc,
    required this.keyMoments,
    required this.musicDirection,
    required this.reflectionPrompt,
    required this.sequence,
    this.providerLabel,
    this.processingVersion,
  });

  final StoryExperienceIntention intention;
  final String coreMessage;
  final StoryExperienceArc emotionalArc;
  final List<StoryExperiencePlanDraftMoment> keyMoments;
  final StoryExperiencePlanDraftMusicDirection musicDirection;
  final String reflectionPrompt;
  final List<StoryExperiencePlanDraftStep> sequence;
  final String? providerLabel;
  final String? processingVersion;
}

final class StoryExperiencePlanDraftMoment {
  const StoryExperiencePlanDraftMoment({
    required this.id,
    required this.description,
    required this.startOffset,
    required this.endOffset,
    this.startTimestampMs,
    this.endTimestampMs,
  });

  final String id;
  final String description;
  final int startOffset;
  final int endOffset;
  final int? startTimestampMs;
  final int? endTimestampMs;
}

final class StoryExperiencePlanDraftMusicDirection {
  const StoryExperiencePlanDraftMusicDirection({
    required this.mood,
    required this.energy,
    required this.style,
    required this.rationale,
  });

  final String mood;
  final String energy;
  final String style;
  final String rationale;
}

final class StoryExperiencePlanDraftStep {
  const StoryExperiencePlanDraftStep({
    required this.type,
    this.referenceId,
  });

  final StoryExperienceStepType type;
  final String? referenceId;
}

final class StoryExperiencePlannerException implements Exception {
  const StoryExperiencePlannerException(this.message);

  final String message;

  @override
  String toString() => 'StoryExperiencePlannerException: $message';
}
