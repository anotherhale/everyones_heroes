import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';

final class AnswerStoryBuilderPromptRequest {
  const AnswerStoryBuilderPromptRequest({
    required this.sessionId,
    required this.responseId,
    required this.promptId,
    required this.text,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderResponseId responseId;
  final StoryBuilderPromptId promptId;
  final String text;
}
