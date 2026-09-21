import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';

final class SkipStoryBuilderPromptRequest {
  const SkipStoryBuilderPromptRequest({
    required this.sessionId,
    required this.responseId,
    required this.promptId,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderResponseId responseId;
  final StoryBuilderPromptId promptId;
}
