import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';

import '../../builders/behavioral_evidence_builder.dart';

void main() {
  const service = DeterministicExperienceSelectionService();

  group('DeterministicExperienceSelectionService', () {
    test('selects consistency experience when consistency is present', () {
      final journey = _journeyWithPattern(BehaviorPatternType.consistency);

      final experience = service.selectFor(journey);

      expect(experience.id, 'consistency-next-step');
      expect(experience.type, ExperienceType.mission);
      expect(experience.title, 'Keep Showing Up');
      expect(experience.action, ExperienceAction.begin);
      expect(
        experience.rationale,
        'You have been building consistency across your recent journey.',
      );
    });

    test('selects reflection when no recognized pattern exists', () {
      final journey = _journeyWithoutPatterns();

      final experience = service.selectFor(journey);

      expect(experience.id, 'default-reflection');
      expect(experience.type, ExperienceType.reflection);
      expect(experience.title, 'Take the Next Step');
      expect(experience.action, ExperienceAction.begin);
      expect(experience.rationale, isNull);
    });

    test('selection is deterministic for the same journey state', () {
      final journey = _journeyWithPattern(BehaviorPatternType.consistency);

      final first = service.selectFor(journey);
      final second = service.selectFor(journey);

      expect(first.id, second.id);
      expect(first.type, second.type);
      expect(first.title, second.title);
      expect(first.description, second.description);
      expect(first.action, second.action);
      expect(first.rationale, second.rationale);
    });
  });
}

Journey _journeyWithoutPatterns() {
  return Journey(
    id: JourneyId('journey-1'),
    vision: JourneyVision('Become the person I want to be'),
  );
}

Journey _journeyWithPattern(BehaviorPatternType type) {
  final evidenceType = switch (type) {
    BehaviorPatternType.consistency => BehavioralEvidenceType.discipline,
    BehaviorPatternType.discipline => BehavioralEvidenceType.discipline,
    BehaviorPatternType.resilience => BehavioralEvidenceType.resilience,
    BehaviorPatternType.courage => BehavioralEvidenceType.courage,
    BehaviorPatternType.leadership => BehavioralEvidenceType.leadership,
    BehaviorPatternType.service => BehavioralEvidenceType.service,
    BehaviorPatternType.purpose => BehavioralEvidenceType.purpose,
    BehaviorPatternType.selfAwareness => BehavioralEvidenceType.selfAwareness,
    BehaviorPatternType.avoidance => BehavioralEvidenceType.avoidance,
    BehaviorPatternType.responsibility => BehavioralEvidenceType.responsibility,
  };

  final evidence = [
    BehavioralEvidenceBuilder()
        .withType(evidenceType)
        .observedAt(DateTime(2026, 8, 1))
        .build(),
    BehavioralEvidenceBuilder()
        .withType(evidenceType)
        .observedAt(DateTime(2026, 8, 2))
        .build(),
  ];

  return Journey(
    id: JourneyId('journey-1'),
    vision: JourneyVision('Become the person I want to be'),
    behaviorPatterns: [
      BehaviorPattern(
        type: type,
        strength: const Strength(0.8),
        supportingEvidence: evidence,
        firstObservedAt: DateTime(2026, 8, 1),
        lastObservedAt: DateTime(2026, 8, 2),
      ),
    ],
  );
}
