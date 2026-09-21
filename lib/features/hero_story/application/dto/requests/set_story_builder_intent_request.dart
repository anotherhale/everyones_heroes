import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';

final class SetStoryBuilderIntentRequest {
  const SetStoryBuilderIntentRequest({
    required this.sessionId,
    required this.intent,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderIntent intent;
}
