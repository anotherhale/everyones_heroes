import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Raised when a Story Builder session reaches completed status.
///
/// Justification: completion is a meaningful fact for later slices that will
/// materialize Story representations / Understanding from session material.
/// No reactors registered in SB.1. Story is NOT auto-created (SB.0 default).
final class StoryBuilderSessionCompleted extends EventBase {
  StoryBuilderSessionCompleted({
    required this.sessionId,
    required this.heroId,
    this.storyId,
    super.correlationId,
    super.causationId,
  }) : super(
         aggregateId: sessionId,
         aggregateType: AggregateType.storyBuilderSession,
       );

  final StoryBuilderSessionId sessionId;
  final HeroId heroId;

  /// Optional link if a Story was associated before completion (SB.5+).
  final StoryId? storyId;
}
