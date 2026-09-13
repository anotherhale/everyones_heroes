import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Explicit user-initiated reflection after Story consumption (HS.7 D11).
///
/// Does not modify the Reflection aggregate with a Story foreign key.
/// Story context remains presentation/application only.
final class StartStoryReflectionRequest {
  const StartStoryReflectionRequest({
    required this.storyId,
    required this.journeyId,
    this.reflectionId,
  });

  final StoryId storyId;
  final JourneyId journeyId;
  final ReflectionId? reflectionId;
}
