import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';

void main() {
  group('DefaultCurrentJourneyContext', () {
    late DefaultCurrentJourneyContext context;

    setUp(() {
      context = DefaultCurrentJourneyContext();
    });

    test('starts without a current journey', () {
      expect(context.currentJourneyId, isNull);
    });

    test('sets the current journey', () {
      final journeyId = JourneyId.generate();

      context.setCurrentJourney(journeyId);

      expect(context.currentJourneyId, journeyId);
    });

    test('replaces the current journey', () {
      final firstJourneyId = JourneyId.generate();
      final secondJourneyId = JourneyId.generate();

      context.setCurrentJourney(firstJourneyId);
      context.setCurrentJourney(secondJourneyId);

      expect(context.currentJourneyId, secondJourneyId);
    });

    test('clears the current journey', () {
      context.setCurrentJourney(JourneyId.generate());

      context.clear();

      expect(context.currentJourneyId, isNull);
    });
  });
}
