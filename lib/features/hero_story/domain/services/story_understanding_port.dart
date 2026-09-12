import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/candidate_story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_observation.dart';

/// Provider-independent story understanding boundary (HS-ADR-024).
abstract interface class StoryUnderstandingPort {
  Future<StoryUnderstandingDraft> analyze(AnalyzeStoryContentRequest request);
}

/// Validated plain-Dart analysis input — not a Story aggregate.
final class AnalyzeStoryContentRequest {
  const AnalyzeStoryContentRequest({
    required this.storyId,
    required this.sourceRepresentationIds,
    required this.sourceText,
    required this.analysisLanguage,
    required this.processingVersion,
    this.requestId,
  });

  final StoryId storyId;
  final List<StoryRepresentationId> sourceRepresentationIds;
  final String sourceText;
  final LanguageCode analysisLanguage;
  final String processingVersion;
  final String? requestId;
}

/// Provider-agnostic draft mapped to [StoryUnderstanding.createProposed].
final class StoryUnderstandingDraft {
  const StoryUnderstandingDraft({
    this.candidateClassification,
    this.candidateSuitability,
    this.candidateSpirituality,
    this.observations = const [],
    this.detectedLanguage,
    this.supportLevel,
    this.providerLabel,
    this.modelLabel,
    this.promptOrTemplateVersion,
    this.uncertainties = const [],
    this.opaqueProviderConfidence,
  });

  final CandidateStoryClassification? candidateClassification;
  final CandidateContentSuitability? candidateSuitability;
  final CandidateSpiritualityClassification? candidateSpirituality;
  final List<StoryObservation> observations;
  final LanguageCode? detectedLanguage;
  final AnalysisSupportLevel? supportLevel;
  final String? providerLabel;
  final String? modelLabel;
  final String? promptOrTemplateVersion;
  final List<String> uncertainties;
  final Object? opaqueProviderConfidence;
}

final class StoryUnderstandingException implements Exception {
  const StoryUnderstandingException(this.message);

  final String message;

  @override
  String toString() => 'StoryUnderstandingException: $message';
}
