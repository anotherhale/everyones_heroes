import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/begin_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/home_screen.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';

void main() {
  TodayExperienceViewModel experience({
    String title = 'Keep Showing Up',
    String description = 'Take one small step today to strengthen the consistency you have already been building.',
    String callToAction = 'Begin Experience',
    String? rationale =
        'You have been building consistency across your recent journey.',
  }) {
    return TodayExperienceViewModel(
      id: 'consistency-next-step',
      experienceType: ExperienceType.mission,
      action: ExperienceAction.begin,
      title: title,
      description: description,
      callToAction: callToAction,
      rationale: rationale,
    );
  }

  Widget buildHome({AsyncValue<TodayExperienceViewModel>? todayExperience}) {
    return ProviderScope(
      overrides: [
        todayExperienceProvider.overrideWith(
          (ref) async =>
              (todayExperience ?? AsyncValue.data(experience())).requireValue,
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders the application-backed today experience', (
      tester,
    ) async {
      await tester.pumpWidget(buildHome());
      await tester.pump();

      expect(find.text('Good morning.'), findsOneWidget);
      expect(
        find.text(
          "You don't have to change everything today.\n"
          'Just take the next step.',
        ),
        findsOneWidget,
      );
      expect(find.text("TODAY'S EXPERIENCE"), findsOneWidget);
      expect(find.text('Keep Showing Up'), findsOneWidget);
      expect(
        find.text(
          'Take one small step today to strengthen the consistency '
          'you have already been building.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'You have been building consistency across your recent journey.',
        ),
        findsOneWidget,
      );
      expect(find.text('Begin Experience'), findsOneWidget);
    });

    testWidgets('today experience opens experience detail', (tester) async {
      final reflectionId = ReflectionId.generate();
      final journeyId = JourneyId.generate();

      final fakeUseCase = _FakeBeginExperienceUseCase(
        result: Success(
          Reflection.create(id: reflectionId, journeyId: journeyId),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayExperienceProvider.overrideWith((ref) async => experience()),
            beginExperienceUseCaseProvider.overrideWithValue(fakeUseCase),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('today-experience-begin')));
      await tester.pumpAndSettle();

      expect(find.text("Today's Experience"), findsOneWidget);
      expect(find.text('Keep Showing Up'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('begin-experience-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders journey, discovery, and reflection entry points', (
      tester,
    ) async {
      await tester.pumpWidget(buildHome());
      await tester.pump();

      expect(find.text('YOUR JOURNEY'), findsOneWidget);
      expect(find.text('Continue your journey'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('DISCOVER'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.text('Learn something about yourself'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('REFLECT'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('REFLECT'), findsOneWidget);
      expect(find.text('Reflect on an experience'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        buildHome(todayExperience: const AsyncValue.loading()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        buildHome(
          todayExperience: AsyncValue.error(
            Exception('Unable to load experience'),
            StackTrace.current,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text("Today's experience isn't available right now."),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('does not require domain pattern details', (tester) async {
      await tester.pumpWidget(
        buildHome(
          todayExperience: AsyncValue.data(
            experience(
              title: 'Take the Next Step',
              description: 'Reflect on what matters most right now.',
              callToAction: 'Reflect',
              rationale: null,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Take the Next Step'), findsOneWidget);
      expect(
        find.text('Reflect on what matters most right now.'),
        findsOneWidget,
      );
      expect(find.text('Reflect'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('today-experience-rationale')),
        findsNothing,
      );
    });
  });
}

final class _FakeBeginExperienceUseCase implements BeginExperienceUseCase {
  _FakeBeginExperienceUseCase({required this.result});

  final Result<Reflection> result;

  @override
  Future<Result<Reflection>> execute({required ExperienceAction action}) async {
    return result;
  }
}
