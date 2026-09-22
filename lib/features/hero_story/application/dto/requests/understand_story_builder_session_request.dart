import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_understanding_kind.dart';

/// Request Story Understanding for a durable Story Builder session (SB.8).
final class UnderstandStoryBuilderSessionRequest {
  const UnderstandStoryBuilderSessionRequest({
    required this.sessionId,
    this.kind = StoryBuilderUnderstandingKind.deterministic,
    this.analyzedAt,
  });

  final StoryBuilderSessionId sessionId;

  /// [StoryBuilderUnderstandingKind.deterministic] never requires AI.
  /// [StoryBuilderUnderstandingKind.aiEnhanced] uses the understanding port.
  final StoryBuilderUnderstandingKind kind;

  /// Optional clock injection for tests.
  final DateTime? analyzedAt;
}
