import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Provider-independent translation boundary (HS.5 Slice B / HS-ADR-037).
abstract interface class StoryTranslationPort {
  Future<StoryTranslationDraft> translate(
    TranslateStoryRepresentationRequest request,
  );
}

final class TranslateStoryRepresentationRequest {
  const TranslateStoryRepresentationRequest({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.sourceText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sourceFormat,
    required this.processingVersion,
    this.requestId,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final String sourceText;
  final LanguageCode sourceLanguage;
  final LanguageCode targetLanguage;
  final StoryRepresentationFormat sourceFormat;
  final String processingVersion;
  final String? requestId;
}

final class StoryTranslationDraft {
  const StoryTranslationDraft({
    required this.textContent,
    required this.language,
    required this.format,
    this.providerLabel,
    this.supportLevel,
  });

  final String textContent;
  final LanguageCode language;
  final StoryRepresentationFormat format;
  final String? providerLabel;
  final AnalysisSupportLevel? supportLevel;
}

final class StoryTranslationException implements Exception {
  const StoryTranslationException(this.message);

  final String message;

  @override
  String toString() => 'StoryTranslationException: $message';
}
