import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/begin_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/experience_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';

void main() {
  final journeyId = JourneyId.generate();

  final experience = TodayExperienceViewModel(
    id: 'test-experience',
    experienceType: ExperienceType.reflection,
    action: ExperienceAction.begin,
    title: 'Keep Showing Up',
    description: 'Take one small step today.',
    callToAction: 'Begin Experience',
    rationale: 'You have been building consistency.',
  );

  testWidgets('renders the experience details', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: ExperienceScreen(experience: experience)),
      ),
    );

    expect(find.text("Today's Experience"), findsOneWidget);
    expect(find.text('Keep Showing Up'), findsOneWidget);
    expect(find.text('Take one small step today.'), findsOneWidget);
    expect(find.text('You have been building consistency.'), findsOneWidget);
    expect(find.text('Begin Experience'), findsOneWidget);
  });

  testWidgets('begin experience creates reflection and navigates', (
    tester,
  ) async {
    final reflectionId = ReflectionId.generate();

    final fakeUseCase = _FakeBeginExperienceUseCase(
      result: Success(
        Reflection.create(id: reflectionId, journeyId: journeyId),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          beginExperienceUseCaseProvider.overrideWithValue(fakeUseCase),
        ],
        child: MaterialApp(home: ExperienceScreen(experience: experience)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
    await tester.pumpAndSettle();

    expect(fakeUseCase.executeCount, 1);
    expect(find.byType(ReflectScreen), findsOneWidget);
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
