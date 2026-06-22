import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class EventId extends StronglyTypedId {
  const EventId(super.value);

  factory EventId.generate() {
    return EventId(StronglyTypedId.uuid.v4());
  }
}
