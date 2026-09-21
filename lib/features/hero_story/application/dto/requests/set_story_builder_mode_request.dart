import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';

/// Explicit mode change request (SB.7 AI failure → Guided recovery).
final class SetStoryBuilderModeRequest {
  const SetStoryBuilderModeRequest({
    required this.sessionId,
    required this.mode,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderMode mode;
}
