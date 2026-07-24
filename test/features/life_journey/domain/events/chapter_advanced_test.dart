import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/chapter_advanced.dart';

void main() {
  group('ChapterAdvanced', () {
    test('stores chapter transition', () {
      final event = ChapterAdvanced(
        aggregateId: JourneyId.generate(),
        previousChapter: JourneyChapter.awakening,
        newChapter: JourneyChapter.commitment,
      );

      expect(event.previousChapter, JourneyChapter.awakening);

      expect(event.newChapter, JourneyChapter.commitment);
    });

    test('uses Journey aggregate type', () {
      final event = ChapterAdvanced(
        aggregateId: JourneyId.generate(),
        previousChapter: JourneyChapter.awakening,
        newChapter: JourneyChapter.commitment,
      );

      expect(event.aggregateType, AggregateType.journey);
    });
  });
}
