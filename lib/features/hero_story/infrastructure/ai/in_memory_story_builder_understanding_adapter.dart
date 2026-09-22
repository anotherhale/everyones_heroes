import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understood_theme_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_claim.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_key_story_elements.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_narrative_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_significant_event.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_theme.dart';

/// Deterministic development/test [StoryBuilderUnderstandingPort] (no network).
///
/// Grounds claims only in provided response IDs / structure. Never invents
/// polished story prose. Optional forced failure for adapter tests.
final class InMemoryStoryBuilderUnderstandingAdapter
    implements StoryBuilderUnderstandingPort {
  InMemoryStoryBuilderUnderstandingAdapter({
    this.forcedFailureMessage,
    this.forcedDraft,
  });

  final String? forcedFailureMessage;
  final StoryBuilderUnderstandingDraft? forcedDraft;

  static const Map<String, StoryBuilderTheme> _keywordThemes = {
    'persever': StoryBuilderTheme.perseverance,
    'courage': StoryBuilderTheme.courage,
    'afraid': StoryBuilderTheme.courage,
    'family': StoryBuilderTheme.family,
    'loss': StoryBuilderTheme.loss,
    'fail': StoryBuilderTheme.failure,
    'leader': StoryBuilderTheme.leadership,
    'service': StoryBuilderTheme.service,
    'sacrifice': StoryBuilderTheme.sacrifice,
    'purpose': StoryBuilderTheme.purpose,
    'love': StoryBuilderTheme.love,
    'transform': StoryBuilderTheme.transformation,
    'adversity': StoryBuilderTheme.overcomingAdversity,
    'second chance': StoryBuilderTheme.secondChances,
    'discover': StoryBuilderTheme.discovery,
  };

  @override
  Future<StoryBuilderUnderstandingDraft> analyze(
    StoryBuilderUnderstandingRequest request,
  ) async {
    final failure = forcedFailureMessage;
    if (failure != null) {
      throw StoryBuilderUnderstandingException(failure);
    }
    if (forcedDraft != null) {
      return forcedDraft!;
    }

    final answered = request.responses
        .where((r) => !r.skipped && (r.text ?? '').trim().isNotEmpty)
        .toList();
    if (answered.isEmpty) {
      throw const StoryBuilderUnderstandingException(
        'No answered Hero material available for understanding.',
      );
    }

    final themes = <UnderstoodTheme>[];
    final seenThemes = <StoryBuilderTheme>{};
    for (final intentTheme in request.themes) {
      if (seenThemes.add(intentTheme)) {
        themes.add(
          UnderstoodTheme(
            theme: intentTheme,
            origin: UnderstoodThemeOrigin.sessionIntent,
          ),
        );
      }
    }
    for (final response in answered) {
      final lower = response.text!.toLowerCase();
      for (final entry in _keywordThemes.entries) {
        if (lower.contains(entry.key) && seenThemes.add(entry.value)) {
          themes.add(
            UnderstoodTheme(
              theme: entry.value,
              origin: UnderstoodThemeOrigin.derivedFromResponses,
              sourceResponseIds: [response.id],
            ),
          );
        }
      }
    }

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
    final events = <UnderstoodSignificantEvent>[];

    for (final section in request.structureSections) {
      if (!section.hasSourceMaterial) {
        continue;
      }
      final ids = section.sourceResponseIds;
      final matching = answered.where((r) => ids.contains(r.id)).toList();
      final snippet = matching.isEmpty
          ? null
          : 'Hero provided ${section.narrativeRole.name} material.';

      narrativeElements.add(
        UnderstoodNarrativeElement(
          narrativeRole: section.narrativeRole,
          sourceResponseIds: ids,
          derivedNote: snippet,
        ),
      );

      final claim = UnderstoodClaim(
        sourceResponseIds: ids,
        derivedInterpretation: snippet,
      );
      switch (section.narrativeRole) {
        case StoryBuilderNarrativeRole.challenge:
          challenge = claim;
        case StoryBuilderNarrativeRole.struggle:
          struggle = claim;
        case StoryBuilderNarrativeRole.stakes:
          stakes = claim;
        case StoryBuilderNarrativeRole.turningPoint:
          turningPoint = claim;
          events.add(
            UnderstoodSignificantEvent(
              label: 'Turning point material',
              sourceResponseIds: ids,
              narrativeRole: section.narrativeRole,
            ),
          );
        case StoryBuilderNarrativeRole.decision:
          decision = claim;
          events.add(
            UnderstoodSignificantEvent(
              label: 'Decision material',
              sourceResponseIds: ids,
              narrativeRole: section.narrativeRole,
            ),
          );
        case StoryBuilderNarrativeRole.action:
          action = claim;
          events.add(
            UnderstoodSignificantEvent(
              label: 'Action material',
              sourceResponseIds: ids,
              narrativeRole: section.narrativeRole,
            ),
          );
        case StoryBuilderNarrativeRole.outcome:
          outcome = claim;
          events.add(
            UnderstoodSignificantEvent(
              label: 'Outcome material',
              sourceResponseIds: ids,
              narrativeRole: section.narrativeRole,
            ),
          );
        case StoryBuilderNarrativeRole.reflection:
          reflection = claim;
        case StoryBuilderNarrativeRole.message:
          message = claim;
        case StoryBuilderNarrativeRole.beginning:
        case StoryBuilderNarrativeRole.importance:
          break;
      }
    }

    return StoryBuilderUnderstandingDraft(
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
      significantEvents: events,
      derivedSummary:
          'Derived analysis of ${answered.length} Hero-authored response(s).',
      providerLabel: 'in_memory',
      promptOrTemplateVersion: 'sb8.ai.in_memory.v1',
    );
  }
}
