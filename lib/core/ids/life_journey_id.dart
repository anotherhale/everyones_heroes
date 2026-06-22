import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class LifeJourneyId extends StronglyTypedId {
  const LifeJourneyId(super.value);

  factory LifeJourneyId.generate() {
    return LifeJourneyId(StronglyTypedId.uuid.v4());
  }
}
