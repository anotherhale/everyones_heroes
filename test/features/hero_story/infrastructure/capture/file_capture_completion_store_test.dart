import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/capture/file_capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late FileStoryRepository storyRepository;
  late FileCaptureCompletionStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('eh-capture-store-');
    storyRepository = FileStoryRepository(rootDirectory: tempDir);
    store = FileCaptureCompletionStore(
      rootDirectory: tempDir,
      storyRepository: storyRepository,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  CompleteStoryCaptureResponse buildResponse() {
    final now = DateTime.utc(2024, 7, 1);
    final story = Story(
      id: const StoryId('story-cap-1'),
      heroId: const HeroId('hero-cap-1'),
      title: StoryTitle('Untitled Story'),
      narrative: StoryNarrative.provisional(),
      originalLanguage: LanguageCode('en'),
      createdAt: now,
      updatedAt: now,
    );

    return CompleteStoryCaptureResponse(
      story: story,
      storyId: story.id,
      representationId: const StoryRepresentationId('rep-cap-1'),
      mediaReference: MediaReference('file:///tmp/capture.m4a'),
      createdStory: true,
      idempotentReplay: false,
    );
  }

  test('save and find round-trip in memory', () {
    final response = buildResponse();
    store.save('session-1', response);

    final found = store.find('session-1');
    expect(found, isNotNull);
    expect(found!.storyId.value, 'story-cap-1');
    expect(found.representationId.value, 'rep-cap-1');
    expect(found.mediaReference.uri, 'file:///tmp/capture.m4a');
    expect(found.createdStory, isTrue);
    expect(found.story.narrative.isProvisional, isTrue);
  });

  test('persists index to disk and reloads after restart', () {
    store.save('session-1', buildResponse());

    final indexFile = File(p.join(tempDir.path, 'capture_completions.json'));
    expect(indexFile.existsSync(), isTrue);
    expect(indexFile.readAsStringSync(), contains('story-cap-1'));
    expect(indexFile.readAsStringSync(), contains('"story"'));

    final restarted = FileCaptureCompletionStore(
      rootDirectory: tempDir,
      storyRepository: FileStoryRepository(rootDirectory: tempDir),
    );
    final found = restarted.find('session-1');
    expect(found, isNotNull);
    expect(found!.story.title.value, 'Untitled Story');
    expect(found.story.pullDomainEvents(), isEmpty);
    expect(found.mediaReference.uri, 'file:///tmp/capture.m4a');
  });

  test('remove deletes session from memory and disk', () {
    store.save('session-1', buildResponse());
    store.remove('session-1');

    expect(store.find('session-1'), isNull);

    final restarted = FileCaptureCompletionStore(
      rootDirectory: tempDir,
      storyRepository: storyRepository,
    );
    expect(restarted.find('session-1'), isNull);
  });
}
