import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Presentation model for Story Experience (safe DTO projection).
final class StoryExperienceViewModel {
  const StoryExperienceViewModel({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.narrativeBody,
    required this.originalLanguage,
    required this.playables,
    this.heroDisplayName,
    this.primaryPlayable,
  });

  factory StoryExperienceViewModel.fromDetail(StoryExperienceDetail detail) {
    return StoryExperienceViewModel(
      storyId: detail.storyId,
      heroId: detail.heroId,
      heroDisplayName: detail.heroDisplayName,
      title: detail.title,
      narrativeBody: detail.narrativeBody,
      originalLanguage: detail.originalLanguage,
      playables: detail.playableRepresentations
          .map(PlayableRepresentationViewModel.fromDto)
          .toList(growable: false),
      primaryPlayable: detail.primaryPlayable == null
          ? null
          : PlayableRepresentationViewModel.fromDto(detail.primaryPlayable!),
    );
  }

  final StoryId storyId;
  final HeroId heroId;
  final String? heroDisplayName;
  final String title;
  final String narrativeBody;
  final LanguageCode originalLanguage;
  final List<PlayableRepresentationViewModel> playables;
  final PlayableRepresentationViewModel? primaryPlayable;
}

final class PlayableRepresentationViewModel {
  const PlayableRepresentationViewModel({
    required this.representationId,
    required this.formatLabel,
    required this.languageCode,
    required this.hasText,
    required this.hasMedia,
    this.textContent,
  });

  factory PlayableRepresentationViewModel.fromDto(
    PlayableRepresentation dto,
  ) {
    return PlayableRepresentationViewModel(
      representationId: dto.representationId,
      formatLabel: _formatLabel(dto.format),
      languageCode: dto.language.value,
      hasText: dto.hasText,
      hasMedia: dto.hasMedia,
      textContent: dto.textContent,
    );
  }

  final StoryRepresentationId representationId;
  final String formatLabel;
  final String languageCode;
  final bool hasText;
  final bool hasMedia;
  final String? textContent;

  static String _formatLabel(StoryRepresentationFormat format) {
    return switch (format) {
      StoryRepresentationFormat.audio => 'Audio',
      StoryRepresentationFormat.video => 'Video',
      StoryRepresentationFormat.written => 'Written',
      StoryRepresentationFormat.transcript => 'Transcript',
      StoryRepresentationFormat.script => 'Script',
      StoryRepresentationFormat.shortForm => 'Short form',
      StoryRepresentationFormat.longForm => 'Long form',
    };
  }
}
