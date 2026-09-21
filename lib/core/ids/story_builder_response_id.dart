import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Stable identity for a Hero-authored Story Builder response.
final class StoryBuilderResponseId extends StronglyTypedId {
  const StoryBuilderResponseId(super.value);

  factory StoryBuilderResponseId.generate() {
    return StoryBuilderResponseId(StronglyTypedId.uuid.v4());
  }
}
