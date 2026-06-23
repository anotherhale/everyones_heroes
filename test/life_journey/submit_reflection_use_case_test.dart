import 'package:everyonesheroes/features/life_journey/application/requests/submit_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/submit_reflection_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';

void main() {
  group('SubmitReflectionUseCase', () {
    late InMemoryReflectionRepository reflectionRepository;

    late InMemoryEventStore eventStore;

    late InMemoryEventDispatcher dispatcher;

    late InMemoryEventBus eventBus;

    late SubmitReflectionUseCase useCase;

    setUp(() {
      reflectionRepository = InMemoryReflectionRepository();

      eventStore = InMemoryEventStore();

      dispatcher = InMemoryEventDispatcher();

      eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );

      useCase = SubmitReflectionUseCase(
        reflectionRepository: reflectionRepository,
        eventBus: eventBus,
      );
    });

    test('submits reflection', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(
        const JournalResponse(text: 'Today I learned persistence.'),
      );

      await reflectionRepository.save(reflection);

      final result = await useCase.execute(
        SubmitReflectionRequest(reflectionId: reflection.id),
      );

      expect(result, isA<Success<Reflection>>());

      final saved = await reflectionRepository.findById(reflection.id);

      expect(saved, isNotNull);

      expect(saved!.isSubmitted, isTrue);

      expect(saved.submittedAt, isNotNull);
    });

    test('returns failure when reflection does not exist', () async {
      final result = await useCase.execute(
        SubmitReflectionRequest(reflectionId: ReflectionId.generate()),
      );

      expect(result, isA<Failure<Reflection>>());
    });

    test('publishes ReflectionSubmitted event', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(text: 'Reflection content'));

      await reflectionRepository.save(reflection);

      await useCase.execute(
        SubmitReflectionRequest(reflectionId: reflection.id),
      );

      final events = await eventStore.allEvents();

      expect(events.length, 1);

      expect(events.first.event, isA<ReflectionSubmitted>());
    });

    test('fails when reflection has no responses', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      await reflectionRepository.save(reflection);

      final result = await useCase.execute(
        SubmitReflectionRequest(reflectionId: reflection.id),
      );

      expect(result, isA<Failure<Reflection>>());
    });

    test('clears domain events after publish', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(text: 'Test'));

      await reflectionRepository.save(reflection);

      await useCase.execute(
        SubmitReflectionRequest(reflectionId: reflection.id),
      );

      expect(reflection.domainEvents, isEmpty);
    });

    test('cannot submit already submitted reflection', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(text: 'Test'));

      reflection.submit();

      reflection.clearDomainEvents();

      await reflectionRepository.save(reflection);

      final result = await useCase.execute(
        SubmitReflectionRequest(reflectionId: reflection.id),
      );

      expect(result, isA<Failure<Reflection>>());
    });
  });
}
