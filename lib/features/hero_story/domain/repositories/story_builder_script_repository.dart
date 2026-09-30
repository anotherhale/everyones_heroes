import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';

/// Persistence boundary for durable Story Builder scripts (SB.8).
///
/// Scripts survive app reload and Create Story failures. Do not store a
/// duplicate of the full session — only script fields + session provenance.
abstract interface class StoryBuilderScriptRepository {
  Future<void> save(StoryBuilderScript script);

  Future<StoryBuilderScript?> findById(StoryBuilderScriptId id);

  Future<bool> exists(StoryBuilderScriptId id);

  Future<void> delete(StoryBuilderScriptId id);

  /// Scripts derived from a given session (newest first).
  Future<List<StoryBuilderScript>> findBySessionId(
    StoryBuilderSessionId sessionId,
  );

  /// Latest script for a session, if any.
  Future<StoryBuilderScript?> findLatestBySessionId(
    StoryBuilderSessionId sessionId,
  );

  /// Latest approved script for a session, if any.
  Future<StoryBuilderScript?> findLatestApprovedBySessionId(
    StoryBuilderSessionId sessionId,
  );
}
