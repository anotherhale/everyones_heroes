import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference.dart';
import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference_type.dart';

final class DiscoveryPreferenceFixture {
  const DiscoveryPreferenceFixture._();

  static DiscoveryPreference create({
    DiscoveryPreferenceType type = DiscoveryPreferenceType.musicStyle,
    String value = 'Epic Orchestral',
  }) {
    return DiscoveryPreference(type: type, value: value);
  }

  static DiscoveryPreference music({String value = 'Epic Orchestral'}) =>
      create(type: DiscoveryPreferenceType.musicStyle, value: value);

  static DiscoveryPreference coaching({String value = 'Direct'}) =>
      create(type: DiscoveryPreferenceType.coachingStyle, value: value);

  static DiscoveryPreference storytelling({String value = 'Heroic Journey'}) =>
      create(type: DiscoveryPreferenceType.storytellingStyle, value: value);
}
