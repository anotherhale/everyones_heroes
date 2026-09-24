import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/just_audio_story_experience_player.dart';

/// Production Story Experience player factory. Tests override with a fake.
final storyExperiencePlayerFactoryProvider =
    Provider<StoryExperiencePlayerFactory>((ref) {
  return const JustAudioStoryExperiencePlayerFactory();
});
