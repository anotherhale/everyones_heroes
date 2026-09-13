import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodayExperienceViewModel', () {
    test('maps an adaptive experience into presentation state', () {
      const experience = AdaptiveExperience(
        id: 'consistency-next-step',
        type: ExperienceType.reflection,
        title: 'Keep Showing Up',
        description:
            'Take one small step today to strengthen the consistency '
            'you have already been building.',
        action: ExperienceAction.begin,
        rationale:
            'You have been building consistency across your recent journey.',
      );

      final viewModel =
          TodayExperienceViewModel.fromExperience(experience);

      expect(viewModel.id, 'consistency-next-step');
      expect(viewModel.experienceType, ExperienceType.reflection);
      expect(viewModel.title, 'Keep Showing Up');
      expect(
        viewModel.description,
        'Take one small step today to strengthen the consistency '
        'you have already been building.',
      );
      expect(viewModel.callToAction, 'Begin Experience');
      expect(
        viewModel.rationale,
        'You have been building consistency across your recent journey.',
      );
      expect(viewModel.storyTargetId, isNull);
    });

    test('preserves an absent rationale', () {
      const experience = AdaptiveExperience(
        id: 'default-reflection',
        type: ExperienceType.reflection,
        title: 'Take the Next Step',
        description:
            'Take a moment to reflect on where you are and what matters '
            'most right now.',
        action: ExperienceAction.begin,
      );

      final viewModel =
          TodayExperienceViewModel.fromExperience(experience);

      expect(viewModel.rationale, isNull);
    });

    test('maps story experience target id for HS.8 routing', () {
      final storyId = StoryId('story-adaptive-1');
      final experience = AdaptiveExperience(
        id: 'adaptive-story-${storyId.value}',
        type: ExperienceType.story,
        title: 'A Relevant Story',
        description: 'A story that connects with themes.',
        action: ExperienceAction.begin,
        rationale:
            'This story connects with themes you\'ve recently reflected on.',
        target: StoryExperienceTarget(storyId: storyId),
      );

      final viewModel =
          TodayExperienceViewModel.fromExperience(experience);

      expect(viewModel.experienceType, ExperienceType.story);
      expect(viewModel.storyTargetId, 'story-adaptive-1');
      expect(viewModel.rationale, isNotNull);
    });
  });
}
