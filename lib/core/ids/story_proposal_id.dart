import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Stable identity for a [StoryProposal] (SB.9).
///
/// Distinct from [StoryBuilderSessionId], [StoryId], and response/prompt IDs.
/// Each new proposal generation allocates a new identity; a persisted proposal
/// keeps the same id across reloads.
final class StoryProposalId extends StronglyTypedId implements AggregateId {
  const StoryProposalId(super.value);

  factory StoryProposalId.generate() {
    return StoryProposalId(StronglyTypedId.uuid.v4());
  }
}
