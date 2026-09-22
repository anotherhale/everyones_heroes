import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_transport.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';

/// Deterministic development/test [StoryAuthoringTransport] for SB.11.
///
/// Distinct from HS.5 [InMemoryStoryAuthoringAdapter] ([StoryAuthoringPort]).
/// Produces derived prose from supplied Hero material without inventing facts.
final class InMemoryStoryProposalAuthoringAdapter
    implements StoryAuthoringTransport {
  InMemoryStoryProposalAuthoringAdapter({
    this.forcedFailureMessage,
    this.forcedResponse,
  });

  final String? forcedFailureMessage;
  final StoryAuthoringResponse? forcedResponse;

  @override
  Future<StoryAuthoringResponse> author(StoryAuthoringRequest request) async {
    final failure = forcedFailureMessage;
    if (failure != null) {
      throw StoryShaperException(failure);
    }
    if (forcedResponse != null) {
      return forcedResponse!;
    }

    final sourceSections = request.sections
        .where(
          (s) =>
              !s.wasSkipped &&
              s.content != null &&
              s.content!.trim().isNotEmpty &&
              s.sourceResponseIds.isNotEmpty,
        )
        .toList();

    if (sourceSections.isEmpty) {
      throw const StoryShaperException(
        'No Hero-authored material available for AI story authoring.',
      );
    }

    final sections = <StoryAuthoringSectionOutput>[];
    for (final section in sourceSections) {
      final text = section.content!.trim();
      sections.add(
        StoryAuthoringSectionOutput(
          role: section.role,
          content: _shapeProse(section.role, text),
          sourceResponseIds: List.of(section.sourceResponseIds),
        ),
      );
    }

    final themeHint = request.themes.isEmpty
        ? null
        : request.themes.map(_themeLabel).join(', ');

    return StoryAuthoringResponse(
      title: request.title ??
          (themeHint == null ? 'A story of growth' : 'A story of $themeHint'),
      summary:
          'AI-assisted draft derived from ${sourceSections.length} Hero section(s).',
      sections: sections,
      warnings: const [],
      providerLabel: 'in_memory',
      promptOrTemplateVersion: 'sb11.ai.in_memory.v1',
    );
  }

  static String _shapeProse(StoryBuilderNarrativeRole role, String source) {
    // Lightweight rewrite that stays grounded in supplied text — tests only.
    return 'From the Hero\'s account of ${_roleLabel(role)}: $source';
  }

  static String _roleLabel(StoryBuilderNarrativeRole role) {
    return switch (role) {
      StoryBuilderNarrativeRole.beginning => 'the beginning',
      StoryBuilderNarrativeRole.challenge => 'the challenge',
      StoryBuilderNarrativeRole.importance => 'what mattered',
      StoryBuilderNarrativeRole.struggle => 'the struggle',
      StoryBuilderNarrativeRole.stakes => 'what was at stake',
      StoryBuilderNarrativeRole.turningPoint => 'the turning point',
      StoryBuilderNarrativeRole.decision => 'the decision',
      StoryBuilderNarrativeRole.action => 'the action taken',
      StoryBuilderNarrativeRole.outcome => 'the outcome',
      StoryBuilderNarrativeRole.reflection => 'the reflection',
      StoryBuilderNarrativeRole.message => 'the message',
    };
  }

  static String _themeLabel(StoryBuilderTheme theme) {
    return switch (theme) {
      StoryBuilderTheme.overcomingAdversity => 'overcoming adversity',
      StoryBuilderTheme.courage => 'courage',
      StoryBuilderTheme.service => 'service',
      StoryBuilderTheme.leadership => 'leadership',
      StoryBuilderTheme.loss => 'loss',
      StoryBuilderTheme.failure => 'failure',
      StoryBuilderTheme.transformation => 'transformation',
      StoryBuilderTheme.perseverance => 'perseverance',
      StoryBuilderTheme.secondChances => 'second chances',
      StoryBuilderTheme.sacrifice => 'sacrifice',
      StoryBuilderTheme.family => 'family',
      StoryBuilderTheme.discovery => 'discovery',
      StoryBuilderTheme.purpose => 'purpose',
      StoryBuilderTheme.love => 'love',
    };
  }
}
