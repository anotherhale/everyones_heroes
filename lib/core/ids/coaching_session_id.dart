import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class CoachingSessionId extends StronglyTypedId {
  CoachingSessionId(super.value);

  factory CoachingSessionId.generate() =>
      CoachingSessionId(StronglyTypedId.uuid.v4());
}
