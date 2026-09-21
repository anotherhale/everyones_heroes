import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';

/// Presentation labels for Story Builder intent vocabulary (SB.6).
abstract final class StoryBuilderIntentLabels {
  static String purpose(StoryBuilderPurpose purpose) {
    return switch (purpose) {
      StoryBuilderPurpose.inspireSomeone => 'Inspire someone',
      StoryBuilderPurpose.encourageSomeone => 'Encourage someone',
      StoryBuilderPurpose.helpSomeoneFeelLessAlone =>
        'Help someone feel less alone',
      StoryBuilderPurpose.preserveAMemory => 'Preserve a memory',
      StoryBuilderPurpose.honorSomeone => 'Honor someone',
      StoryBuilderPurpose.shareALesson => 'Share a lesson',
      StoryBuilderPurpose.helpSomeoneFacingSomethingSimilar =>
        'Help someone facing something similar',
      StoryBuilderPurpose.simplyTellMyStory => 'Simply tell my story',
      StoryBuilderPurpose.notSureYet => 'Not sure yet',
    };
  }

  static String theme(StoryBuilderTheme theme) {
    return switch (theme) {
      StoryBuilderTheme.overcomingAdversity => 'Overcoming adversity',
      StoryBuilderTheme.courage => 'Courage',
      StoryBuilderTheme.service => 'Service',
      StoryBuilderTheme.leadership => 'Leadership',
      StoryBuilderTheme.loss => 'Loss',
      StoryBuilderTheme.failure => 'Failure',
      StoryBuilderTheme.transformation => 'Transformation',
      StoryBuilderTheme.perseverance => 'Perseverance',
      StoryBuilderTheme.secondChances => 'Second chances',
      StoryBuilderTheme.sacrifice => 'Sacrifice',
      StoryBuilderTheme.family => 'Family',
      StoryBuilderTheme.discovery => 'Discovery',
      StoryBuilderTheme.purpose => 'Purpose',
      StoryBuilderTheme.love => 'Love',
    };
  }
}
