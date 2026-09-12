import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_translation_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_authoring_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_translation_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');
  final spanish = LanguageCode('es');

  group('InMemoryStoryAuthoringAdapter', () {
    test('is deterministic for script format', () async {
      final adapter = InMemoryStoryAuthoringAdapter();
      final request = GenerateStoryAuthoringRequest(
        storyId: StoryId.generate(),
        sourceRepresentationId: StoryRepresentationId.generate(),
        sourceText: 'Courage after loss.',
        language: english,
        targetFormat: StoryRepresentationFormat.script,
        processingVersion: 'hs5-v1',
      );

      final a = await adapter.generate(request);
      final b = await adapter.generate(request);
      expect(a.textContent, b.textContent);
      expect(a.format, StoryRepresentationFormat.script);
      expect(a.textContent, contains('SCRIPT'));
    });

    test('rejects empty source', () async {
      final adapter = InMemoryStoryAuthoringAdapter();
      expect(
        () => adapter.generate(
          GenerateStoryAuthoringRequest(
            storyId: StoryId.generate(),
            sourceRepresentationId: StoryRepresentationId.generate(),
            sourceText: '   ',
            language: english,
            targetFormat: StoryRepresentationFormat.script,
            processingVersion: 'hs5-v1',
          ),
        ),
        throwsA(isA<StoryAuthoringException>()),
      );
    });
  });

  group('InMemoryStoryTranslationAdapter', () {
    test('prefixes target language deterministically', () async {
      final adapter = InMemoryStoryTranslationAdapter();
      final draft = await adapter.translate(
        TranslateStoryRepresentationRequest(
          storyId: StoryId.generate(),
          sourceRepresentationId: StoryRepresentationId.generate(),
          sourceText: 'Hello hero',
          sourceLanguage: english,
          targetLanguage: spanish,
          sourceFormat: StoryRepresentationFormat.script,
          processingVersion: 'hs5-v1',
        ),
      );
      expect(draft.language, spanish);
      expect(draft.textContent, startsWith('[es]'));
    });
  });
}
