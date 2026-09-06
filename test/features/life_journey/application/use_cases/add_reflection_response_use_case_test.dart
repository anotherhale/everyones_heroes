import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/add_reflection_response_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

void main() {
  group('DefaultAddReflectionResponseUseCase', () {
    late ReflectionRepository repository;
    late AddReflectionResponseUseCase useCase;
    late ReflectionId reflectionId;
    late Reflection reflection;

    setUp(() {
      repository = _FakeReflectionRepository();
      useCase = DefaultAddReflectionResponseUseCase(
        reflectionRepository: repository,
      );

      reflectionId = ReflectionId.generate();

      reflection = Reflection.create(
        id: reflectionId,
        journeyId: JourneyId.generate(),
      );

      repository.save(reflection);
    });

    test('adds response and persists reflection', () async {
      final response = EmojiResponse(emotion: ReflectionEmotion.proud);

      final result = await useCase.execute(
        reflectionId: reflectionId,
        response: response,
      );

      expect(result, isA<Success<Reflection>>());

      final saved = await repository.findById(reflectionId);

      expect(saved, isNotNull);
      expect(saved!.responses, hasLength(1));
      expect(saved.responses.single, same(response));
    });

    test('returns failure when reflection does not exist', () async {
      final missingId = ReflectionId.generate();

      final result = await useCase.execute(
        reflectionId: missingId,
        response: const EmojiResponse(emotion: ReflectionEmotion.grateful),
      );

      expect(result, isA<Failure<Reflection>>());

      final failure = result as Failure<Reflection>;
      expect(failure.error, contains('Reflection not found'));
    });

    test(
      'returns failure when reflection has already been submitted',
      () async {
        reflection.addResponse(
          const EmojiResponse(emotion: ReflectionEmotion.proud),
        );
        reflection.submit();
        await repository.save(reflection);

        final result = await useCase.execute(
          reflectionId: reflectionId,
          response: const EmojiResponse(emotion: ReflectionEmotion.hopeful),
        );

        expect(result, isA<Failure<Reflection>>());

        final failure = result as Failure<Reflection>;
        expect(failure.error, contains('Cannot modify a submitted reflection'));
      },
    );
  });
}

final class _FakeReflectionRepository implements ReflectionRepository {
  final Map<ReflectionId, Reflection> _reflections = {};

  @override
  Future<void> save(Reflection reflection) async {
    _reflections[reflection.id] = reflection;
  }

  @override
  Future<Reflection?> findById(ReflectionId id) async {
    return _reflections[id];
  }

  @override
  Future<List<Reflection>> findByJourneyId(JourneyId journeyId) async {
    return _reflections.values
        .where((reflection) => reflection.journeyId == journeyId)
        .toList();
  }

  @override
  Future<bool> exists(ReflectionId id) async {
    return _reflections.containsKey(id);
  }

  @override
  Future<void> delete(ReflectionId id) async {
    _reflections.remove(id);
  }
}
