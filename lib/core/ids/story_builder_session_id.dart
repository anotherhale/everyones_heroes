import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class StoryBuilderSessionId extends StronglyTypedId
    implements AggregateId {
  const StoryBuilderSessionId(super.value);

  factory StoryBuilderSessionId.generate() {
    return StoryBuilderSessionId(StronglyTypedId.uuid.v4());
  }
}
