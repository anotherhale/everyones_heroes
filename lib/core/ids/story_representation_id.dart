import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class StoryRepresentationId extends StronglyTypedId {
  const StoryRepresentationId(super.value);

  factory StoryRepresentationId.generate() {
    return StoryRepresentationId(StronglyTypedId.uuid.v4());
  }
}
