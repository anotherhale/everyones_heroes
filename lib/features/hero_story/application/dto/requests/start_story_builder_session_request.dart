import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';

final class StartStoryBuilderSessionRequest {
  const StartStoryBuilderSessionRequest({
    required this.sessionId,
    required this.heroId,
    this.mode = StoryBuilderMode.guided,
    this.intent,
    this.storyId,
  });

  final StoryBuilderSessionId sessionId;
  final HeroId heroId;
  final StoryBuilderMode mode;
  final StoryBuilderIntent? intent;
  final StoryId? storyId;
}
