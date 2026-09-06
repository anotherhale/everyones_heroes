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
            home: ReflectScreen(reflectionId: id),
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
