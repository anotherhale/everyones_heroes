import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class HeroId extends StronglyTypedId implements AggregateId {
  const HeroId(super.value);

  factory HeroId.generate() {
    return HeroId(StronglyTypedId.uuid.v4());
  }
}
