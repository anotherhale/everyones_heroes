import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/behavioral_signal.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_signal_type.dart';

void main() {
  group('behavioralSignal', () {
    test('creates signal', () {
      final timestamp = DateTime.now();

      final signal = BehavioralSignal(
        type: BehavioralSignalType.discipline,
        observedAt: timestamp,
      );

      expect(signal.type, BehavioralSignalType.discipline);

      expect(signal.observedAt, timestamp);
    });

    test('supports discipline signal', () {
      final signal = BehavioralSignal(
        type: BehavioralSignalType.discipline,
        observedAt: DateTime.now(),
      );

      expect(signal.type, BehavioralSignalType.discipline);
    });

    test('supports resilience signal', () {
      final signal = BehavioralSignal(
        type: BehavioralSignalType.resilience,
        observedAt: DateTime.now(),
      );

      expect(signal.type, BehavioralSignalType.resilience);
    });

    test('supports leadership signal', () {
      final signal = BehavioralSignal(
        type: BehavioralSignalType.leadership,
        observedAt: DateTime.now(),
      );

      expect(signal.type, BehavioralSignalType.leadership);
    });

    test('preserves observation timestamp', () {
      final timestamp = DateTime(2026, 1, 15, 10, 30);

      final signal = BehavioralSignal(
        type: BehavioralSignalType.service,
        observedAt: timestamp,
      );

      expect(signal.observedAt, timestamp);
    });

    test('signals with same values are equivalent', () {
      final timestamp = DateTime(2026, 1, 15);

      final first = BehavioralSignal(
        type: BehavioralSignalType.courage,
        observedAt: timestamp,
      );

      final second = BehavioralSignal(
        type: BehavioralSignalType.courage,
        observedAt: timestamp,
      );

      expect(first.type, second.type);

      expect(first.observedAt, second.observedAt);
    });
  });
}
