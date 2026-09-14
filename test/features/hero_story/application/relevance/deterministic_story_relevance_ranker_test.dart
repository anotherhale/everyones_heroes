import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/deterministic_story_relevance_ranker.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../life_journey/builders/behavioral_evidence_builder.dart';

void main() {
  const ranker = DeterministicStoryRelevanceRanker();
  final courage = NarrativeThemeId('courage');
  final service = NarrativeThemeId('service');
  final growth = NarrativeThemeId('growth');

  group('DeterministicStoryRelevanceRanker', () {
    test('matching theme produces relevance', () {
      final summaries = [
        _summary(
          id: 's1',
          title: 'Courage Story',
          themes: [courage],
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        _summary(
          id: 's2',
          title: 'Unrelated',
          themes: [growth],
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ];

      final ranked = ranker.rank(
        summaries: summaries,
        signals: AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(ranked, hasLength(1));
      expect(ranked.single.storyId.value, 's1');
      expect(ranked.single.themeOverlapCount, 1);
      expect(ranked.single.patternBoost, 0.0);
    });

    test('no matching theme produces no candidates', () {
      final ranked = ranker.rank(
        summaries: [
          _summary(
            id: 's1',
            title: 'Growth',
            themes: [growth],
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        signals: AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(ranked, isEmpty);
    });

    test('patterns strengthen relevance when themes match', () {
      final summaries = [
        _summary(
          id: 's1',
          title: 'Courage',
          themes: [courage],
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ];

      final withoutPatterns = ranker.rank(
        summaries: summaries,
        signals: AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );
      final withPatterns = ranker.rank(
        summaries: summaries,
        signals: AdaptiveDiscoverySignals(
          narrativeThemeIds: [courage],
          behaviorPatterns: [_consistency(0.9)],
        ),
      );

      expect(withoutPatterns.single.patternBoost, 0.0);
      expect(withPatterns.single.patternBoost, 0.9);
      expect(
        withPatterns.single.relevanceScore,
        greaterThan(withoutPatterns.single.relevanceScore),
      );
    });

    test('higher theme overlap ranks first', () {
      final ranked = ranker.rank(
        summaries: [
          _summary(
            id: 'one-theme',
            title: 'One',
            themes: [courage],
            updatedAt: DateTime.utc(2026, 2, 1),
          ),
          _summary(
            id: 'two-themes',
            title: 'Two',
            themes: [courage, service],
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        signals: AdaptiveDiscoverySignals(
          narrativeThemeIds: [courage, service],
        ),
      );

      expect(ranked.map((c) => c.storyId.value).toList(), [
        'two-themes',
        'one-theme',
      ]);
    });

    test('equal overlap uses pattern boost then updatedAt then storyId', () {
      final ranked = ranker.rank(
        summaries: [
          _summary(
            id: 'b-story',
            title: 'B',
            themes: [courage],
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          _summary(
            id: 'a-story',
            title: 'A',
            themes: [courage],
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          _summary(
            id: 'newer',
            title: 'Newer',
            themes: [courage],
            updatedAt: DateTime.utc(2026, 2, 1),
          ),
        ],
        signals: AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(ranked.map((c) => c.storyId.value).toList(), [
        'newer',
        'a-story',
        'b-story',
      ]);
    });

    test('ranking is deterministic for identical inputs', () {
      final summaries = [
        _summary(
          id: 's2',
          title: 'Second',
          themes: [courage, service],
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
        _summary(
          id: 's1',
          title: 'First',
          themes: [courage],
          updatedAt: DateTime.utc(2026, 1, 3),
        ),
      ];
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [courage, service],
        behaviorPatterns: [_consistency(0.5)],
      );

      final first = ranker.rank(summaries: summaries, signals: signals);
      final second = ranker.rank(summaries: summaries, signals: signals);

      expect(
        first.map((c) => c.storyId.value).toList(),
        second.map((c) => c.storyId.value).toList(),
      );
      expect(first.first.relevanceScore, second.first.relevanceScore);
    });
  });
}

StoryDiscoverySummary _summary({
  required String id,
  required String title,
  required List<NarrativeThemeId> themes,
  required DateTime updatedAt,
}) {
  return StoryDiscoverySummary(
    storyId: StoryId(id),
    heroId: HeroId('hero-$id'),
    title: title,
    originalLanguage: LanguageCode('en'),
    availableLanguages: [LanguageCode('en')],
    subjects: const [],
    challenges: const [],
    narrativeThemeIds: themes,
    outcomes: const [],
    emotionalCharacters: const [],
    visibility: StoryVisibility.public,
    spiritualityCategory: SpiritualityCategory.nonSpiritual,
    profanity: SuitabilityLevel.none,
    violence: SuitabilityLevel.none,
    sexualContent: SuitabilityLevel.none,
    substanceUse: SuitabilityLevel.none,
    disturbingContent: SuitabilityLevel.none,
    authoritativeRepresentations: const [],
    matchReasons: const [],
    updatedAt: updatedAt,
    createdAt: updatedAt,
  );
}

BehaviorPattern _consistency(double strength) {
  final evidence = [
    BehavioralEvidenceBuilder()
        .withType(BehavioralEvidenceType.discipline)
        .observedAt(DateTime(2026, 8, 1))
        .build(),
    BehavioralEvidenceBuilder()
        .withType(BehavioralEvidenceType.discipline)
        .observedAt(DateTime(2026, 8, 2))
        .build(),
  ];

  return BehaviorPattern(
    type: BehaviorPatternType.consistency,
    strength: Strength(strength),
    supportingEvidence: evidence,
    firstObservedAt: DateTime(2026, 8, 1),
    lastObservedAt: DateTime(2026, 8, 2),
  );
}
