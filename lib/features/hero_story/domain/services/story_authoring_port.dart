import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Provider-independent authoring boundary for intentional Story representations.
///
/// AI may help present the story. AI does not own the story (HS-ADR-032/033).
abstract interface class StoryAuthoringPort {
  Future<StoryAuthoringDraft> generate(GenerateStoryAuthoringRequest request);
}

final class GenerateStoryAuthoringRequest {
  const GenerateStoryAuthoringRequest({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.sourceText,
    required this.language,
    required this.targetFormat,
    required this.processingVersion,
    this.requestId,
    this.understandingContext,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final String sourceText;
  final LanguageCode language;
  final StoryRepresentationFormat targetFormat;
  final String processingVersion;
  final String? requestId;

  /// Optional non-authoritative context from an approved/applicable understanding.
  final String? understandingContext;
}

final class StoryAuthoringDraft {
  const StoryAuthoringDraft({
    required this.textContent,
    required this.format,
    required this.language,
    this.providerLabel,
    this.supportLevel,
    this.notes,
  });

  final String textContent;
  final StoryRepresentationFormat format;
  final LanguageCode language;
  final String? providerLabel;
  final AnalysisSupportLevel? supportLevel;
  final String? notes;
}

final class StoryAuthoringException implements Exception {
  const StoryAuthoringException(this.message);

  final String message;

  @override
  String toString() => 'StoryAuthoringException: $message';
}
