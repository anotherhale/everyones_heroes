import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/observation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_observation.dart';

/// Deterministic keyword-based understanding adapter (no network / no AI SDK).
///
/// Validates closed enums and never invents taxonomy values or Hero identity.
final class InMemoryStoryUnderstandingAdapter
    implements StoryUnderstandingPort {
  InMemoryStoryUnderstandingAdapter({
    this.forcedFailureMessage,
    this.injectMalformedIdentityClaim = false,
    this.injectUnknownSubjectLabel,
    Iterable<NarrativeThemeId>? themeCandidates,
  }) : themeCandidates = List.unmodifiable(themeCandidates ?? const []);

  final String? forcedFailureMessage;
  final bool injectMalformedIdentityClaim;
  final String? injectUnknownSubjectLabel;
  final List<NarrativeThemeId> themeCandidates;

  static const int maxObservations = 50;

  @override
  Future<StoryUnderstandingDraft> analyze(
    AnalyzeStoryContentRequest request,
  ) async {
    if (forcedFailureMessage != null) {
      throw StoryUnderstandingException(forcedFailureMessage!);
    }

    final text = request.sourceText.trim();
    if (text.isEmpty) {
      throw const StoryUnderstandingException(
        'Source text for understanding cannot be empty.',
      );
    }

    if (request.sourceRepresentationIds.isEmpty) {
      throw const StoryUnderstandingException(
        'At least one source representation id is required.',
      );
    }

    if (injectMalformedIdentityClaim) {
      throw const StoryUnderstandingException(
        'Malformed AI output rejected: sensitive Hero identity inference.',
      );
    }

    // Unknown free-form labels are discarded (never become closed enums).
    if (injectUnknownSubjectLabel != null) {
      // Deliberately ignored — recorded as uncertainty below.
    }

    final lower = text.toLowerCase();
    final subjects = <StorySubject>{};
    final challenges = <StoryChallenge>{};
    final outcomes = <StoryOutcome>{};
    final emotional = <EmotionalCharacter>{};
    final observations = <StoryObservation>[];
    final uncertainties = <String>[];

    void mention(StorySubject subject, String keyword) {
      if (lower.contains(keyword)) {
        subjects.add(subject);
        observations.add(
          StoryObservation(
            kind: ObservationKind.contentMention,
            content: 'Source mentions $keyword (subject: ${subject.name}).',
            supportLevel: AnalysisSupportLevel.moderate,
          ),
        );
      }
    }

    mention(StorySubject.military, 'military');
    mention(StorySubject.family, 'family');
    mention(StorySubject.career, 'career');
    mention(StorySubject.startingOver, 'starting over');
    mention(StorySubject.leadership, 'leadership');
    mention(StorySubject.service, 'service');

    if (lower.contains('fear')) {
      challenges.add(StoryChallenge.fear);
    }
    if (lower.contains('loss') || lower.contains('grief')) {
      challenges.add(StoryChallenge.loss);
      if (lower.contains('grief')) {
        challenges.add(StoryChallenge.grief);
      }
    }
    if (lower.contains('failure')) {
      challenges.add(StoryChallenge.failure);
    }
    if (lower.contains('change')) {
      challenges.add(StoryChallenge.change);
    }

    if (lower.contains('courage') || lower.contains('courageous')) {
      emotional.add(EmotionalCharacter.inspiring);
      observations.add(
        StoryObservation(
          kind: ObservationKind.contentMention,
          content: 'Source mentions courage.',
          supportLevel: AnalysisSupportLevel.moderate,
        ),
      );
    }
    if (lower.contains('hope')) {
      emotional.add(EmotionalCharacter.hopeful);
    }
    if (lower.contains('funny') || lower.contains('humor')) {
      emotional.add(EmotionalCharacter.funny);
    }

    if (lower.contains('recovery') || lower.contains('recover')) {
      outcomes.add(StoryOutcome.recovery);
    }
    if (lower.contains('purpose')) {
      outcomes.add(StoryOutcome.findingPurpose);
    }
    if (lower.contains('transformation') || lower.contains('transform')) {
      outcomes.add(StoryOutcome.personalTransformation);
    }
    if (lower.contains('new beginning') || lower.contains('starting over')) {
      outcomes.add(StoryOutcome.newBeginning);
    }

    if (injectUnknownSubjectLabel != null) {
      uncertainties.add(
        'Unsupported catalog label discarded: $injectUnknownSubjectLabel',
      );
      observations.add(
        StoryObservation(
          kind: ObservationKind.uncertainty,
          content:
              'Unknown catalog label "$injectUnknownSubjectLabel" was not mapped.',
          supportLevel: AnalysisSupportLevel.weak,
        ),
      );
    }

    CandidateSpiritualityClassification? spirituality;
    if (lower.contains('prayer') ||
        lower.contains('faith') ||
        lower.contains('church') ||
        lower.contains('mosque') ||
        lower.contains('temple')) {
      // Story content signal only — never Hero religion.
      spirituality = CandidateSpiritualityClassification(
        category: SpiritualityCategory.religious,
        tradition: lower.contains('church')
            ? ReligiousTradition.christianity
            : lower.contains('mosque')
            ? ReligiousTradition.islam
            : ReligiousTradition.other,
      );
      observations.add(
        StoryObservation(
          kind: ObservationKind.contentMention,
          content:
              'Story content appears to include religious references '
              '(content classification only; not Hero identity).',
          supportLevel: AnalysisSupportLevel.weak,
        ),
      );
    } else if (lower.contains('spiritual') && !lower.contains('religion')) {
      spirituality = CandidateSpiritualityClassification(
        category: SpiritualityCategory.spiritual,
      );
    }

    CandidateContentSuitability? suitability;
    var violence = SuitabilityLevel.none;
    var disturbing = SuitabilityLevel.none;
    if (lower.contains('violence') || lower.contains('combat')) {
      violence = SuitabilityLevel.moderate;
    }
    if (lower.contains('trauma') || lower.contains('disturbing')) {
      disturbing = SuitabilityLevel.mild;
    }
    if (violence != SuitabilityLevel.none ||
        disturbing != SuitabilityLevel.none) {
      suitability = CandidateContentSuitability(
        violence: violence,
        disturbingContent: disturbing,
      );
    }

    LanguageCode? detected = request.analysisLanguage;
    observations.add(
      StoryObservation(
        kind: ObservationKind.languageSignal,
        content: 'Analysis language treated as ${request.analysisLanguage.value}.',
        supportLevel: AnalysisSupportLevel.weak,
      ),
    );

    if (observations.length > maxObservations) {
      throw const StoryUnderstandingException(
        'Observation count exceeds adapter validation bound.',
      );
    }

    final classification = CandidateStoryClassification(
      subjects: subjects,
      challenges: challenges,
      narrativeThemeIds: themeCandidates,
      outcomes: outcomes,
      emotionalCharacters: emotional,
      audience: StoryAudience.adult,
    );

    return StoryUnderstandingDraft(
      candidateClassification: classification.isEmpty ? null : classification,
      candidateSuitability: suitability,
      candidateSpirituality: spirituality,
      observations: List.unmodifiable(observations),
      detectedLanguage: detected,
      supportLevel: AnalysisSupportLevel.moderate,
      providerLabel: 'in_memory',
      modelLabel: 'keyword_v1',
      promptOrTemplateVersion: 'hs4-fixture-1',
      uncertainties: List.unmodifiable(uncertainties),
      opaqueProviderConfidence: 'deterministic',
    );
  }
}
