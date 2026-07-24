import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class LifeJourneyId extends StronglyTypedId implements AggregateId {
  const LifeJourneyId(super.value);

  factory LifeJourneyId.generate() {
    return LifeJourneyId(StronglyTypedId.uuid.v4());
  }
}
