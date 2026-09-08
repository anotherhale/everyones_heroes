import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_journey_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart';

import '../features/life_journey/builders/behavioral_evidence_builder.dart';

final class TestEventBus implements EventBus {
  final List<DomainEvent> publishedEvents = [];

  @override
  Future<void> publish(DomainEvent event) async {
    publishedEvents.add(event);
  }
}

void main() {
  late InMemoryJourneyRepository journeyRepository;
  late InMemoryReflectionRepository reflectionRepository;
  late CurrentJourneyContext currentJourneyContext;

  late CreateJourneyUseCase createJourneyUseCase;
  late DetectPatternUseCase detectPatternUseCase;
  late GetTodayExperienceUseCase getTodayExperienceUseCase;

  setUp(() {
    journeyRepository = InMemoryJourneyRepository();
    reflectionRepository = InMemoryReflectionRepository();
    currentJourneyContext = DefaultCurrentJourneyContext();

    final eventBus = TestEventBus();

    createJourneyUseCase = CreateJourneyUseCase(
      journeyRepository: journeyRepository,
      eventBus: eventBus,
    );

    detectPatternUseCase = DefaultDetectPatternUseCase(
      journeyRepository: journeyRepository,
      reflectionRepository: reflectionRepository,
      detector: RuleBasedPatternDetector(
        rules: [
          const ConsistencyPatternRule(),
        ],
      ),
      eventBus: eventBus,
    );

    getTodayExperienceUseCase = DefaultGetTodayExperienceUseCase(
      journeyRepository: journeyRepository,
      currentJourneyContext: currentJourneyContext,
      experienceSelectionService:
          const DeterministicExperienceSelectionService(),
    );
  });

  test(
    'Slice 4: updated understanding changes today experience',
    () async {
      final journeyId = JourneyId.generate();

      final createResult = await createJourneyUseCase.execute(
        CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision(
            'Become the person I want to be.',
          ),
        ),
      );

      final journey = createResult.fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      currentJourneyContext.setCurrentJourney(journey.id);

      final initialResult = await getTodayExperienceUseCase.execute();

      final initialExperience = initialResult.fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(initialExperience.id, 'default-reflection');
      expect(initialExperience.type, ExperienceType.reflection);

      final reflectionIds = List.generate(
        3,
        (_) => ReflectionId.generate(),
      );

      final observationDates = [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 3),
      ];

      for (var i = 0; i < reflectionIds.length; i++) {
        final reflection = Reflection.create(
          id: reflectionIds[i],
          journeyId: journeyId,
        );

        reflection.addResponse(
          const JournalResponse(
            response: 'I showed up and followed through.',
          ),
        );

        reflection.submit();

        reflection.addBehavioralEvidence([
          BehavioralEvidenceBuilder()
              .withType(BehavioralEvidenceType.discipline)
              .observedAt(observationDates[i])
              .fromSource(
                ReflectionEvidenceSource(
                  reflectionId: reflectionIds[i],
                ),
              )
              .build(),
        ]);

        await reflectionRepository.save(reflection);
      }

      final patternResult = await detectPatternUseCase.execute(journeyId);

      final patterns = patternResult.fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(patterns, hasLength(1));
      expect(
        patterns.single.type,
        BehaviorPatternType.consistency,
      );

      final updatedJourney = await journeyRepository.findById(journeyId);

      expect(updatedJourney, isNotNull);
      expect(updatedJourney!.behaviorPatterns, hasLength(1));
      expect(
        updatedJourney.behaviorPatterns.single.type,
        BehaviorPatternType.consistency,
      );

      final updatedResult = await getTodayExperienceUseCase.execute();

      final updatedExperience = updatedResult.fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(updatedExperience.id, 'consistency-next-step');
      expect(updatedExperience.type, ExperienceType.reflection);
      expect(updatedExperience.title, 'Keep Showing Up');
      expect(updatedExperience.action, ExperienceAction.begin);
      expect(
        updatedExperience.rationale,
        'You have been building consistency across your recent journey.',
      );
    },
  );
}
