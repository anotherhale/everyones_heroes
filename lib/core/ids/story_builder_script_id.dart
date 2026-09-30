import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Stable identity for a durable [StoryBuilderScript] (SB.8 script generation).
///
/// Distinct from [StoryBuilderSessionId], [StoryProposalId], [StoryId], and
/// [StoryRepresentationId]. Each generation allocates a new identity; a
/// persisted script keeps the same id across reloads and edits.
final class StoryBuilderScriptId extends StronglyTypedId
    implements AggregateId {
  const StoryBuilderScriptId(super.value);

  factory StoryBuilderScriptId.generate() {
    return StoryBuilderScriptId(StronglyTypedId.uuid.v4());
  }
}
