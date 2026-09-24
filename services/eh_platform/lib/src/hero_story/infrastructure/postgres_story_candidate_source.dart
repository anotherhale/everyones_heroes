import 'dart:convert';

import 'package:eh_platform/src/hero_story/application/ports/discoverable_story_candidate_projection.dart';
import 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';
import 'package:eh_platform/src/persistence/database.dart';

/// Live PostgreSQL [StoryCandidateSource] + projection writer (J.2 Slice 4).
///
/// Queries only eligibility-gated projection rows. Does not access Reflection,
/// Journey, Flutter state, or the Slice 3 seed catalog.
///
/// **Transitional:** rows are populated by
/// [ProjectDiscoverableStoryCandidateUseCase] until Phase 7 event reactors
/// refresh the projection from platform Story/Hero authority.
final class PostgresStoryCandidateSource
    implements StoryCandidateSource, DiscoverableStoryCandidateProjection {
  PostgresStoryCandidateSource(this._database);

  final PlatformDatabase _database;

  @override
  Future<List<StoryCandidateRecord>> listCandidates() async {
    final rows = await _database.connection.execute(
      '''
SELECT story_id, hero_id, title, theme_ids, updated_at
FROM discoverable_story_candidates
ORDER BY updated_at DESC, story_id ASC
''',
    );

    return List.unmodifiable(
      rows.map((row) {
        final themeIds = _decodeThemeIds(row[3]);
        return StoryCandidateRecord(
          storyId: row[0]! as String,
          heroId: row[1]! as String,
          title: row[2]! as String,
          themeIds: themeIds,
          updatedAt: (row[4]! as DateTime).toUtc(),
        );
      }),
    );
  }

  @override
  Future<void> upsert(
    StoryCandidateRecord record, {
    String? storyVisibility,
    String? heroVisibility,
  }) async {
    await _database.connection.execute(
      r'''
INSERT INTO discoverable_story_candidates (
  story_id, hero_id, title, theme_ids, updated_at,
  story_visibility, hero_visibility, projected_at
) VALUES (
  $1, $2, $3, $4::jsonb, $5, $6, $7, NOW()
)
ON CONFLICT (story_id) DO UPDATE SET
  hero_id = EXCLUDED.hero_id,
  title = EXCLUDED.title,
  theme_ids = EXCLUDED.theme_ids,
  updated_at = EXCLUDED.updated_at,
  story_visibility = EXCLUDED.story_visibility,
  hero_visibility = EXCLUDED.hero_visibility,
  projected_at = NOW()
''',
      parameters: [
        record.storyId,
        record.heroId,
        record.title,
        jsonEncode(record.themeIds),
        record.updatedAt.toUtc(),
        storyVisibility,
        heroVisibility,
      ],
    );
  }

  @override
  Future<void> remove(String storyId) async {
    await _database.connection.execute(
      r'DELETE FROM discoverable_story_candidates WHERE story_id = $1',
      parameters: [storyId],
    );
  }

  @override
  Future<bool> exists(String storyId) async {
    final rows = await _database.connection.execute(
      r'SELECT 1 FROM discoverable_story_candidates WHERE story_id = $1',
      parameters: [storyId],
    );
    return rows.isNotEmpty;
  }

  static List<String> _decodeThemeIds(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    }
    throw StateError(
      'discoverable_story_candidates.theme_ids must be a JSON array',
    );
  }
}
