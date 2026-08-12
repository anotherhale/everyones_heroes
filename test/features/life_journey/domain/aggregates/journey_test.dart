import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/behavior_patterns_detected.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  final vision = JourneyVision('Become healthy enough to hike with my family');

  Journey createJourney() {
    return Journey.create(
      id: JourneyId.generate(),
      vision: JourneyVision('Become healthy enough to hike with my family'),
    );
  }

  group('Journey Creation', () {
    test('creates journey', () {
      final journey = createJourney();

      expect(
        journey.vision,
        JourneyVision('Become healthy enough to hike with my family'),
      );
    });

    test('starts in awakening', () {
      expect(createJourney().currentChapter, JourneyChapter.awakening);
    });

    test('raises JourneyCreated', () {
      final journey = createJourney();

      final events = journey.pullDomainEvents();
      expectEventRaised<JourneyCreated>(events);
      expectEventCount(events, 1);
    });
  });

  group('Quest Management', () {
    test('attach quest', () {
      final journey = createJourney();

      final questId = QuestId.generate();

      journey.attachQuest(questId);

      expect(journey.hasQuest(questId), isTrue);
    });

    test('cannot attach duplicate quest', () {
      final journey = createJourney();

      final questId = QuestId.generate();

      journey.attachQuest(questId);

      expect(() => journey.attachQuest(questId), throwsStateError);
    });
  });

  group('Chapter Progression', () {
    test('awakening to commitment', () {
      final journey = createJourney();

      journey.advanceChapter(JourneyChapter.commitment);

      expect(journey.currentChapter, JourneyChapter.commitment);
    });

    test('raises ChapterAdvanced', () {
      final journey = createJourney();
      journey.pullDomainEvents();
      journey.advanceChapter(JourneyChapter.commitment);
      final events = journey.pullDomainEvents();
      expectEventRaised<ChapterAdvanced>(events);
      expectEventCount(events, 1);
    });

    test('cannot skip chapter', () {
      final journey = createJourney();

      expect(
        () => journey.advanceChapter(JourneyChapter.resistance),
        throwsStateError,
      );
    });

    test('cannot regress chapter', () {
      final journey = createJourney();

      journey.advanceChapter(JourneyChapter.commitment);

      expect(
        () => journey.advanceChapter(JourneyChapter.awakening),
        throwsStateError,
      );
    });
  });

  group('Journey Completion', () {
    test('is complete at contribution', () {
      final journey = createJourney();

      journey.advanceChapter(JourneyChapter.commitment);

      journey.advanceChapter(JourneyChapter.resistance);

      journey.advanceChapter(JourneyChapter.momentum);

      journey.advanceChapter(JourneyChapter.transformation);

      journey.advanceChapter(JourneyChapter.contribution);

      expect(journey.isComplete, isTrue);
    });
  });
  group('Behavior Pattern Management', () {
    test('adds detected behavior patterns', () {
      final journey = Journey(id: JourneyId.generate(), vision: vision);

      final pattern = createBehaviorPattern();

      journey.updateBehaviorPatterns([pattern]);

      expect(journey.behaviorPatterns, equals([pattern]));
    });

    test('raises BehaviorPatternsDetected when patterns change', () {
      final journeyId = JourneyId.generate();

      final journey = Journey(id: journeyId, vision: vision);

      final pattern = createBehaviorPattern();

      journey.updateBehaviorPatterns([pattern]);

      final events = journey.pullDomainEvents();

      final event = events.whereType<BehaviorPatternsDetected>().single;

      expect(event.aggregateId, equals(journeyId));
      expect(event.patterns, equals([pattern]));
    });

    test(
      'does not raise BehaviorPatternsDetected when patterns do not change',
      () {
        final pattern = createBehaviorPattern();

        final journey = Journey(
          id: JourneyId.generate(),
          vision: vision,
          behaviorPatterns: [pattern],
        );

        journey.updateBehaviorPatterns([pattern]);

        final events = journey.pullDomainEvents();

        expect(events.whereType<BehaviorPatternsDetected>(), isEmpty);
      },
    );

    test('replaces existing patterns when patterns change', () {
      final existingPattern = createBehaviorPattern();

      final newPattern = createBehaviorPattern(
        type: BehaviorPatternType.leadership,
      );

      final journey = Journey(
        id: JourneyId.generate(),
        vision: vision,
        behaviorPatterns: [existingPattern],
      );

      journey.updateBehaviorPatterns([newPattern]);

      expect(journey.behaviorPatterns, equals([newPattern]));
    });

    test('does not consider pattern ordering a change', () {
      final consistency = createBehaviorPattern();

      final leadership = createBehaviorPattern(
        type: BehaviorPatternType.leadership,
      );

      final journey = Journey(
        id: JourneyId.generate(),
        vision: vision,
        behaviorPatterns: [consistency, leadership],
      );

      journey.updateBehaviorPatterns([leadership, consistency]);

      expect(journey.behaviorPatterns, equals([consistency, leadership]));

      final events = journey.pullDomainEvents();

      expect(events.whereType<BehaviorPatternsDetected>(), isEmpty);
    });

    test('raises BehaviorPatternsDetected when a pattern is strengthened', () {
      final weakPattern = createBehaviorPattern(strength: const Strength(0.40));

      final strongPattern = createBehaviorPattern(
        strength: const Strength(0.80),
      );

      final journey = Journey(
        id: JourneyId.generate(),
        vision: vision,
        behaviorPatterns: [weakPattern],
      );

      journey.updateBehaviorPatterns([strongPattern]);

      expect(journey.behaviorPatterns, equals([strongPattern]));

      final events = journey.pullDomainEvents();

      final event = events.whereType<BehaviorPatternsDetected>().single;

      expect(event.patterns, equals([strongPattern]));
    });
  });
}

BehaviorPattern createBehaviorPattern({
  BehaviorPatternType type = BehaviorPatternType.consistency,
  Strength strength = const Strength(0.60),
}) {
  final firstObservedAt = DateTime(2026, 1, 1);
  final lastObservedAt = DateTime(2026, 1, 15);

  return BehaviorPattern(
    type: type,
    strength: strength,
    supportingEvidence: [
      createBehavioralEvidence(
        reflectionId: ReflectionId.generate(),
        observedAt: firstObservedAt,
      ),
      createBehavioralEvidence(
        reflectionId: ReflectionId.generate(),
        observedAt: lastObservedAt,
      ),
    ],
    firstObservedAt: firstObservedAt,
    lastObservedAt: lastObservedAt,
  );
}

BehavioralEvidence createBehavioralEvidence({
  required ReflectionId reflectionId,
  DateTime? observedAt,
}) {
  return BehavioralEvidence(
    type: BehavioralEvidenceType.confidence,
    source: ReflectionEvidenceSource(reflectionId: reflectionId),
    strength: const Strength(0.60),
    observedAt: observedAt ?? DateTime(2026, 1, 1),
  );
}
