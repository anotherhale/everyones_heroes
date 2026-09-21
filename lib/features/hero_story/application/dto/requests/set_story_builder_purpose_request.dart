import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';

final class SetStoryBuilderPurposeRequest {
  const SetStoryBuilderPurposeRequest({
    required this.sessionId,
    this.purpose,
  });

  final StoryBuilderSessionId sessionId;

  /// `null` clears a previously selected purpose.
  final StoryBuilderPurpose? purpose;
}
