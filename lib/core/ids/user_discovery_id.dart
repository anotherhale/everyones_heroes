import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class UserDiscoveryId extends StronglyTypedId {
  const UserDiscoveryId(super.value);

  factory UserDiscoveryId.generate() {
    return UserDiscoveryId(StronglyTypedId.uuid.v4());
  }
}
