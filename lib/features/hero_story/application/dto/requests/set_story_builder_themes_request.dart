import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';

final class SetStoryBuilderThemesRequest {
  const SetStoryBuilderThemesRequest({
    required this.sessionId,
    this.themes = const [],
    this.themesUnsure = false,
  });

  final StoryBuilderSessionId sessionId;
  final List<StoryBuilderTheme> themes;
  final bool themesUnsure;
}
