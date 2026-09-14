import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late FileStoryRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('eh-file-story-repo-');
    repository = FileStoryRepository(rootDirectory: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Story buildStory({
    required String id,
    required String heroId,
    StoryLifecycleStatus status = StoryLifecycleStatus.draft,
    String title = 'Story',
  }) {
    final now = DateTime.utc(2024, 3, 1);
    return Story(
      id: StoryId(id),
      heroId: HeroId(heroId),
      title: StoryTitle(title),
      narrative: StoryNarrative('Narrative for $title'),
      originalLanguage: LanguageCode('en'),
      lifecycleStatus: status,
      visibility: StoryVisibility.community,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('save writes json and findById returns story', () async {
    final story = buildStory(id: 'story-a', heroId: 'hero-1');
    await repository.save(story);

    expect(
      File(p.join(tempDir.path, 'stories', 'story-a.json')).existsSync(),
      isTrue,
    );

    final loaded = await repository.findById(const StoryId('story-a'));
    expect(loaded, isNotNull);
    expect(loaded!.title.value, 'Story');
    expect(await repository.exists(const StoryId('story-a')), isTrue);
  });

  test('findByHeroId filters by hero', () async {
    await repository.save(buildStory(id: 's1', heroId: 'hero-a', title: 'A1'));
    await repository.save(buildStory(id: 's2', heroId: 'hero-b', title: 'B1'));
    await repository.save(buildStory(id: 's3', heroId: 'hero-a', title: 'A2'));

    final forHero = await repository.findByHeroId(const HeroId('hero-a'));
    expect(forHero.map((s) => s.id.value), unorderedEquals(['s1', 's3']));
  });

  test('findPublished returns only published stories', () async {
    await repository.save(
      buildStory(
        id: 'pub',
        heroId: 'hero-1',
        status: StoryLifecycleStatus.published,
        title: 'Published',
      ),
    );
    await repository.save(
      buildStory(
        id: 'draft',
        heroId: 'hero-1',
        status: StoryLifecycleStatus.draft,
        title: 'Draft',
      ),
    );

    final published = await repository.findPublished();
    expect(published, hasLength(1));
    expect(published.single.id.value, 'pub');
  });

  test('survives process restart via disk', () async {
    await repository.save(buildStory(id: 'persist', heroId: 'hero-1'));

    final restarted = FileStoryRepository(rootDirectory: tempDir);
    final loaded = await restarted.findById(const StoryId('persist'));
    expect(loaded, isNotNull);
    expect(loaded!.heroId.value, 'hero-1');
  });

  test('delete removes file and cache', () async {
    await repository.save(buildStory(id: 'gone', heroId: 'hero-1'));
    await repository.delete(const StoryId('gone'));

    expect(await repository.findById(const StoryId('gone')), isNull);
    expect(
      File(p.join(tempDir.path, 'stories', 'gone.json')).existsSync(),
      isFalse,
    );
  });
}
