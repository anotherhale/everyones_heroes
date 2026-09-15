import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/transcribe_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/transcription/file_story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/transcription/file_transcription_completion_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ProxyStoryTranscriptionAdapter', () {
    test('maps EH request/response through proxy contract', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'text': 'Proxy transcript text',
            'language': 'en',
            'providerLabel': 'openai_via_eh_proxy',
            'supportLevel': 'moderate',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = ProxyStoryTranscriptionAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
        authToken: 'token',
      );

      final result = await adapter.transcribe(
        TranscribeStoryMediaRequest(
          storyId: StoryId('story-1'),
          sourceRepresentationId: StoryRepresentationId('rep-1'),
          mediaReference: const MediaReference('file://audio.wav'),
          language: LanguageCode('en'),
          processingVersion: 'hs4-v1',
          requestId: 'req-1',
          mediaBytes: [1, 2, 3],
        ),
      );

      expect(captured.url.path, '/story-transcriptions');
      expect(captured.headers['authorization'], 'Bearer token');
      final body = jsonDecode(captured.body) as Map;
      expect(body['storyId'], 'story-1');
      expect(body['mediaBase64'], isNotEmpty);
      expect(result.text, 'Proxy transcript text');
      expect(result.providerLabel, 'openai_via_eh_proxy');
    });

    test('maps network/provider failures to StoryTranscriptionException',
        () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'boom'}), 502);
      });
      final adapter = ProxyStoryTranscriptionAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
      );

      expect(
        () => adapter.transcribe(
          TranscribeStoryMediaRequest(
            storyId: StoryId('story-1'),
            sourceRepresentationId: StoryRepresentationId('rep-1'),
            mediaReference: const MediaReference('file://audio.wav'),
            language: LanguageCode('en'),
            processingVersion: 'hs4-v1',
            mediaBytes: [1, 2, 3],
          ),
        ),
        throwsA(isA<StoryTranscriptionException>()),
      );
    });

    test('maps malformed provider response', () async {
      final client = MockClient((request) async {
        return http.Response('not-json', 200);
      });
      final adapter = ProxyStoryTranscriptionAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
      );

      expect(
        () => adapter.transcribe(
          TranscribeStoryMediaRequest(
            storyId: StoryId('story-1'),
            sourceRepresentationId: StoryRepresentationId('rep-1'),
            mediaReference: const MediaReference('file://audio.wav'),
            language: LanguageCode('en'),
            processingVersion: 'hs4-v1',
            mediaBytes: [9, 9, 9],
          ),
        ),
        throwsA(
          isA<StoryTranscriptionException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('malformed'),
          ),
        ),
      );
    });
  });

  group('InMemoryStoryTranscriptionAdapter development path', () {
    test('produces deterministic output without network', () async {
      final adapter = InMemoryStoryTranscriptionAdapter();
      final first = await adapter.transcribe(
        TranscribeStoryMediaRequest(
          storyId: StoryId('s'),
          sourceRepresentationId: StoryRepresentationId('r'),
          mediaReference: const MediaReference('mem://x'),
          language: LanguageCode('en'),
          processingVersion: 'hs4-v1',
          mediaBytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      );
      final second = await adapter.transcribe(
        TranscribeStoryMediaRequest(
          storyId: StoryId('s'),
          sourceRepresentationId: StoryRepresentationId('r'),
          mediaReference: const MediaReference('mem://x'),
          language: LanguageCode('en'),
          processingVersion: 'hs4-v1',
          mediaBytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      );
      expect(first.text, second.text);
      expect(first.providerLabel, 'in_memory');
    });
  });

  group('FileStoryTranscriptionJobStore', () {
    test('persists and reloads job status across store instances', () async {
      final root = await Directory.systemTemp.createTemp('hs11-jobs-');
      addTearDown(() => root.delete(recursive: true));

      final store = FileStoryTranscriptionJobStore(rootDirectory: root);
      final storyId = StoryId.generate();
      final sourceId = StoryRepresentationId.generate();
      store.save(
        StoryTranscriptionJob(
          storyId: storyId,
          sourceRepresentationId: sourceId,
          status: StoryTranscriptionJobStatus.completed,
          requestId: 'req-1',
          transcriptRepresentationId: StoryRepresentationId.generate(),
          updatedAt: DateTime.utc(2026, 9, 15),
          startedAt: DateTime.utc(2026, 9, 15),
          completedAt: DateTime.utc(2026, 9, 15),
        ),
      );

      final reloaded = FileStoryTranscriptionJobStore(rootDirectory: root);
      final job = reloaded.find(
        storyId: storyId,
        sourceRepresentationId: sourceId,
      );
      expect(job, isNotNull);
      expect(job!.status, StoryTranscriptionJobStatus.completed);
      expect(job.requestId, 'req-1');
    });
  });

  group('FileTranscriptionCompletionStore', () {
    test('round-trips successful completion records', () async {
      final root = await Directory.systemTemp.createTemp('hs11-tx-complete-');
      addTearDown(() => root.delete(recursive: true));
      final stories = FileStoryRepository(rootDirectory: root);

      final story = Story.create(
        id: StoryId.generate(),
        heroId: HeroId.generate(),
        title: StoryTitle('Durable'),
        narrative: StoryNarrative.provisional(),
        originalLanguage: LanguageCode('en'),
      );
      await stories.save(story);

      final store = FileTranscriptionCompletionStore(
        rootDirectory: root,
        storyRepository: stories,
      );
      final transcriptId = StoryRepresentationId.generate();
      store.save(
        'req-durable',
        TranscribeStoryResponse(
          story: story,
          storyId: story.id,
          transcriptRepresentationId: transcriptId,
          mediaReference: const MediaReference('file://audio.wav'),
        ),
      );

      final reloaded = FileTranscriptionCompletionStore(
        rootDirectory: root,
        storyRepository: stories,
      );
      final found = reloaded.find('req-durable');
      expect(found, isNotNull);
      expect(found!.transcriptRepresentationId, transcriptId);
      expect(found.storyId, story.id);
    });
  });

  test('TranscriptionFailureKind maps common messages', () {
    expect(
      TranscriptionFailureKind.fromMessage('AI consent required'),
      TranscriptionFailureKind.consentMissing,
    );
    expect(
      TranscriptionFailureKind.fromMessage('proxy timed out'),
      TranscriptionFailureKind.timeout,
    );
    expect(
      TranscriptionFailureKind.fromMessage('network socket failure'),
      TranscriptionFailureKind.networkFailure,
    );
  });
}
