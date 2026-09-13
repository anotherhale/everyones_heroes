import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../builders/behavioral_evidence_builder.dart';

void main() {
  const composer = AdaptiveExperienceComposer(
    reflectionSelectionService: DeterministicExperienceSelectionService(),
  );

  group('AdaptiveExperienceComposer', () {
    test('selects AdaptiveExperience(type: story) with target and rationale', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow.'),
      );
      final storyId = StoryId('story-1');
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [NarrativeThemeId('courage')],
      );
      final candidates = [
        DiscoverableStoryCandidate(
          storyId: storyId,
          heroId: HeroId('hero-1'),
          title: 'Courage Under Fire',
          matchedThemeIds: [NarrativeThemeId('courage')],
          themeOverlapCount: 1,
          patternBoost: 0.0,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ];

      final experience = composer.compose(
        journey: journey,
        signals: signals,
        candidates: candidates,
      );

      expect(experience.type, ExperienceType.story);
      expect(experience.id, 'adaptive-story-story-1');
      expect(experience.title, 'Courage Under Fire');
      expect(experience.target, StoryExperienceTarget(storyId: storyId));
      expect(
        experience.rationale,
        'This story connects with themes you\'ve recently reflected on.',
      );
    });

    test('patterns enrich rationale when available', () {
      final journey = _journeyWithConsistency();
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [NarrativeThemeId('courage')],
        behaviorPatterns: journey.behaviorPatterns,
      );
      final candidates = [
        DiscoverableStoryCandidate(
          storyId: StoryId('story-1'),
          heroId: HeroId('hero-1'),
          title: 'Courage',
          matchedThemeIds: [NarrativeThemeId('courage')],
          themeOverlapCount: 1,
          patternBoost: 0.8,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ];

      final experience = composer.compose(
        journey: journey,
        signals: signals,
        candidates: candidates,
      );

      expect(experience.type, ExperienceType.story);
      expect(
        experience.rationale,
        contains('patterns of consistency'),
      );
    });

    test('falls back to reflection when no candidates (cold start)', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow.'),
      );

      final experience = composer.compose(
        journey: journey,
        signals: AdaptiveDiscoverySignals(),
        candidates: const [],
      );

      expect(experience.type, ExperienceType.reflection);
      expect(experience.id, 'default-reflection');
      expect(experience.target, isNull);
    });

    test('themes without matching candidates fall back to reflection', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow.'),
      );

      final experience = composer.compose(
        journey: journey,
        signals: AdaptiveDiscoverySignals(
          narrativeThemeIds: [NarrativeThemeId('courage')],
        ),
        candidates: const [],
      );

      expect(experience.type, ExperienceType.reflection);
    });

    test('ignores candidates with zero theme overlap', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow.'),
      );

      final experience = composer.compose(
        journey: journey,
        signals: AdaptiveDiscoverySignals(),
        candidates: [
          DiscoverableStoryCandidate(
            storyId: StoryId('story-1'),
            heroId: HeroId('hero-1'),
            title: 'No Overlap',
            matchedThemeIds: const [],
            themeOverlapCount: 0,
            patternBoost: 0.9,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      expect(experience.type, ExperienceType.reflection);
    });
  });
}

Journey _journeyWithConsistency() {
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

  return Journey(
    id: JourneyId('journey-patterns'),
    vision: JourneyVision('Build consistency.'),
    behaviorPatterns: [
      BehaviorPattern(
        type: BehaviorPatternType.consistency,
        strength: const Strength(0.8),
        supportingEvidence: evidence,
        firstObservedAt: DateTime(2026, 8, 1),
        lastObservedAt: DateTime(2026, 8, 2),
      ),
    ],
  );
}
