import 'package:everyonesheroes/features/life_journey/application/use_cases/create_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';

void main() {
  group('CreateReflectionUseCase', () {
    late InMemoryReflectionRepository repository;

    late CreateReflectionUseCase useCase;

    setUp(() {
      repository = InMemoryReflectionRepository();

      useCase = CreateReflectionUseCase(
        reflectionRepository: repository,
      );
    });

    test('creates reflection', () async {
      final result = await useCase.execute(
        CreateReflectionRequest(
          reflectionId: ReflectionId.generate(),
          journeyId: JourneyId.generate(),
        ),
      );

      expect(
        result,
        isA<Success<Reflection>>(),
      );
    });

    test('saves reflection', () async {
      final reflectionId =
          ReflectionId.generate();

      final result = await useCase.execute(
        CreateReflectionRequest(
          reflectionId: reflectionId,
          journeyId: JourneyId.generate(),
        ),
      );

      final reflection = result.fold(
        onSuccess: (value) => value,
        onFailure: (_) => null,
      );

      final stored =
          await repository.findById(
        reflection!.id,
      );

      expect(
        stored,
        same(reflection),
      );
    });

    test('returns created reflection', () async {
      final reflectionId =
          ReflectionId.generate();

      final result = await useCase.execute(
        CreateReflectionRequest(
          reflectionId: reflectionId,
          journeyId: JourneyId.generate(),
        ),
      );

      expect(
        result.fold(
          onSuccess: (value) => value.id,
          onFailure: (_) => null,
        ),
        reflectionId,
      );
    });

    test('returns failure on exception', () async {
      final badUseCase =
          CreateReflectionUseCase(
        reflectionRepository:
            _ThrowingReflectionRepository(),
      );

      final result =
          await badUseCase.execute(
        CreateReflectionRequest(
          reflectionId:
              ReflectionId.generate(),
          journeyId:
              JourneyId.generate(),
        ),
      );

      expect(
        result,
        isA<Failure<Reflection>>(),
      );
    });
  });
}

final class _ThrowingReflectionRepository
    implements ReflectionRepository {
  @override
  Future<void> delete(
    ReflectionId id,
  ) async {}

  @override
  Future<bool> exists(
    ReflectionId id,
  ) async =>
      false;

  @override
  Future<Reflection?> findById(
    ReflectionId id,
  ) async =>
      null;

  @override
  Future<void> save(
    Reflection reflection,
  ) async {
    throw Exception('boom');
  }
}