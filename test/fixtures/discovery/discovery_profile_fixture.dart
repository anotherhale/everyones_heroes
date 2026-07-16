import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/user_discovery.dart';
import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference.dart';

final class DiscoveryProfileFixture {
  const DiscoveryProfileFixture._();

  static DiscoveryProfile create({
    DiscoveryProfileId? id,
    UserId? userId,
    Iterable<InfluenceId>? influenceIds,
    Iterable<NarrativeThemeId>? narrativeThemeIds,
    Iterable<UserDiscovery>? discoveries,
    Iterable<DiscoveryPreference>? preferences,
  }) {
    return DiscoveryProfile(
      id: id ?? DiscoveryProfileId.generate(),
      userId: userId ?? UserId.generate(),
      influenceIds: influenceIds,
      narrativeThemeIds: narrativeThemeIds,
      discoveries: discoveries,
      preferences: preferences,
    );
  }
}
