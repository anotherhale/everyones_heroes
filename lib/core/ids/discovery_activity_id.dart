import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class DiscoveryActivityId extends StronglyTypedId {
  DiscoveryActivityId(super.value);

  factory DiscoveryActivityId.generate() =>
      DiscoveryActivityId(StronglyTypedId.uuid.v4());
}
