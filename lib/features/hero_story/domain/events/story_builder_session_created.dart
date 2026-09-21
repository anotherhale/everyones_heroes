import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';

/// Raised when a Story Builder session is created.
///
/// Justification: matches Hero/Story create→publish EventBus convention so
/// application use cases can notify interested reactors later (e.g. analytics,
/// resume surfaces) without UI constructing events. No reactors registered in SB.1.
final class StoryBuilderSessionCreated extends EventBase {
  StoryBuilderSessionCreated({
    required this.sessionId,
    required this.heroId,
    super.correlationId,
    super.causationId,
  }) : super(
         aggregateId: sessionId,
         aggregateType: AggregateType.storyBuilderSession,
       );

  final StoryBuilderSessionId sessionId;
  final HeroId heroId;
}
