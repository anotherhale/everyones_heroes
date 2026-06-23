import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'InMemoryReflectionRepository',
    () {
      late InMemoryReflectionRepository repository;

      setUp(() {
        repository =
            InMemoryReflectionRepository();
      });

      test(
        'save() stores reflection',
        () async {
          final reflection =
              Reflection.create(
            id: ReflectionId.generate(),
            journeyId:
                JourneyId.generate(),
          );

          await repository.save(
            reflection,
          );

          final result =
              await repository.findById(
            reflection.id,
          );

          expect(
            result,
            same(reflection),
          );
        },
      );

      test(
        'findById() returns null when missing',
        () async {
          final result =
              await repository.findById(
            ReflectionId.generate(),
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'exists() returns true when stored',
        () async {
          final reflection =
              Reflection.create(
            id: ReflectionId.generate(),
            journeyId:
                JourneyId.generate(),
          );

          await repository.save(
            reflection,
          );

          expect(
            await repository.exists(
              reflection.id,
            ),
            isTrue,
          );
        },
      );

      test(
        'exists() returns false when missing',
        () async {
          expect(
            await repository.exists(
              ReflectionId.generate(),
            ),
            isFalse,
          );
        },
      );

      test(
        'save() overwrites existing reflection',
        () async {
          final id =
              ReflectionId.generate();

          final original =
              Reflection.create(
            id: id,
            journeyId:
                JourneyId.generate(),
          );

          final replacement =
              Reflection.create(
            id: id,
            journeyId:
                JourneyId.generate(),
          );

          await repository.save(
            original,
          );

          await repository.save(
            replacement,
          );

          final result =
              await repository.findById(
            id,
          );

          expect(
            result,
            same(replacement),
          );
        },
      );

      test(
        'delete() removes reflection',
        () async {
          final reflection =
              Reflection.create(
            id: ReflectionId.generate(),
            journeyId:
                JourneyId.generate(),
          );

          await repository.save(
            reflection,
          );

          await repository.delete(
            reflection.id,
          );

          final result =
              await repository.findById(
            reflection.id,
          );

          expect(
            result,
            isNull,
          );
        },
      );
    },
  );
}