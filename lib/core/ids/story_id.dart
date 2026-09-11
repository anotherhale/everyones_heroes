import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class StoryId extends StronglyTypedId implements AggregateId {
  const StoryId(super.value);

  factory StoryId.generate() {
    return StoryId(StronglyTypedId.uuid.v4());
  }
}
