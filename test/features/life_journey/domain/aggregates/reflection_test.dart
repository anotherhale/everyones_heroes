import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/insights_generated.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  group('Reflection', () {
    late Reflection reflection;

    setUp(() {
      reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
    });

    test('creates reflection', () {
      expect(reflection.id, isNotNull);
      expect(reflection.responses, isEmpty);
      expect(reflection.insights, isEmpty);
      expect(reflection.behavioralEvidence, isEmpty);
      expect(reflection.isSubmitted, isFalse);
    });

    test('adds response', () {
      reflection.addResponse(
        const JournalResponse(response: 'Today I learned something.'),
      );

      expect(reflection.responses.length, 1);
    });

    test('adds multiple responses', () {
      reflection.addResponses([
        const JournalResponse(response: 'First'),
        const JournalResponse(response: 'Second'),
      ]);

      expect(reflection.responses.length, 2);
    });

    test('cannot submit empty reflection', () {
      expect(reflection.submit, throwsStateError);
    });

    test('submits reflection', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      expect(reflection.isSubmitted, isTrue);

      expect(reflection.submittedAt, isNotNull);
    });

    test('cannot submit twice', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      expect(reflection.submit, throwsStateError);
    });

    test('raises ReflectionSubmitted event', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();
      final events = reflection.pullDomainEvents();
      expectEventRaised<ReflectionSubmitted>(events);
      expectEventCount(events, 1);
    });

    test('cannot add response after submission', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      expect(
        () =>
            reflection.addResponse(const JournalResponse(response: 'Another')),
        throwsStateError,
      );
    });

    test('cannot add insights before submission', () {
      expect(
        () => reflection.addInsights([
          Insight(statement: 'Insight', confidence: 0.9),
        ]),
        throwsStateError,
      );
    });

    test('adds insights after submission', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      reflection.addInsights([Insight(statement: 'Insight', confidence: 0.9)]);

      expect(reflection.insights.length, 1);
    });

    test('raises InsightsGenerated event', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      // Ignore ReflectionSubmitted
      reflection.pullDomainEvents();

      reflection.addInsights([Insight(statement: 'Insight', confidence: 0.9)]);

      final events = reflection.pullDomainEvents();

      expect(events.single, isA<InsightsGenerated>());

      // Ensure the queue has been consumed.
      expect(reflection.pullDomainEvents(), isEmpty);
    });

    test('cannot add behavioral evidence before submission', () {
      expect(
        () => reflection.addBehavioralEvidence([
          BehavioralEvidence(
            type: BehavioralEvidenceType.resilience,
            source: ReflectionEvidenceSource(reflectionId: reflection.id),
            strength: Strength(0.9),
            observedAt: DateTime.now(),
          ),
        ]),
        throwsStateError,
      );
    });

    test('adds behavioral evidence after submission', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      reflection.addBehavioralEvidence([
        BehavioralEvidence(
          type: BehavioralEvidenceType.resilience,
          source: ReflectionEvidenceSource(reflectionId: reflection.id),
          strength: Strength(0.9),
          observedAt: DateTime.now(),
        ),
      ]);

      expect(reflection.behavioralEvidence.length, 1);
    });

    test('raises BehavioralEvidenceDetected event', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      // Consume ReflectionSubmitted.
      reflection.pullDomainEvents();

      reflection.addBehavioralEvidence([
        BehavioralEvidence(
          type: BehavioralEvidenceType.resilience,
          source: ReflectionEvidenceSource(reflectionId: reflection.id),
          strength: Strength(0.9),
          observedAt: DateTime.now(),
        ),
      ]);

      final events = reflection.pullDomainEvents();

      expect(events, hasLength(1));
      expect(events.single, isA<BehavioralEvidenceDetected>());
    });

    test('deduplicates narrative themes', () {
      reflection.addResponse(const JournalResponse(response: 'Reflection'));

      reflection.submit();

      final theme = NarrativeThemeId.generate();

      reflection.addNarrativeThemes([theme, theme]);

      expect(reflection.narrativeThemes.length, 1);
    });

    test('responses are immutable', () {
      expect(
        () => reflection.responses.add(const JournalResponse(response: 'test')),
        throwsUnsupportedError,
      );
    });
  });
}
