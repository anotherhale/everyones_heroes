import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

final class PresentStoryBuilderPromptRequest {
  const PresentStoryBuilderPromptRequest({
    required this.sessionId,
    required this.prompt,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderPrompt prompt;
}
