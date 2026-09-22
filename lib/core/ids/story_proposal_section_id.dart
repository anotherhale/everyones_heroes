import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for one section within a [StoryProposal] (SB.9).
final class StoryProposalSectionId extends StronglyTypedId {
  const StoryProposalSectionId(super.value);

  factory StoryProposalSectionId.generate() {
    return StoryProposalSectionId(StronglyTypedId.uuid.v4());
  }
}
