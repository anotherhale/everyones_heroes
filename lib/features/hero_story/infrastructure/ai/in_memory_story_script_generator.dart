import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_script_generator.dart';

/// Development / test [StoryScriptGenerator] — no network (SB.8).
///
/// Transforms supplied answers into a simple first-person narrative without
/// inventing facts beyond the provided material.
final class InMemoryStoryScriptGenerator implements StoryScriptGenerator {
  InMemoryStoryScriptGenerator({
    this.fixedContent,
    this.failWith,
  });

  /// When set, returned verbatim (after trim validation by the use case).
  String? fixedContent;

  /// When set, generate throws this exception.
  StoryScriptGeneratorException? failWith;

  int callCount = 0;
  StoryScriptGenerationMaterial? lastMaterial;

  @override
  Future<StoryScriptGenerationDraft> generate(
    StoryScriptGenerationMaterial material,
  ) async {
    callCount += 1;
    lastMaterial = material;
    final failure = failWith;
    if (failure != null) {
      throw failure;
    }

    final content = fixedContent ?? _composeFromAnswers(material);
    return StoryScriptGenerationDraft(
      content: content,
      language: material.language ?? LanguageCode('en'),
      providerLabel: 'in_memory_story_script_generator',
      processingVersion: StoryScriptGenerationDraft.defaultProcessingVersion,
    );
  }

  static String _composeFromAnswers(StoryScriptGenerationMaterial material) {
    final buffer = StringBuffer();
    buffer.writeln(
      'When I think about this part of my life, these are the experiences '
      'I want to share.',
    );
    buffer.writeln();
    for (final answer in material.answers) {
      buffer.writeln(answer.answer.trim());
      buffer.writeln();
    }
    buffer.writeln(
      'Looking back now, those moments still matter to me, and this is the '
      'story I am ready to tell.',
    );
    return buffer.toString().trim();
  }
}
