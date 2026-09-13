import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_detail_screen.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/begin_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/experience_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

void main() {
  final journeyId = JourneyId.generate();

  group('ExperienceScreen HS.8 story routing', () {
    testWidgets(
      'story experience opens HS.7 StoryDetailScreen without BeginExperience',
      (tester) async {
        final fakeBegin = _FakeBeginExperienceUseCase(
          result: Success(
            Reflection.create(
              id: ReflectionId.generate(),
              journeyId: journeyId,
            ),
          ),
        );

        final experience = TodayExperienceViewModel(
          id: 'adaptive-story-story-1',
          experienceType: ExperienceType.story,
          action: ExperienceAction.begin,
          title: 'Courage Under Fire',
          description: 'A story that connects with themes.',
          callToAction: 'Begin Experience',
          rationale:
              'This story connects with themes you\'ve recently reflected on.',
          storyTargetId: 'story-1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              beginExperienceUseCaseProvider.overrideWithValue(fakeBegin),
            ],
            child: MaterialApp(
              home: ExperienceScreen(experience: experience),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
        await tester.pumpAndSettle();

        expect(fakeBegin.executeCount, 0);
        expect(find.byType(StoryDetailScreen), findsOneWidget);
        expect(find.byType(ReflectScreen), findsNothing);
      },
    );

    testWidgets('reflection experience still uses BeginExperienceUseCase', (
      tester,
    ) async {
      final reflectionId = ReflectionId.generate();
      final fakeBegin = _FakeBeginExperienceUseCase(
        result: Success(
          Reflection.create(id: reflectionId, journeyId: journeyId),
        ),
      );

      final experience = TodayExperienceViewModel(
        id: 'default-reflection',
        experienceType: ExperienceType.reflection,
        action: ExperienceAction.begin,
        title: 'Take the Next Step',
        description: 'Reflect.',
        callToAction: 'Begin Experience',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            beginExperienceUseCaseProvider.overrideWithValue(fakeBegin),
          ],
          child: MaterialApp(home: ExperienceScreen(experience: experience)),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
      await tester.pumpAndSettle();

      expect(fakeBegin.executeCount, 1);
      expect(find.byType(ReflectScreen), findsOneWidget);
    });
  });
}

final class _FakeBeginExperienceUseCase implements BeginExperienceUseCase {
  _FakeBeginExperienceUseCase({required this.result});

  final Result<Reflection> result;
  int executeCount = 0;

  @override
  Future<Result<Reflection>> execute({required ExperienceAction action}) async {
    executeCount++;
    return result;
  }
}
