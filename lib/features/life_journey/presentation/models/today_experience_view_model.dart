import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';

final class TodayExperienceViewModel {
  const TodayExperienceViewModel({
    required this.id,
    required this.experienceType,
    required this.title,
    required this.description,
    required this.action,
    required this.callToAction,
    this.rationale,
    this.storyTargetId,
  });

  final String id;
  final ExperienceType experienceType;
  final String title;
  final String description;
  final ExperienceAction action;
  final String callToAction;
  final String? rationale;

  /// Story id string when [experienceType] is [ExperienceType.story].
  final String? storyTargetId;

  static String _callToActionFor(ExperienceAction action) {
    return switch (action) {
      ExperienceAction.begin => 'Begin Experience',
    };
  }

  factory TodayExperienceViewModel.fromExperience(
    AdaptiveExperience experience,
  ) {
    final target = experience.target;
    final storyTargetId = switch (target) {
      StoryExperienceTarget(:final storyId) => storyId.value,
      null => null,
    };

    return TodayExperienceViewModel(
      id: experience.id,
      experienceType: experience.type,
      title: experience.title,
      description: experience.description,
      action: experience.action,
      callToAction: _callToActionFor(experience.action),
      rationale: experience.rationale,
      storyTargetId: storyTargetId,
    );
  }
}
