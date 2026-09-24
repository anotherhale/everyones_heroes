import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Application response for [GenerateStoryExperiencePlanUseCase] (HS.12.4).
final class GenerateStoryExperiencePlanResponse {
  const GenerateStoryExperiencePlanResponse({
    required this.plan,
    this.idempotentReplay = false,
  });

  final StoryExperiencePlan plan;
  final bool idempotentReplay;
}
