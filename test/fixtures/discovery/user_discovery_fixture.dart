import 'package:everyonesheroes/core/ids/user_discovery_id.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/user_discovery.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/user_discovery_type.dart';

final class UserDiscoveryFixture {
  const UserDiscoveryFixture._();

  static UserDiscovery create({
    UserDiscoveryId? id,
    DiscoveryType type = DiscoveryType.favoriteHero,
    String value = 'Rocky Balboa',
    double confidence = 1.0,
    DateTime? discoveredAt,
  }) {
    return UserDiscovery(
      id: id ?? UserDiscoveryId.generate(),
      type: type,
      value: value,
      confidence: confidence,
      discoveredAt: discoveredAt ?? DateTime.utc(2026, 1, 1),
    );
  }

  static UserDiscovery favoriteHero({String value = 'Rocky Balboa'}) =>
      create(type: DiscoveryType.favoriteHero, value: value);

  static UserDiscovery favoriteBook({String value = 'Atomic Habits'}) =>
      create(type: DiscoveryType.favoriteBook, value: value);

  static UserDiscovery favoriteMovie({String value = 'Rocky'}) =>
      create(type: DiscoveryType.favoriteMovie, value: value);

  static UserDiscovery lifeGoal({String value = 'Become a great leader'}) =>
      create(type: DiscoveryType.lifeGoal, value: value);
}
