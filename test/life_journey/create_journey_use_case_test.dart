import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/contexts/life_journey/application/create_journey_request.dart';
import 'package:everyonesheroes/contexts/life_journey/application/create_journey_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

void main() {
  group('CreateJourneyUseCase', () {
    late InMemoryJourneyRepository repository;

    late InMemoryEventStore eventStore;
    late InMemoryEventDispatcher dispatcher;
    late InMemoryEventBus eventBus;

    late CreateJourneyUseCase useCase;

    setUp(() {
      repository = InMemoryJourneyRepository();

      eventStore = InMemoryEventStore();
      dispatcher = InMemoryEventDispatcher();

      eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );

      useCase = CreateJourneyUseCase(
        journeyRepository: repository,
        eventBus: eventBus,
      );
    });

    test('creates journey', () async {
      final result = await useCase.execute(
        CreateJourneyRequest(
          journeyId: JourneyId.generate(),
          vision: JourneyVision('Become healthier'),
        ),
      );

      expect(result, isA<Success<Journey>>());
    });

    test('saves journey', () async {
      final journeyId = JourneyId.generate();

      await useCase.execute(
        CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Become healthier'),
        ),
      );

      final journey = await repository.findById(journeyId);

      expect(journey, isNotNull);
    });

    test('returns created journey', () async {
      final journeyId = JourneyId.generate();

      final result = await useCase.execute(
        CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Become healthier'),
        ),
      );

      result.fold(
        onSuccess: (journey) {
          expect(journey.id, journeyId);
        },
        onFailure: fail,
      );
    });

    test('starts in awakening chapter', () async {
      final result = await useCase.execute(
        CreateJourneyRequest(
          journeyId: JourneyId.generate(),
          vision: JourneyVision('Become healthier'),
        ),
      );

      result.fold(
        onSuccess: (journey) {
          expect(journey.currentChapter, JourneyChapter.awakening);
        },
        onFailure: fail,
      );
    });

    test('publishes JourneyCreated event', () async {
      await useCase.execute(
        CreateJourneyRequest(
          journeyId: JourneyId.generate(),
          vision: JourneyVision('Become healthier'),
        ),
      );

      final envelopes = await eventStore.allEvents();

      expect(envelopes.length, 1);

      expect(envelopes.single.event, isA<JourneyCreated>());
    });
  });
}
