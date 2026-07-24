import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class JourneyId extends StronglyTypedId implements AggregateId {
  const JourneyId(super.value);

  factory JourneyId.generate() {
    return JourneyId(StronglyTypedId.uuid.v4());
  }
}
