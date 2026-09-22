import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_claim.dart';

/// Validates that understanding provenance references only session responses.
abstract final class StoryBuilderUnderstandingProvenance {
  /// Response IDs present on the session (answered or skipped).
  static Set<StoryBuilderResponseId> validResponseIds(
    StoryBuilderSession session,
  ) {
    return {for (final response in session.responses) response.id};
  }

  /// Throws [StoryBuilderUnderstandingException] when any ID is unknown.
  static void validateResponseIds({
    required Iterable<StoryBuilderResponseId> candidateIds,
    required Set<StoryBuilderResponseId> validIds,
    required String context,
  }) {
    for (final id in candidateIds) {
      if (!validIds.contains(id)) {
        throw StoryBuilderUnderstandingException(
          'Invalid provenance in $context: unknown response id ${id.value}.',
        );
      }
    }
  }

  static void validateDraft({
    required StoryBuilderUnderstandingDraft draft,
    required Set<StoryBuilderResponseId> validIds,
  }) {
    for (final theme in draft.themes) {
      validateResponseIds(
        candidateIds: theme.sourceResponseIds,
        validIds: validIds,
        context: 'theme ${theme.theme.name}',
      );
    }
    for (final element in draft.narrativeElements) {
      validateResponseIds(
        candidateIds: element.sourceResponseIds,
        validIds: validIds,
        context: 'narrativeElement ${element.narrativeRole.name}',
      );
    }
    for (final event in draft.significantEvents) {
      validateResponseIds(
        candidateIds: event.sourceResponseIds,
        validIds: validIds,
        context: 'significantEvent "${event.label}"',
      );
    }
    final keys = draft.keyElements;
    _validateClaim(keys.challenge, 'keyElements.challenge', validIds);
    _validateClaim(keys.struggle, 'keyElements.struggle', validIds);
    _validateClaim(keys.stakes, 'keyElements.stakes', validIds);
    _validateClaim(keys.turningPoint, 'keyElements.turningPoint', validIds);
    _validateClaim(keys.decision, 'keyElements.decision', validIds);
    _validateClaim(keys.action, 'keyElements.action', validIds);
    _validateClaim(keys.outcome, 'keyElements.outcome', validIds);
    _validateClaim(keys.reflection, 'keyElements.reflection', validIds);
    _validateClaim(keys.message, 'keyElements.message', validIds);
  }

  static void _validateClaim(
    UnderstoodClaim? claim,
    String context,
    Set<StoryBuilderResponseId> validIds,
  ) {
    if (claim == null) {
      return;
    }
    validateResponseIds(
      candidateIds: claim.sourceResponseIds,
      validIds: validIds,
      context: context,
    );
  }
}
