import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/insights_generated.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';

import 'package:flutter_test/flutter_test.dart';

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
        const JournalResponse(text: 'Today I learned something.'),
      );

      expect(reflection.responses.length, 1);
    });

    test('adds multiple responses', () {
      reflection.addResponses([
        const JournalResponse(text: 'First'),
        const JournalResponse(text: 'Second'),
      ]);

      expect(reflection.responses.length, 2);
    });

    test('cannot submit empty reflection', () {
      expect(reflection.submit, throwsStateError);
    });

    test('submits reflection', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      expect(reflection.isSubmitted, isTrue);

      expect(reflection.submittedAt, isNotNull);
    });

    test('cannot submit twice', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      expect(reflection.submit, throwsStateError);
    });

    test('raises ReflectionSubmitted event', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      expect(reflection.domainEvents.length, 1);

      expect(reflection.domainEvents.first, isA<ReflectionSubmitted>());
    });

    test('cannot add response after submission', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      expect(
        () => reflection.addResponse(const JournalResponse(text: 'Another')),
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
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      reflection.addInsights([Insight(statement: 'Insight', confidence: 0.9)]);

      expect(reflection.insights.length, 1);
    });

    test('raises InsightsGenerated event', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      reflection.clearDomainEvents();

      reflection.addInsights([Insight(statement: 'Insight', confidence: 0.9)]);

      expect(reflection.domainEvents.first, isA<InsightsGenerated>());
    });

    test('cannot add behavioral evidence before submission', () {
      expect(
        () => reflection.addBehavioralEvidence([
          BehavioralEvidence(
            evidenceType: BehavioralEvidenceType.resilience,
            source: ReflectionEvidenceSource(reflectionId: reflection.id),
            strength: 0.9,
          ),
        ]),
        throwsStateError,
      );
    });

    test('adds behavioral evidence after submission', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      reflection.addBehavioralEvidence([
        BehavioralEvidence(
          evidenceType: BehavioralEvidenceType.resilience,
          source: ReflectionEvidenceSource(reflectionId: reflection.id),
          strength: 0.9,
        ),
      ]);

      expect(reflection.behavioralEvidence.length, 1);
    });

    test('raises BehavioralEvidenceDetected event', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      reflection.clearDomainEvents();

      reflection.addBehavioralEvidence([
        BehavioralEvidence(
          evidenceType: BehavioralEvidenceType.resilience,
          source: ReflectionEvidenceSource(reflectionId: reflection.id),
          strength: 0.9,
        ),
      ]);

      expect(reflection.domainEvents.first, isA<BehavioralEvidenceDetected>());
    });

    test('deduplicates narrative themes', () {
      reflection.addResponse(const JournalResponse(text: 'Reflection'));

      reflection.submit();

      final theme = NarrativeThemeId.generate();

      reflection.addNarrativeThemes([theme, theme]);

      expect(reflection.narrativeThemes.length, 1);
    });

    test('responses are immutable', () {
      expect(
        () => reflection.responses.add(const JournalResponse(text: 'test')),
        throwsUnsupportedError,
      );
    });
  });
}
