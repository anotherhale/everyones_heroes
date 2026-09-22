import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

final class CreateStoryRequest {
  const CreateStoryRequest({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.narrative,
    required this.originalLanguage,
    this.visibility = StoryVisibility.draft,
    this.originalSourceDescription,
    this.provenance,
  });

  final StoryId storyId;
  final HeroId heroId;
  final StoryTitle title;
  final StoryNarrative narrative;
  final LanguageCode originalLanguage;
  final StoryVisibility visibility;
  final String? originalSourceDescription;

  /// When set, takes precedence over [originalSourceDescription] (SB.13).
  final StoryProvenance? provenance;
}
