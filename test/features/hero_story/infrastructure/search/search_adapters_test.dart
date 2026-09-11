import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_hero_search_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hero search filters by experience area and language', () async {
    final repo = InMemoryHeroRepository();
    final matching = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Sam',
        experienceAreas: const ['Military'],
        languages: [LanguageCode('en')],
      ),
    );
    final other = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Pat',
        experienceAreas: const ['Arts'],
        languages: [LanguageCode('es')],
      ),
    );
    await repo.save(matching);
    await repo.save(other);

    final search = InMemoryHeroSearchAdapter(repo);
    final ids = await search.search(
      HeroSearchQuery(
        experienceArea: 'Military',
        language: LanguageCode('en'),
      ),
    );

    expect(ids, [matching.id]);
  });

  test('story search excludes unpublished by default', () async {
    final heroes = InMemoryHeroRepository();
    final stories = InMemoryStoryRepository();
    final heroId = HeroId.generate();
    await heroes.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(displayName: 'Hero'),
      ),
    );

    final draft = Story.create(
      id: StoryId.generate(),
      heroId: heroId,
      title: StoryTitle('Draft'),
      narrative: StoryNarrative('Still a draft story.'),
      originalLanguage: LanguageCode('en'),
    );
    final published = Story.create(
      id: StoryId.generate(),
      heroId: heroId,
      title: StoryTitle('Published'),
      narrative: StoryNarrative('A published story.'),
      originalLanguage: LanguageCode('en'),
    );
    published
      ..submit()
      ..markReadyForReview()
      ..approve()
      ..changeVisibility(StoryVisibility.public)
      ..publish();

    await stories.save(draft);
    await stories.save(published);

    final ids = await InMemoryStorySearchAdapter(stories).search(
      const StorySearchQuery(text: 'story'),
    );

    expect(ids, [published.id]);
  });
}
