import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class UserDiscoveryId extends StronglyTypedId implements AggregateId {
  const UserDiscoveryId(super.value);

  factory UserDiscoveryId.generate() {
    return UserDiscoveryId(StronglyTypedId.uuid.v4());
  }
}
