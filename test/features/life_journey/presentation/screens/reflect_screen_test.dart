import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/add_reflection_response_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/submit_reflection_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/add_reflection_response_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/submit_reflection_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';

import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

void main() {
  group('ReflectScreen', () {
    late ReflectionId reflectionId;
    late _FakeAddReflectionResponseUseCase addResponseUseCase;
    late _FakeSubmitReflectionUseCase submitUseCase;

    setUp(() {
      reflectionId = ReflectionId.generate();
      addResponseUseCase = _FakeAddReflectionResponseUseCase();
      submitUseCase = _FakeSubmitReflectionUseCase();
    });

    Future<void> buildScreen(
      WidgetTester tester, {
      ReflectionId? id,
      Future<Result<Reflection>>? pendingReflection,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            addReflectionResponseUseCaseProvider.overrideWithValue(
              addResponseUseCase,
            ),
            submitReflectionUseCaseProvider.overrideWithValue(
              submitUseCase,
            ),
          ],
          child: MaterialApp(
            home: ReflectScreen(
              reflectionId: id,
              pendingReflection: pendingReflection,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('renders reflection choices', (tester) async {
      await buildScreen(tester, id: reflectionId);

      expect(find.text('Reflect'), findsOneWidget);
      expect(
        find.text('How are you feeling about your journey?'),
        findsOneWidget,
      );
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('Growing'), findsOneWidget);
      expect(find.text('Motivated'), findsOneWidget);
      expect(find.text('Peaceful'), findsOneWidget);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grateful'), findsOneWidget);
      expect(find.text('Save Reflection'), findsOneWidget);
    });

    testWidgets('save is disabled until a feeling is selected', (
      tester,
    ) async {
      await buildScreen(tester, id: reflectionId);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      final saveButton = find.byKey(
        const ValueKey('save-reflection'),
      );

      expect(saveButton, findsOneWidget);

      final button = tester.widget<FilledButton>(saveButton);

      expect(button.onPressed, isNull);
    });

    testWidgets('selecting a feeling enables save', (tester) async {
      await buildScreen(tester, id: reflectionId);

      await tester.tap(
        find.byKey(const ValueKey('feeling-growing')),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('save-reflection')),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('save adds response and submits reflection', (tester) async {
      await buildScreen(tester, id: reflectionId);

      await tester.tap(
        find.byKey(const ValueKey('feeling-growing')),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('save-reflection')),
      );
      await tester.pumpAndSettle();

      expect(addResponseUseCase.executed, isTrue);
      expect(addResponseUseCase.reflectionId, reflectionId);
      expect(addResponseUseCase.response, isA<EmojiResponse>());

      final response = addResponseUseCase.response! as EmojiResponse;

      expect(response.emotion, ReflectionEmotion.hopeful);

      expect(submitUseCase.executed, isTrue);
      expect(submitUseCase.reflectionId, reflectionId);

      // Reflect as MaterialApp home cannot pop — confirmation remains.
      expect(
        find.text('Reflection saved: Growing'),
        findsOneWidget,
      );
    });

    testWidgets('save does nothing without a reflection id', (tester) async {
      await buildScreen(tester);

      await tester.tap(
        find.byKey(const ValueKey('feeling-growing')),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('save-reflection')),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('pending reflection enables save after first frame', (
      tester,
    ) async {
      final pending = Future<Result<Reflection>>.value(
        Success(
          Reflection.create(
            id: reflectionId,
            journeyId: JourneyId.generate(),
          ),
        ),
      );

      await buildScreen(tester, pendingReflection: pending);

      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('feeling-growing')),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('save-reflection')),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('pushed Reflect shows AppBar back affordance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            addReflectionResponseUseCaseProvider.overrideWithValue(
              addResponseUseCase,
            ),
            submitReflectionUseCaseProvider.overrideWithValue(
              submitUseCase,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      key: const Key('open-reflect'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReflectScreen(
                              reflectionId: reflectionId,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-reflect')));
      await tester.pumpAndSettle();

      expect(find.byType(ReflectScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Reflect'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ReflectScreen), findsNothing);
      expect(find.byKey(const Key('open-reflect')), findsOneWidget);
    });

    testWidgets(
      'successful save pops to root and invalidates today experience',
      (tester) async {
        var todayExperienceBuilds = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              addReflectionResponseUseCaseProvider.overrideWithValue(
                addResponseUseCase,
              ),
              submitReflectionUseCaseProvider.overrideWithValue(
                submitUseCase,
              ),
              todayExperienceProvider.overrideWith((ref) async {
                todayExperienceBuilds++;
                return TodayExperienceViewModel(
                  id: 'experience-$todayExperienceBuilds',
                  experienceType: ExperienceType.reflection,
                  action: ExperienceAction.begin,
                  title: 'Keep Showing Up',
                  description: 'Take one small step today.',
                  callToAction: 'Begin Experience',
                );
              }),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  // Keep provider alive so invalidate is observable.
                  ref.watch(todayExperienceProvider);
                  return Scaffold(
                    key: const Key('home-root'),
                    body: Center(
                      child: FilledButton(
                        key: const Key('open-stack'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text("Today's Experience"),
                                ),
                                body: Center(
                                  child: FilledButton(
                                    key: const Key('open-reflect'),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ReflectScreen(
                                            reflectionId: reflectionId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Reflect'),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('Experience'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('open-stack')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-reflect')));
        await tester.pumpAndSettle();

        expect(find.byType(ReflectScreen), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('feeling-growing')),
        );
        await tester.pump();

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();

        final buildsBeforeSave = todayExperienceBuilds;

        await tester.tap(
          find.byKey(const ValueKey('save-reflection')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReflectScreen), findsNothing);
        expect(find.text("Today's Experience"), findsNothing);
        expect(find.byKey(const Key('home-root')), findsOneWidget);
        expect(submitUseCase.executed, isTrue);
        expect(todayExperienceBuilds, greaterThan(buildsBeforeSave));
      },
    );
  });
}

final class _FakeAddReflectionResponseUseCase
    implements AddReflectionResponseUseCase {
  bool executed = false;
  ReflectionId? reflectionId;
  dynamic response;

  @override
  Future<Result<Reflection>> execute({
    required ReflectionId reflectionId,
    required ReflectionResponse response,
  }) async {
    executed = true;
    this.reflectionId = reflectionId;
    this.response = response;

    final reflection = Reflection.create(
      id: reflectionId,
      journeyId: JourneyId.generate(),
    );

    return Success(reflection);
  }
}

final class _FakeSubmitReflectionUseCase
    implements SubmitReflectionUseCase {
  bool executed = false;
  ReflectionId? reflectionId;

  @override
  Future<Result<Reflection>> execute(
    SubmitReflectionRequest request,
  ) async {
    executed = true;
    reflectionId = request.reflectionId;

    final reflection = Reflection.create(
      id: request.reflectionId,
      journeyId: JourneyId.generate(),
    );

    return Success(reflection);
  }
}
