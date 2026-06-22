import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/chapter_advanced.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

void main() {
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

      expect(journey.domainEvents.first, isA<JourneyCreated>());
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

      journey.advanceChapter(JourneyChapter.commitment);

      expect(journey.domainEvents.any((e) => e is ChapterAdvanced), isTrue);
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
}
