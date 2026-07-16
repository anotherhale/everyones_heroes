import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference_type.dart';

import '../../../../fixtures/discovery/discovery_preference_fixture.dart';

void main() {
  group('DiscoveryPreference', () {
    test('creates a valid preference', () {
      final preference = DiscoveryPreferenceFixture.music();

      expect(preference.type, DiscoveryPreferenceType.musicStyle);

      expect(preference.value, 'Epic Orchestral');
    });

    test('trims whitespace', () {
      final preference = DiscoveryPreferenceFixture.create(
        value: '  Epic Orchestral  ',
      );

      expect(preference.value, 'Epic Orchestral');
    });

    test('throws when value is empty', () {
      expect(
        () => DiscoveryPreferenceFixture.create(value: ''),
        throwsArgumentError,
      );
    });

    test('throws when value is whitespace', () {
      expect(
        () => DiscoveryPreferenceFixture.create(value: '    '),
        throwsArgumentError,
      );
    });

    test('equal preferences compare equal', () {
      final a = DiscoveryPreferenceFixture.music();
      final b = DiscoveryPreferenceFixture.music();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different values are not equal', () {
      final a = DiscoveryPreferenceFixture.music();
      final b = DiscoveryPreferenceFixture.music(value: 'Rock');

      expect(a, isNot(equals(b)));
    });

    test('different types are not equal', () {
      final a = DiscoveryPreferenceFixture.music();
      final b = DiscoveryPreferenceFixture.coaching();

      expect(a, isNot(equals(b)));
    });
  });
}
