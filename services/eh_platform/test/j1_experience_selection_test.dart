import 'package:eh_platform/eh_platform.dart';
import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';
import 'package:eh_platform/src/experience/application/models/experience_type.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/evidence_source.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/strength.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:test/test.dart';

BehaviorPattern _consistencyPattern() {
  final now = DateTime.utc(2026, 1, 1);
  return BehaviorPattern(
    type: BehaviorPatternType.consistency,
    strength: const Strength(0.8),
    supportingEvidence: List.generate(
      3,
      (i) => BehavioralEvidence(
        type: BehavioralEvidenceType.discipline,
        source: ReflectionEvidenceSource(reflectionId: ReflectionId('r$i')),
        strength: const Strength(0.8),
        observedAt: now.add(Duration(days: i)),
      ),
    ),
    firstObservedAt: now,
    lastObservedAt: now.add(const Duration(days: 2)),
  );
}

void main() {
  group('DeterministicExperienceSelectionService', () {
    const selection = DeterministicExperienceSelectionService();

    test('consistency pattern selects consistency-next-step', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow'),
        behaviorPatterns: [_consistencyPattern()],
      );

      final experience = selection.selectFor(journey);

      expect(experience.id, 'consistency-next-step');
      expect(experience.type, ExperienceType.reflection);
      expect(experience.title, 'Keep Showing Up');
      expect(experience.rationale, isNotNull);
      expect(experience.explanationSources, hasLength(1));
      expect(experience.explanationSources.first.kind, 'behavior_pattern');
      expect(experience.explanationSources.first.value, 'consistency');
    });

    test('empty / unknown patterns select default-reflection', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow'),
      );

      final experience = selection.selectFor(journey);

      expect(experience.id, 'default-reflection');
      expect(experience.type, ExperienceType.reflection);
      expect(experience.title, 'Take the Next Step');
      expect(experience.rationale, isNull);
      expect(experience.explanationSources, isEmpty);
    });

    test('selection is deterministic for identical inputs', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow'),
        behaviorPatterns: [_consistencyPattern()],
      );

      final a = selection.selectFor(journey);
      final b = selection.selectFor(journey);
      expect(a.id, b.id);
      expect(a.title, b.title);
      expect(a.rationale, b.rationale);
    });
  });

  group('AdaptiveExperienceComposer (HS.8)', () {
    const selection = DeterministicExperienceSelectionService();
    const composer = AdaptiveExperienceComposer(
      reflectionSelectionService: selection,
    );

    test('theme-overlapping Story candidate selects adaptive-story', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow'),
      );
      final candidate = DiscoverableStoryCandidate(
        storyId: 'story-1',
        heroId: 'hero-1',
        title: 'Rising Again',
        matchedThemeIds: const ['courage'],
        themeOverlapCount: 1,
        patternBoost: 0.0,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final experience = composer.compose(
        journey: journey,
        signals: AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['courage'],
        ),
        candidates: [candidate],
      );

      expect(experience.id, 'adaptive-story-story-1');
      expect(experience.type, ExperienceType.story);
      expect(experience.title, 'Rising Again');
      expect(experience.target, isNotNull);
    });

    test('no candidates falls back to UI.3 reflection', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow'),
        behaviorPatterns: [_consistencyPattern()],
      );

      final experience = composer.compose(
        journey: journey,
        signals: AdaptiveDiscoverySignals(
          behaviorPatterns: journey.behaviorPatterns,
        ),
        candidates: const [],
      );

      expect(experience.id, 'consistency-next-step');
      expect(experience.type, ExperienceType.reflection);
    });

    test('zero theme overlap falls back to UI.3 reflection', () {
      final journey = Journey(
        id: JourneyId('j1'),
        vision: JourneyVision('Grow'),
      );
      final candidate = DiscoverableStoryCandidate(
        storyId: 'story-1',
        heroId: 'hero-1',
        title: 'Rising Again',
        matchedThemeIds: const [],
        themeOverlapCount: 0,
        patternBoost: 0.5,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final experience = composer.compose(
        journey: journey,
        signals: AdaptiveDiscoverySignals(),
        candidates: [candidate],
      );

      expect(experience.id, 'default-reflection');
    });
  });

  group('EmptyDiscoverableStoryCandidatePort', () {
    test('defaults to empty candidates', () async {
      const port = EmptyDiscoverableStoryCandidatePort();
      final result = await port.findRelevant(AdaptiveDiscoverySignals());
      expect(result, isEmpty);
    });
  });
}
