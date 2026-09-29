import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Resolves Story-ready narrative text from Hero-owned proposal/session material.
///
/// SB.13 materialization must not invent prose or call AI. When
/// [StoryProposal.narrative] is absent, recover from:
/// 1. Non-empty proposal section contents (Hero-authored or Hero-reviewed)
/// 2. Canonical Story Builder answers via section [sourceResponseIds]
/// 3. All answered session responses (structure-mapping gaps)
///
/// Returns null only when no Hero story material exists — preserving the
/// materialization invariant that empty proposals cannot become Stories.
abstract final class StoryProposalNarrativeResolver {
  static String? resolve({
    required StoryProposal proposal,
    StoryBuilderSession? session,
  }) {
    final fromProposal = proposal.narrativeContent;
    if (fromProposal != null) {
      return fromProposal;
    }
    if (session == null) {
      return null;
    }
    return _fromSessionAnswers(proposal: proposal, session: session);
  }

  static String? _fromSessionAnswers({
    required StoryProposal proposal,
    required StoryBuilderSession session,
  }) {
    final responseById = {
      for (final response in session.responses) response.id.value: response,
    };

    final linkedParts = <String>[];
    final seenResponseIds = <String>{};
    for (final section in proposal.sections) {
      if (section.wasSkipped) continue;
      for (final sourceId in section.sourceResponseIds) {
        if (!seenResponseIds.add(sourceId.value)) continue;
        final response = responseById[sourceId.value];
        if (response == null || response.skipped) continue;
        final text = response.text?.trim();
        if (text == null || text.isEmpty) continue;
        linkedParts.add(text);
      }
    }
    if (linkedParts.isNotEmpty) {
      return linkedParts.join('\n\n');
    }

    final answeredParts = <String>[];
    final ordered = [...session.responses]
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    for (final response in ordered) {
      if (response.skipped) continue;
      final text = response.text?.trim();
      if (text == null || text.isEmpty) continue;
      answeredParts.add(text);
    }
    if (answeredParts.isEmpty) {
      return null;
    }
    return answeredParts.join('\n\n');
  }
}
