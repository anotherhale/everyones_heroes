import 'dart:convert';

import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/enums/journey_chapter.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/journey_repository.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/h2_json_codec.dart';
import 'package:eh_platform/src/persistence/unit_of_work.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/user_id.dart';
import 'package:postgres/postgres.dart';

/// PostgreSQL Journey repository — authoritative H.2 persistence.
final class PostgresJourneyRepository implements JourneyRepository {
  PostgresJourneyRepository({
    required UnitOfWork unitOfWork,
    H2JsonCodec codec = const H2JsonCodec(),
  }) : _uow = unitOfWork,
       _codec = codec;

  final UnitOfWork _uow;
  final H2JsonCodec _codec;

  Session get _session {
    final session = _uow.session;
    if (session == null) {
      throw StateError('PostgresJourneyRepository requires an active session.');
    }
    return session;
  }

  Future<void> ensureUser(UserId userId) async {
    await _session.execute(
      Sql.named(
        'INSERT INTO users (id) VALUES (@id) ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {'id': userId.value},
    );
  }

  Future<void> saveForUser(Journey journey, UserId userId) async {
    await ensureUser(userId);
    await _session.execute(
      Sql.named('''
        INSERT INTO journeys (
          id, user_id, vision, current_chapter, active_quest_ids,
          behavior_patterns, version, updated_at
        ) VALUES (
          @id, @userId, @vision, @chapter, @quests, @patterns, 0, NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
          vision = EXCLUDED.vision,
          current_chapter = EXCLUDED.current_chapter,
          active_quest_ids = EXCLUDED.active_quest_ids,
          behavior_patterns = EXCLUDED.behavior_patterns,
          version = journeys.version + 1,
          updated_at = NOW()
        '''),
      parameters: {
        'id': journey.id.value,
        'userId': userId.value,
        'vision': journey.vision.value,
        'chapter': journey.currentChapter.name,
        'quests': jsonEncode(_codec.encodeQuestIds(journey.activeQuestIds)),
        'patterns': jsonEncode(_codec.encodePatterns(journey.behaviorPatterns)),
      },
    );
  }

  @override
  Future<void> save(Journey journey) async {
    // Ownership must be established via [saveForUser] for inserts.
    // Updates reuse existing user_id.
    final existing = await _session.execute(
      Sql.named('SELECT user_id FROM journeys WHERE id = @id'),
      parameters: {'id': journey.id.value},
    );
    if (existing.isEmpty) {
      throw StateError(
        'Cannot save new Journey without user ownership. Use saveForUser.',
      );
    }
    final userId = UserId(existing.first[0] as String);
    await saveForUser(journey, userId);
  }

  @override
  Future<Journey?> findById(JourneyId id) async {
    final rows = await _session.execute(
      Sql.named('''
        SELECT id, vision, current_chapter, active_quest_ids, behavior_patterns
        FROM journeys WHERE id = @id
        '''),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) {
      return null;
    }
    return _map(rows.first);
  }

  Future<Journey?> findCurrentByUserId(UserId userId) async {
    final rows = await _session.execute(
      Sql.named('''
        SELECT id, vision, current_chapter, active_quest_ids, behavior_patterns
        FROM journeys
        WHERE user_id = @userId
        ORDER BY updated_at DESC
        LIMIT 1
        '''),
      parameters: {'userId': userId.value},
    );
    if (rows.isEmpty) {
      return null;
    }
    return _map(rows.first);
  }

  Future<UserId?> ownerOf(JourneyId id) async {
    final rows = await _session.execute(
      Sql.named('SELECT user_id FROM journeys WHERE id = @id'),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) {
      return null;
    }
    return UserId(rows.first[0] as String);
  }

  @override
  Future<bool> exists(JourneyId id) async {
    final rows = await _session.execute(
      Sql.named('SELECT 1 FROM journeys WHERE id = @id'),
      parameters: {'id': id.value},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> delete(JourneyId id) async {
    await _session.execute(
      Sql.named('DELETE FROM journeys WHERE id = @id'),
      parameters: {'id': id.value},
    );
  }

  Journey _map(ResultRow row) {
    return Journey(
      id: JourneyId(row[0] as String),
      vision: JourneyVision(row[1] as String),
      currentChapter: JourneyChapter.values.byName(row[2] as String),
      activeQuestIds: _codec.decodeQuestIds(row[3]),
      behaviorPatterns: _codec.decodePatterns(row[4]),
    );
  }
}
