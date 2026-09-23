import 'dart:convert';

import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/h2_json_codec.dart';
import 'package:eh_platform/src/persistence/unit_of_work.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/mission_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/quest_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/user_id.dart';
import 'package:postgres/postgres.dart';

/// PostgreSQL Reflection repository — embeds Behavioral Evidence.
final class PostgresReflectionRepository implements ReflectionRepository {
  PostgresReflectionRepository({
    required UnitOfWork unitOfWork,
    H2JsonCodec codec = const H2JsonCodec(),
  }) : _uow = unitOfWork,
       _codec = codec;

  final UnitOfWork _uow;
  final H2JsonCodec _codec;

  Session get _session {
    final session = _uow.session;
    if (session == null) {
      throw StateError(
        'PostgresReflectionRepository requires an active session.',
      );
    }
    return session;
  }

  Future<void> saveForUser(Reflection reflection, UserId userId) async {
    await _session.execute(
      Sql.named('''
        INSERT INTO reflections (
          id, user_id, journey_id, quest_id, mission_id,
          created_at, submitted_at, responses, insights,
          behavioral_evidence, narrative_themes, version, updated_at
        ) VALUES (
          @id, @userId, @journeyId, @questId, @missionId,
          @createdAt, @submittedAt, @responses, @insights,
          @evidence, @themes, 0, NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
          submitted_at = EXCLUDED.submitted_at,
          responses = EXCLUDED.responses,
          insights = EXCLUDED.insights,
          behavioral_evidence = EXCLUDED.behavioral_evidence,
          narrative_themes = EXCLUDED.narrative_themes,
          version = reflections.version + 1,
          updated_at = NOW()
        '''),
      parameters: {
        'id': reflection.id.value,
        'userId': userId.value,
        'journeyId': reflection.journeyId.value,
        'questId': reflection.questId?.value,
        'missionId': reflection.missionId?.value,
        'createdAt': reflection.createdAt.toUtc(),
        'submittedAt': reflection.submittedAt?.toUtc(),
        'responses': jsonEncode(_codec.encodeResponses(reflection.responses)),
        'insights': jsonEncode(_codec.encodeInsights(reflection.insights)),
        'evidence': jsonEncode(
          _codec.encodeEvidenceList(reflection.behavioralEvidence),
        ),
        'themes': jsonEncode(_codec.encodeThemeIds(reflection.narrativeThemes)),
      },
    );
  }

  @override
  Future<void> save(Reflection reflection) async {
    final existing = await _session.execute(
      Sql.named('SELECT user_id FROM reflections WHERE id = @id'),
      parameters: {'id': reflection.id.value},
    );
    if (existing.isEmpty) {
      throw StateError(
        'Cannot save new Reflection without user ownership. Use saveForUser.',
      );
    }
    await saveForUser(reflection, UserId(existing.first[0] as String));
  }

  @override
  Future<Reflection?> findById(ReflectionId id) async {
    final rows = await _session.execute(
      Sql.named('''
        SELECT id, journey_id, quest_id, mission_id, created_at, submitted_at,
               responses, insights, behavioral_evidence, narrative_themes
        FROM reflections WHERE id = @id
        '''),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) {
      return null;
    }
    return _map(rows.first);
  }

  @override
  Future<List<Reflection>> findByJourneyId(JourneyId journeyId) async {
    final rows = await _session.execute(
      Sql.named('''
        SELECT id, journey_id, quest_id, mission_id, created_at, submitted_at,
               responses, insights, behavioral_evidence, narrative_themes
        FROM reflections
        WHERE journey_id = @journeyId
        ORDER BY created_at ASC
        '''),
      parameters: {'journeyId': journeyId.value},
    );
    return rows.map(_map).toList(growable: false);
  }

  Future<UserId?> ownerOf(ReflectionId id) async {
    final rows = await _session.execute(
      Sql.named('SELECT user_id FROM reflections WHERE id = @id'),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) {
      return null;
    }
    return UserId(rows.first[0] as String);
  }

  @override
  Future<bool> exists(ReflectionId id) async {
    final rows = await _session.execute(
      Sql.named('SELECT 1 FROM reflections WHERE id = @id'),
      parameters: {'id': id.value},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> delete(ReflectionId id) async {
    await _session.execute(
      Sql.named('DELETE FROM reflections WHERE id = @id'),
      parameters: {'id': id.value},
    );
  }

  Reflection _map(ResultRow row) {
    return Reflection(
      id: ReflectionId(row[0] as String),
      journeyId: JourneyId(row[1] as String),
      questId: row[2] == null ? null : QuestId(row[2] as String),
      missionId: row[3] == null ? null : MissionId(row[3] as String),
      createdAt: (row[4] as DateTime).toUtc(),
      submittedAt: (row[5] as DateTime?)?.toUtc(),
      responses: _codec.decodeResponses(row[6]),
      insights: _codec.decodeInsights(row[7]),
      behavioralEvidence: _codec.decodeEvidenceList(row[8]),
      narrativeThemes: _codec.decodeThemeIds(row[9]),
    );
  }
}
