import 'dart:collection';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/insights_generated.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/narrative_themes_added.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';

final class Reflection extends AggregateRoot<ReflectionId> {
  Reflection({
    required ReflectionId id,
    required this._journeyId,
    required this._createdAt,
    this._questId,
    this._missionId,
    List<ReflectionResponse>? responses,
    List<Insight>? insights,
    List<BehavioralEvidence>? behavioralEvidence,
    List<NarrativeThemeId>? narrativeThemes,
    this._submittedAt,
  }) : _responses = responses ?? [],
       _insights = insights ?? [],
       _behavioralEvidence = behavioralEvidence ?? [],
       _narrativeThemes = narrativeThemes ?? [],
       super(id);

  final JourneyId _journeyId;

  final QuestId? _questId;

  final MissionId? _missionId;

  final DateTime _createdAt;

  DateTime? _submittedAt;

  final List<ReflectionResponse> _responses;

  final List<Insight> _insights;

  final List<BehavioralEvidence> _behavioralEvidence;

  final List<NarrativeThemeId> _narrativeThemes;

  factory Reflection.create({
    required ReflectionId id,
    required JourneyId journeyId,
    QuestId? questId,
    MissionId? missionId,
  }) {
    return Reflection(
      id: id,
      journeyId: journeyId,
      questId: questId,
      missionId: missionId,
      createdAt: DateTime.now(),
    );
  }

  JourneyId get journeyId => _journeyId;

  QuestId? get questId => _questId;

  MissionId? get missionId => _missionId;

  DateTime get createdAt => _createdAt;

  DateTime? get submittedAt => _submittedAt;

  bool get isSubmitted => _submittedAt != null;

  UnmodifiableListView<ReflectionResponse> get responses =>
      UnmodifiableListView(_responses);

  UnmodifiableListView<Insight> get insights => UnmodifiableListView(_insights);

  UnmodifiableListView<BehavioralEvidence> get behavioralEvidence =>
      UnmodifiableListView(_behavioralEvidence);

  UnmodifiableListView<NarrativeThemeId> get narrativeThemes =>
      UnmodifiableListView(_narrativeThemes);

  void addResponse(ReflectionResponse response) {
    if (isSubmitted) {
      throw StateError('Cannot modify a submitted reflection.');
    }

    _responses.add(response);
  }

  void addResponses(Iterable<ReflectionResponse> responses) {
    for (final response in responses) {
      addResponse(response);
    }
  }

  void submit() {
    if (isSubmitted) {
      throw StateError('Reflection already submitted.');
    }

    if (_responses.isEmpty) {
      throw StateError('Reflection must contain at least one response.');
    }

    _submittedAt = DateTime.now();

    raise(
      ReflectionSubmitted(
        aggregateId: id.value,
        reflectionId: id,
        journeyId: journeyId,
        questId: questId,
        missionId: missionId,
      ),
    );
  }

  void addInsights(Iterable<Insight> insights) {
    _ensureSubmitted();

    final items = insights.toList(growable: false);

    if (items.isEmpty) {
      return;
    }

    _insights.addAll(items);

    raise(
      InsightsGenerated(
        aggregateId: id.value,
        reflectionId: id,
        insights: items,
      ),
    );
  }

  void addBehavioralEvidence(Iterable<BehavioralEvidence> evidence) {
    _ensureSubmitted();

    final items = evidence.toList(growable: false);

    if (items.isEmpty) {
      return;
    }

    _behavioralEvidence.addAll(items);

    raise(
      BehavioralEvidenceDetected(
        aggregateId: id.value,
        reflectionId: id,
        evidence: items,
      ),
    );
  }

void addNarrativeThemes(Iterable<NarrativeThemeId> themes) {
  _ensureSubmitted();

  final addedThemes = <NarrativeThemeId>[];

  for (final themeId in themes) {
    if (!_narrativeThemes.contains(themeId)) {
      _narrativeThemes.add(themeId);
      addedThemes.add(themeId);
    }
  }

  if (addedThemes.isEmpty) {
    return;
  }

  raise(
    NarrativeThemesAdded(
      aggregateId: id.value,
      reflectionId: id,
      narrativeThemeIds: addedThemes,
    ),
  );
}

  void _ensureSubmitted() {
    if (!isSubmitted) {
      throw StateError('Reflection must be submitted first.');
    }
  }
}
