import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class StoryUnderstandingId extends StronglyTypedId
    implements AggregateId {
  const StoryUnderstandingId(super.value);

  factory StoryUnderstandingId.generate() {
    return StoryUnderstandingId(StronglyTypedId.uuid.v4());
  }
}
