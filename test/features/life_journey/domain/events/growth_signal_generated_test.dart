import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_signal_type.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_signal_generated.dart';

void main() {
  group('behavioralSignalGenerated', () {
    test('stores signal type', () {
      final event = BehavioralSignalGenerated(
        aggregateId: 'journey-123',
        signalType: BehavioralSignalType.discipline,
      );

      expect(event.signalType, BehavioralSignalType.discipline);
    });

    test('uses Journey aggregate type', () {
      final event = BehavioralSignalGenerated(
        aggregateId: 'journey-123',
        signalType: BehavioralSignalType.discipline,
      );

      expect(event.aggregateType, 'Journey');
    });
  });
}
