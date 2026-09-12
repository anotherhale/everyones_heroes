import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_port.dart';

/// Deterministic in-memory authoring adapter (no network / no AI SDK).
final class InMemoryStoryAuthoringAdapter implements StoryAuthoringPort {
  InMemoryStoryAuthoringAdapter({
    this.forcedFailureMessage,
    this.forcedEmptyText = false,
  });

  final String? forcedFailureMessage;
  final bool forcedEmptyText;

  @override
  Future<StoryAuthoringDraft> generate(
    GenerateStoryAuthoringRequest request,
  ) async {
    if (forcedFailureMessage != null) {
      throw StoryAuthoringException(forcedFailureMessage!);
    }

    final source = request.sourceText.trim();
    if (source.isEmpty) {
      throw const StoryAuthoringException(
        'Source text for authoring cannot be empty.',
      );
    }

    if (forcedEmptyText) {
      throw const StoryAuthoringException('Authoring produced empty text.');
    }

    final context = request.understandingContext?.trim();
    final contextSuffix =
        (context == null || context.isEmpty) ? '' : ' Context: $context';

    final text = switch (request.targetFormat) {
      StoryRepresentationFormat.script =>
        'SCRIPT for story ${request.storyId.value} '
            '(from ${request.sourceRepresentationId.value}): '
            '$source$contextSuffix',
      StoryRepresentationFormat.shortForm =>
        'SHORT FORM for story ${request.storyId.value}: '
            '${_truncate(source, 160)}$contextSuffix',
      StoryRepresentationFormat.longForm =>
        'LONG FORM for story ${request.storyId.value}: '
            '$source$contextSuffix',
      _ => throw StoryAuthoringException(
          'Unsupported authoring format: ${request.targetFormat.name}',
        ),
    };

    return StoryAuthoringDraft(
      textContent: text,
      format: request.targetFormat,
      language: request.language,
      providerLabel: 'in_memory',
      supportLevel: AnalysisSupportLevel.strong,
      notes: 'deterministic',
    );
  }

  static String _truncate(String value, int max) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}…';
  }
}
