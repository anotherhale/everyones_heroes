import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';

final class EditStoryBuilderResponseRequest {
  const EditStoryBuilderResponseRequest({
    required this.sessionId,
    required this.responseId,
    required this.text,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderResponseId responseId;
  final String text;
}
