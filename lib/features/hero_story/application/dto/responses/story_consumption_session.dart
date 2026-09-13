import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';

/// Ephemeral Story consumption session (HS.7 D8 / D15).
///
/// Not an aggregate. Does not persist. Does not create Reflection,
/// BehavioralEvidence, or domain events.
final class StoryConsumptionSession {
  const StoryConsumptionSession({
    required this.storyId,
    required this.experience,
    required this.selectedRepresentation,
    required this.startedAt,
    this.completed = false,
  });

  final StoryId storyId;
  final StoryExperienceDetail experience;
  final PlayableRepresentation selectedRepresentation;
  final DateTime startedAt;
  final bool completed;

  StoryRepresentationId get representationId =>
      selectedRepresentation.representationId;

  StoryConsumptionSession markCompleted() {
    return StoryConsumptionSession(
      storyId: storyId,
      experience: experience,
      selectedRepresentation: selectedRepresentation,
      startedAt: startedAt,
      completed: true,
    );
  }
}
