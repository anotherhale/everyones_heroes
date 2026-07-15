import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/application/dto/requests/analyze_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/insights_generated.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';

import '../fakes/life_journey/fake_behavioral_evidence_analyzer.dart';
import '../fakes/life_journey/fake_insight_extraction_service.dart';
import '../fakes/life_journey/fake_narrative_theme_resolver.dart';

void main() {
  group('AnalyzeReflectionUseCase', () {
    late InMemoryReflectionRepository reflectionRepository;

    late InMemoryEventStore eventStore;

    late AnalyzeReflectionUseCase useCase;

    setUp(() {
      reflectionRepository = InMemoryReflectionRepository();

      eventStore = InMemoryEventStore();

      useCase = AnalyzeReflectionUseCase(
        reflectionRepository: reflectionRepository,
        insightExtractionService: const FakeInsightExtractionService(),
        behavioralEvidenceAnalyzer: const FakeBehavioralEvidenceAnalyzer(),
        narrativeThemeResolver: const FakeNarrativeThemeResolver(),
        eventBus: InMemoryEventBus(
          eventStore: eventStore,
          dispatcher: InMemoryEventDispatcher(),
        ),
      );
    });

    test('analyzes reflection', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(
        const JournalResponse(
          response: 'I kept going even when it was difficult.',
        ),
      );

      reflection.submit();

      reflection.pullDomainEvents();

      await reflectionRepository.save(reflection);

      final result = await useCase.execute(
        AnalyzeReflectionRequest(reflectionId: reflection.id),
      );

      expect(result, isA<Success<Reflection>>());

      final saved = await reflectionRepository.findById(reflection.id);

      expect(saved!.insights, isNotEmpty);

      expect(saved.behavioralEvidence, isNotEmpty);

      expect(saved.narrativeThemes, isNotEmpty);
    });

    test('returns failure when reflection does not exist', () async {
      final result = await useCase.execute(
        AnalyzeReflectionRequest(reflectionId: ReflectionId.generate()),
      );

      expect(result, isA<Failure<Reflection>>());
    });

    test('publishes InsightsGenerated event', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(response: 'Test'));

      reflection.submit();

      reflection.pullDomainEvents();

      await reflectionRepository.save(reflection);

      await useCase.execute(
        AnalyzeReflectionRequest(reflectionId: reflection.id),
      );

      final events = await eventStore.allEvents();

      expect(events.any((e) => e.event is InsightsGenerated), isTrue);
    });

    test('publishes BehavioralEvidenceDetected event', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(response: 'Test'));

      reflection.submit();

      reflection.pullDomainEvents();

      await reflectionRepository.save(reflection);

      await useCase.execute(
        AnalyzeReflectionRequest(reflectionId: reflection.id),
      );

      final events = await eventStore.allEvents();

      expect(events.any((e) => e.event is BehavioralEvidenceDetected), isTrue);
    });

    test('clears domain events after publish', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(response: 'Test'));

      reflection.submit();

      reflection.pullDomainEvents();

      await reflectionRepository.save(reflection);

      await useCase.execute(
        AnalyzeReflectionRequest(reflectionId: reflection.id),
      );

      expect(reflection.pullDomainEvents(), isEmpty);
    });
  });
}
