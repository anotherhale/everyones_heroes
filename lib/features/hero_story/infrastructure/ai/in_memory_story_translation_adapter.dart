import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_translation_port.dart';

/// Deterministic in-memory translation adapter (no network / no AI SDK).
final class InMemoryStoryTranslationAdapter implements StoryTranslationPort {
  InMemoryStoryTranslationAdapter({
    this.forcedFailureMessage,
    this.forcedEmptyText = false,
  });

  final String? forcedFailureMessage;
  final bool forcedEmptyText;

  @override
  Future<StoryTranslationDraft> translate(
    TranslateStoryRepresentationRequest request,
  ) async {
    if (forcedFailureMessage != null) {
      throw StoryTranslationException(forcedFailureMessage!);
    }

    final source = request.sourceText.trim();
    if (source.isEmpty) {
      throw const StoryTranslationException(
        'Source text for translation cannot be empty.',
      );
    }

    if (forcedEmptyText) {
      throw const StoryTranslationException('Translation produced empty text.');
    }

    if (request.targetLanguage == request.sourceLanguage) {
      throw const StoryTranslationException(
        'Target language must differ from source language.',
      );
    }

    return StoryTranslationDraft(
      textContent: '[${request.targetLanguage.value}] $source',
      language: request.targetLanguage,
      format: request.sourceFormat,
      providerLabel: 'in_memory',
      supportLevel: AnalysisSupportLevel.strong,
    );
  }
}
