import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/discovery/user_discovery_fixture.dart';

void main() {
  group('UserDiscovery', () {
    test('creates a valid discovery', () {
      final discovery = UserDiscoveryFixture.favoriteHero();

      expect(discovery.value, 'Rocky Balboa');
      expect(discovery.confidence, 1.0);
    });

    test('trims whitespace from value', () {
      final discovery = UserDiscoveryFixture.create(
        value: '   Rocky Balboa   ',
      );

      expect(discovery.value, 'Rocky Balboa');
    });

    test('throws when value is empty', () {
      expect(() => UserDiscoveryFixture.create(value: ''), throwsArgumentError);
    });

    test('throws when value contains only whitespace', () {
      expect(
        () => UserDiscoveryFixture.create(value: '     '),
        throwsArgumentError,
      );
    });

    test('throws when confidence is below zero', () {
      expect(
        () => UserDiscoveryFixture.create(confidence: -0.01),
        throwsArgumentError,
      );
    });

    test('throws when confidence is greater than one', () {
      expect(
        () => UserDiscoveryFixture.create(confidence: 1.01),
        throwsArgumentError,
      );
    });

    test('stores supplied values', () {
      final date = DateTime.utc(2026, 7, 15);

      final discovery = UserDiscoveryFixture.create(
        confidence: 0.82,
        discoveredAt: date,
      );

      expect(discovery.type, isNotNull);
      expect(discovery.value, 'Rocky Balboa');
      expect(discovery.confidence, 0.82);
      expect(discovery.discoveredAt, date);
    });
  });
}
