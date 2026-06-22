import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Journey createJourney({JourneyId? id, String vision = 'Become healthier'}) {
  return Journey.create(
    id: id ?? JourneyId.generate(),
    vision: JourneyVision(vision),
  );
}

Journey createUpdatedJourney(JourneyId id) {
  return Journey(
    id: id,
    vision: JourneyVision('Updated'),
    currentChapter: JourneyChapter.commitment,
  );
}

void main() {
  group('InMemoryJourneyRepository', () {
    late InMemoryJourneyRepository repository;

    setUp(() {
      repository = InMemoryJourneyRepository();
    });

    Journey createJourney({JourneyId? id, String vision = 'Become healthier'}) {
      return Journey.create(
        id: id ?? JourneyId.generate(),
        vision: JourneyVision(vision),
      );
    }

    group('save()', () {
      test('saves a journey', () async {
        final journey = createJourney();

        await repository.save(journey);

        final result = await repository.findById(journey.id);

        expect(result, isNotNull);
        expect(result!.id, equals(journey.id));
      });

      test('saves multiple journeys', () async {
        final journey1 = createJourney();
        final journey2 = createJourney();

        await repository.save(journey1);
        await repository.save(journey2);

        expect(await repository.findById(journey1.id), isNotNull);

        expect(await repository.findById(journey2.id), isNotNull);
      });
      test('overwrites existing journey with same id', () async {
        final id = JourneyId.generate();

        await repository.save(createJourney(id: id));

        await repository.save(createUpdatedJourney(id));

        final result = await repository.findById(id);

        expect(result, isNotNull);
        expect(result!.currentChapter, JourneyChapter.commitment);
      });
    });

    group('findById()', () {
      test('returns saved journey', () async {
        final journey = createJourney();

        await repository.save(journey);

        final result = await repository.findById(journey.id);

        expect(result, isNotNull);
        expect(result!.id, equals(journey.id));
      });

      test('returns overwritten journey', () async {
        final id = JourneyId.generate();

        await repository.save(
          Journey.create(id: id, vision: JourneyVision('Original')),
        );

        await repository.save(
          Journey(
            id: id,
            vision: JourneyVision('Become a stronger leader'),
            currentChapter: JourneyChapter.commitment,
          ),
        );

        final result = await repository.findById(id);

        expect(result, isNotNull);
        expect(result!.currentChapter, JourneyChapter.commitment);
      });

      test('returns null when journey does not exist', () async {
        final result = await repository.findById(JourneyId.generate());

        expect(result, isNull);
      });
    });

    group('exists()', () {
      test('returns true when journey exists', () async {
        final journey = createJourney();

        await repository.save(journey);

        expect(await repository.exists(journey.id), isTrue);
      });

      test('returns false when journey does not exist', () async {
        expect(await repository.exists(JourneyId.generate()), isFalse);
      });

      test('returns false after deletion', () async {
        final journey = createJourney();

        await repository.save(journey);

        await repository.delete(journey.id);

        expect(await repository.exists(journey.id), isFalse);
      });
    });

    group('delete()', () {
      test('deletes existing journey', () async {
        final journey = createJourney();

        await repository.save(journey);

        await repository.delete(journey.id);

        final result = await repository.findById(journey.id);

        expect(result, isNull);
      });

      test('deleting missing journey does not throw', () async {
        expect(repository.delete(JourneyId.generate()), completes);
      });

      test('only removes specified journey', () async {
        final journey1 = createJourney();
        final journey2 = createJourney();

        await repository.save(journey1);
        await repository.save(journey2);

        await repository.delete(journey1.id);

        expect(await repository.findById(journey1.id), isNull);

        expect(await repository.findById(journey2.id), isNotNull);
      });
    });

    group('repository lifecycle', () {
      test('save then findById', () async {
        final journey = createJourney();

        await repository.save(journey);

        final result = await repository.findById(journey.id);

        expect(result, isNotNull);
        expect(result!.id, equals(journey.id));
      });

      test('save then exists', () async {
        final journey = createJourney();

        await repository.save(journey);

        expect(await repository.exists(journey.id), isTrue);
      });

      test('save then delete', () async {
        final journey = createJourney();

        await repository.save(journey);

        await repository.delete(journey.id);

        expect(await repository.findById(journey.id), isNull);
      });

      test('save multiple then retrieve independently', () async {
        final journey1 = createJourney();
        final journey2 = createJourney();

        await repository.save(journey1);
        await repository.save(journey2);

        final result1 = await repository.findById(journey1.id);

        final result2 = await repository.findById(journey2.id);

        expect(result1, isNotNull);
        expect(result2, isNotNull);

        expect(result1!.id, equals(journey1.id));

        expect(result2!.id, equals(journey2.id));
      });
    });
  });
}
