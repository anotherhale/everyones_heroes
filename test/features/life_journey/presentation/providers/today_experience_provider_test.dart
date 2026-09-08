import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/get_today_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';

void main() {

  group('todayExperienceProvider', () {
    test('emits experience view model when use case succeeds', () async {
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

      final fakeUseCase =
          _FakeGetTodayExperienceUseCase(Success(experience));

      final container = ProviderContainer(
        overrides: [
          getTodayExperienceUseCaseProvider.overrideWithValue(fakeUseCase),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(
        todayExperienceProvider.future,
      );

      expect(result, isA<TodayExperienceViewModel>());
      expect(result.id, 'consistency-next-step');
      expect(result.experienceType, ExperienceType.reflection);
      expect(result.title, 'Keep Showing Up');
      expect(result.callToAction, 'Begin Experience');
      expect(
        result.rationale,
        'You have been building consistency across your recent journey.',
      );
      expect(fakeUseCase.executeCount, 1);
    });

    test('does not require a journey id from the presentation layer', () async {
      const experience = AdaptiveExperience(
        id: 'default-reflection',
        type: ExperienceType.reflection,
        title: 'Take the Next Step',
        description:
            'Take a moment to reflect on where you are and what matters '
            'most right now.',
        action: ExperienceAction.begin,
      );

      final fakeUseCase =
          _FakeGetTodayExperienceUseCase(Success(experience));

      final container = ProviderContainer(
        overrides: [
          getTodayExperienceUseCaseProvider.overrideWithValue(fakeUseCase),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(
        todayExperienceProvider.future,
      );

      expect(result.id, 'default-reflection');
      expect(result.experienceType, ExperienceType.reflection);
      expect(fakeUseCase.executeCount, 1);
    });
  });
}

final class _FakeGetTodayExperienceUseCase
    implements GetTodayExperienceUseCase {
  _FakeGetTodayExperienceUseCase(this.result);

  final Result<AdaptiveExperience> result;
  int executeCount = 0;

  @override
  Future<Result<AdaptiveExperience>> execute() async {
    executeCount++;
    return result;
  }
}
