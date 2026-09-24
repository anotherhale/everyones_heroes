import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/hero_monogram.dart';

/// What Hero Story shows from the persisted Story and Hero profile.
final class HeroStoryViewData {
  const HeroStoryViewData({
    required this.heroName,
    required this.monogram,
    required this.title,
    this.originalRecordingId,
  });

  final String heroName;
  final String monogram;
  final String title;
  final StoryRepresentationId? originalRecordingId;

  factory HeroStoryViewData.fromHeroAndTitle({
    required String heroName,
    required String title,
    StoryRepresentationId? originalRecordingId,
  }) {
    return HeroStoryViewData(
      heroName: heroName,
      monogram: heroMonogram(heroName),
      title: title,
      originalRecordingId: originalRecordingId,
    );
  }
}
