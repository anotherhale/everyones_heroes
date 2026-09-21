import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Stable identity for a prompt presented during a Story Builder session.
final class StoryBuilderPromptId extends StronglyTypedId {
  const StoryBuilderPromptId(super.value);

  factory StoryBuilderPromptId.generate() {
    return StoryBuilderPromptId(StronglyTypedId.uuid.v4());
  }
}
