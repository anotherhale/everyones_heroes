import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class DiscoveryProfileId extends StronglyTypedId implements AggregateId {
  const DiscoveryProfileId(super.value);

  factory DiscoveryProfileId.generate() {
    return DiscoveryProfileId(StronglyTypedId.uuid.v4());
  }
}
