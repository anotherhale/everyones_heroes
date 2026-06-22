import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/chapter_advanced.dart';

void main() {
  group('ChapterAdvanced', () {
    test('stores chapter transition', () {
      final event =
          ChapterAdvanced(
        aggregateId: 'journey-123',
        previousChapter:
            JourneyChapter.awakening,
        newChapter:
            JourneyChapter.commitment,
      );

      expect(
        event.previousChapter,
        JourneyChapter.awakening,
      );

      expect(
        event.newChapter,
        JourneyChapter.commitment,
      );
    });

    test('uses Journey aggregate type', () {
      final event =
          ChapterAdvanced(
        aggregateId: 'journey-123',
        previousChapter:
            JourneyChapter.awakening,
        newChapter:
            JourneyChapter.commitment,
      );

      expect(
        event.aggregateType,
        'Journey',
      );
    });
  });
}