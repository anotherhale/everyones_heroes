import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/observation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_understanding_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');

  group('InMemoryStoryTranscriptionAdapter', () {
    test('returns deterministic non-empty transcript', () async {
      final adapter = InMemoryStoryTranscriptionAdapter();
      final media = MediaReference('memory://audio/1');
      final result = await adapter.transcribe(
        TranscribeStoryMediaRequest(
          storyId: StoryId.generate(),
          sourceRepresentationId: StoryRepresentationId.generate(),
          mediaReference: media,
          language: english,
          processingVersion: 'hs4-v1',
          mediaBytes: List<int>.generate(40, (i) => i),
        ),
      );

      expect(result.text, isNotEmpty);
      expect(result.language, english);
      expect(result.providerLabel, 'in_memory');
      expect(result.supportLevel, AnalysisSupportLevel.strong);
    });

    test('rejects missing media bytes', () async {
      final adapter = InMemoryStoryTranscriptionAdapter();
      expect(
        () => adapter.transcribe(
          TranscribeStoryMediaRequest(
            storyId: StoryId.generate(),
            sourceRepresentationId: StoryRepresentationId.generate(),
            mediaReference: MediaReference('memory://x'),
            language: english,
            processingVersion: 'hs4-v1',
          ),
        ),
        throwsA(isA<StoryTranscriptionException>()),
      );
    });

    test('forced failure throws', () async {
      final adapter = InMemoryStoryTranscriptionAdapter(
        forcedFailureMessage: 'down',
      );
      expect(
        () => adapter.transcribe(
          TranscribeStoryMediaRequest(
            storyId: StoryId.generate(),
            sourceRepresentationId: StoryRepresentationId.generate(),
            mediaReference: MediaReference('memory://x'),
            language: english,
            processingVersion: 'hs4-v1',
            mediaBytes: [1, 2, 3],
          ),
        ),
        throwsA(isA<StoryTranscriptionException>()),
      );
    });
  });

  group('InMemoryStoryUnderstandingAdapter', () {
    test('maps known keywords to closed enums', () async {
      final adapter = InMemoryStoryUnderstandingAdapter();
      final draft = await adapter.analyze(
        AnalyzeStoryContentRequest(
          storyId: StoryId.generate(),
          sourceRepresentationIds: [StoryRepresentationId.generate()],
          sourceText:
              'After military service and loss, courage helped with starting over.',
          analysisLanguage: english,
          processingVersion: 'hs4-v1',
        ),
      );

      expect(draft.candidateClassification, isNotNull);
      expect(
        draft.candidateClassification!.subjects,
        contains(StorySubject.military),
      );
      expect(draft.providerLabel, 'in_memory');
      expect(draft.observations, isNotEmpty);
    });

    test('unknown labels become uncertainty, not new taxonomy', () async {
      final adapter = InMemoryStoryUnderstandingAdapter(
        injectUnknownSubjectLabel: 'totally_made_up_subject',
      );
      final draft = await adapter.analyze(
        AnalyzeStoryContentRequest(
          storyId: StoryId.generate(),
          sourceRepresentationIds: [StoryRepresentationId.generate()],
          sourceText: 'A quiet reflective story.',
          analysisLanguage: english,
          processingVersion: 'hs4-v1',
        ),
      );

      expect(
        draft.observations.any((o) => o.kind == ObservationKind.uncertainty),
        isTrue,
      );
      expect(
        draft.candidateClassification?.subjects
                .any((s) => s.name == 'totally_made_up_subject') ??
            false,
        isFalse,
      );
    });

    test('rejects empty source text', () async {
      final adapter = InMemoryStoryUnderstandingAdapter();
      expect(
        () => adapter.analyze(
          AnalyzeStoryContentRequest(
            storyId: StoryId.generate(),
            sourceRepresentationIds: [StoryRepresentationId.generate()],
            sourceText: '   ',
            analysisLanguage: english,
            processingVersion: 'hs4-v1',
          ),
        ),
        throwsA(isA<StoryUnderstandingException>()),
      );
    });

    test('rejects forbidden identity claim injection path', () async {
      final adapter = InMemoryStoryUnderstandingAdapter(
        injectMalformedIdentityClaim: true,
      );
      expect(
        () => adapter.analyze(
          AnalyzeStoryContentRequest(
            storyId: StoryId.generate(),
            sourceRepresentationIds: [StoryRepresentationId.generate()],
            sourceText: 'Ordinary content.',
            analysisLanguage: english,
            processingVersion: 'hs4-v1',
          ),
        ),
        throwsA(isA<StoryUnderstandingException>()),
      );
    });
  });
}
