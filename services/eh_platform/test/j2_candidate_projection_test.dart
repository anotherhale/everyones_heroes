import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/modules/hero_story/hero_story_module.dart';
import 'package:test/test.dart';

StoryCandidateEligibilityFacts _eligible({
  String storyId = 'live-story-1',
  String heroId = 'live-hero-1',
  String title = 'Live Finding Direction',
  List<String> themeIds = const ['discovery', 'purpose'],
  DateTime? updatedAt,
  String storyVisibility = 'public',
  String heroVisibility = 'public',
}) {
  return StoryCandidateEligibilityFacts(
    storyId: storyId,
    heroId: heroId,
    title: title,
    themeIds: themeIds,
    updatedAt: updatedAt ?? DateTime.utc(2026, 6, 1),
    lifecycleStatus: 'published',
    storyVisibility: storyVisibility,
    hasProvisionalNarrative: false,
    hasAuthoritativeRepresentation: true,
    heroStatus: 'active',
    heroVisibility: heroVisibility,
  );
}

void main() {
  group('ProjectDiscoverableStoryCandidateUseCase (projection)', () {
    late InMemoryDiscoverableStoryCandidateProjection projection;
    late ProjectDiscoverableStoryCandidateUseCase useCase;

    setUp(() {
      projection = InMemoryDiscoverableStoryCandidateProjection();
      useCase = ProjectDiscoverableStoryCandidateUseCase(
        projection: projection,
      );
    });

    test('valid Story → projection', () async {
      final result = await useCase.execute(_eligible());
      expect(result.wasUpserted, isTrue);
      expect(await projection.exists('live-story-1'), isTrue);
      final records = await projection.listCandidates();
      expect(records.single.storyId, 'live-story-1');
      expect(records.single.themeIds, ['discovery', 'purpose']);
      expect(records.single.title, 'Live Finding Direction');
    });

    test('invalid Story → excluded', () async {
      final result = await useCase.execute(
        _eligible().copyWithLifecycle('draft'),
      );
      expect(result.wasUpserted, isFalse);
      expect(await projection.exists('live-story-1'), isFalse);
      expect(await projection.listCandidates(), isEmpty);
    });

    test('valid Hero + invalid Story → excluded', () async {
      await useCase.execute(
        _eligible(storyVisibility: 'private'),
      );
      expect(await projection.listCandidates(), isEmpty);
    });

    test('valid Story + invalid Hero → excluded', () async {
      await useCase.execute(
        _eligible(heroVisibility: 'private'),
      );
      expect(await projection.listCandidates(), isEmpty);
    });

    test('theme IDs preserved (catalog-valid, sorted unique)', () async {
      await useCase.execute(
        _eligible(themeIds: const ['purpose', 'courage', 'courage']),
      );
      final record = (await projection.listCandidates()).single;
      expect(record.themeIds, ['courage', 'purpose']);
    });

    test('deterministic projection mapping', () async {
      final a = await useCase.execute(_eligible());
      projection.clear();
      final b = await useCase.execute(_eligible());
      expect(a.record!.storyId, b.record!.storyId);
      expect(a.record!.themeIds, b.record!.themeIds);
      expect(a.record!.title, b.record!.title);
      expect(a.record!.updatedAt, b.record!.updatedAt);
    });

    test('upsert behavior replaces existing row', () async {
      await useCase.execute(_eligible(title: 'First'));
      await useCase.execute(_eligible(title: 'Second'));
      final records = await projection.listCandidates();
      expect(records, hasLength(1));
      expect(records.single.title, 'Second');
    });

    test('eligibility removal/invalidation deletes projection row', () async {
      await useCase.execute(_eligible());
      expect(await projection.exists('live-story-1'), isTrue);

      final removed = await useCase.execute(
        _eligible().copyWithLifecycle('archived'),
      );
      expect(removed.wasUpserted, isFalse);
      expect(removed.reason, 'story_not_published');
      expect(await projection.exists('live-story-1'), isFalse);
    });
  });

  group('Live StoryCandidateSource (in-memory projection)', () {
    test('empty projection → no candidates', () async {
      final heroStory = HeroStoryModule.compose();
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: const ['discovery']),
      );
      expect(result, isEmpty);
    });

    test('single candidate with theme match', () async {
      final projection = InMemoryDiscoverableStoryCandidateProjection();
      final project = ProjectDiscoverableStoryCandidateUseCase(
        projection: projection,
      );
      await project.execute(_eligible());

      final heroStory = HeroStoryModule.compose(
        candidateSource: projection,
        projection: projection,
      );
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: const ['discovery']),
      );
      expect(result, hasLength(1));
      expect(result.first.storyId, 'live-story-1');
      expect(result.first.themeOverlapCount, 1);
    });

    test('multiple candidates — deterministic ordering via ranker', () async {
      final projection = InMemoryDiscoverableStoryCandidateProjection();
      final project = ProjectDiscoverableStoryCandidateUseCase(
        projection: projection,
      );
      await project.execute(
        _eligible(
          storyId: 'story-courage-alone',
          title: 'Alone',
          themeIds: const ['courage'],
          updatedAt: DateTime.utc(2026, 1, 11),
        ),
      );
      await project.execute(
        _eligible(
          storyId: 'story-rising-again',
          title: 'Rising',
          themeIds: const ['courage', 'perseverance'],
          updatedAt: DateTime.utc(2026, 1, 10),
        ),
      );

      final heroStory = HeroStoryModule.compose(
        candidateSource: projection,
        projection: projection,
      );
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['courage', 'perseverance'],
        ),
      );
      expect(result.first.storyId, 'story-rising-again');
      expect(result.first.themeOverlapCount, 2);
    });

    test('irrelevant candidates excluded (no theme overlap)', () async {
      final projection = InMemoryDiscoverableStoryCandidateProjection();
      final project = ProjectDiscoverableStoryCandidateUseCase(
        projection: projection,
      );
      await project.execute(
        _eligible(themeIds: const ['leadership', 'service']),
      );

      final heroStory = HeroStoryModule.compose(
        candidateSource: projection,
        projection: projection,
      );
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: const ['love']),
      );
      expect(result, isEmpty);
    });
  });
}

extension on StoryCandidateEligibilityFacts {
  StoryCandidateEligibilityFacts copyWithLifecycle(String lifecycleStatus) {
    return StoryCandidateEligibilityFacts(
      storyId: storyId,
      heroId: heroId,
      title: title,
      themeIds: themeIds,
      updatedAt: updatedAt,
      lifecycleStatus: lifecycleStatus,
      storyVisibility: storyVisibility,
      hasProvisionalNarrative: hasProvisionalNarrative,
      hasAuthoritativeRepresentation: hasAuthoritativeRepresentation,
      heroStatus: heroStatus,
      heroVisibility: heroVisibility,
    );
  }
}
