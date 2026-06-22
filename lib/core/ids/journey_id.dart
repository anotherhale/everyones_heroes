import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class JourneyId extends StronglyTypedId {
  const JourneyId(super.value);

  factory JourneyId.generate() {
    return JourneyId(StronglyTypedId.uuid.v4());
  }
}
