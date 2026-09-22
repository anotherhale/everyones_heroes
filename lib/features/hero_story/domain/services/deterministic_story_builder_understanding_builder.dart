import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_understanding_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understood_theme_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_understanding.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_claim.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_key_story_elements.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_narrative_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_significant_event.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_theme.dart';

/// Builds offline Story Understanding from SB.3/SB.4 material (SB.8).
///
/// No AI, no invented facts, no polished prose, no Story creation.
/// Themes come from session intent; narrative/key/event presence from
/// answered structure sections with response-ID provenance only.
final class DeterministicStoryBuilderUnderstandingBuilder {
  const DeterministicStoryBuilderUnderstandingBuilder();

  static const Set<StoryBuilderNarrativeRole> _eventRoles = {
    StoryBuilderNarrativeRole.turningPoint,
    StoryBuilderNarrativeRole.decision,
    StoryBuilderNarrativeRole.action,
    StoryBuilderNarrativeRole.outcome,
  };

  static const Map<StoryBuilderNarrativeRole, String> _eventLabels = {
    StoryBuilderNarrativeRole.turningPoint: 'Turning point material',
    StoryBuilderNarrativeRole.decision: 'Decision material',
    StoryBuilderNarrativeRole.action: 'Action material',
    StoryBuilderNarrativeRole.outcome: 'Outcome material',
  };

  StoryBuilderUnderstanding build({
    required StoryBuilderSession session,
    required DeterministicStoryStructure structure,
    DateTime? analyzedAt,
  }) {
    final narrativeElements = <UnderstoodNarrativeElement>[];
    UnderstoodClaim? challenge;
    UnderstoodClaim? struggle;
    UnderstoodClaim? stakes;
    UnderstoodClaim? turningPoint;
    UnderstoodClaim? decision;
    UnderstoodClaim? action;
    UnderstoodClaim? outcome;
    UnderstoodClaim? reflection;
    UnderstoodClaim? message;
    final significantEvents = <UnderstoodSignificantEvent>[];

    for (final section in structure.sections) {
      if (!section.hasSourceMaterial) {
        continue;
      }
      final ids = section.sourceResponseIds;
      narrativeElements.add(
        UnderstoodNarrativeElement(
          narrativeRole: section.narrativeRole,
          sourceResponseIds: ids,
        ),
      );

      final claim = UnderstoodClaim(sourceResponseIds: ids);
      switch (section.narrativeRole) {
        case StoryBuilderNarrativeRole.challenge:
          challenge = claim;
        case StoryBuilderNarrativeRole.struggle:
          struggle = claim;
        case StoryBuilderNarrativeRole.stakes:
          stakes = claim;
        case StoryBuilderNarrativeRole.turningPoint:
          turningPoint = claim;
        case StoryBuilderNarrativeRole.decision:
          decision = claim;
        case StoryBuilderNarrativeRole.action:
          action = claim;
        case StoryBuilderNarrativeRole.outcome:
          outcome = claim;
        case StoryBuilderNarrativeRole.reflection:
          reflection = claim;
        case StoryBuilderNarrativeRole.message:
          message = claim;
        case StoryBuilderNarrativeRole.beginning:
        case StoryBuilderNarrativeRole.importance:
          break;
      }

      if (_eventRoles.contains(section.narrativeRole)) {
        significantEvents.add(
          UnderstoodSignificantEvent(
            label: _eventLabels[section.narrativeRole]!,
            sourceResponseIds: ids,
            narrativeRole: section.narrativeRole,
          ),
        );
      }
    }

    final themes = [
      for (final theme in session.intent.themes)
        UnderstoodTheme(
          theme: theme,
          origin: UnderstoodThemeOrigin.sessionIntent,
        ),
    ];

    return StoryBuilderUnderstanding(
      sessionId: session.id,
      kind: StoryBuilderUnderstandingKind.deterministic,
      structure: structure,
      intentSnapshot: session.intent,
      processingVersion:
          StoryBuilderUnderstanding.deterministicProcessingVersion,
      analyzedAt: analyzedAt ?? DateTime.now(),
      themes: themes,
      narrativeElements: narrativeElements,
      keyElements: UnderstoodKeyStoryElements(
        challenge: challenge,
        struggle: struggle,
        stakes: stakes,
        turningPoint: turningPoint,
        decision: decision,
        action: action,
        outcome: outcome,
        reflection: reflection,
        message: message,
      ),
      significantEvents: significantEvents,
      providerLabel: 'deterministic',
    );
  }
}
