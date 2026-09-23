import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';

final class NarrativeThemesAdded extends LifeJourneyEvent {
  NarrativeThemesAdded({
    required this.reflectionId,
    required List<NarrativeThemeId> narrativeThemeIds,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  })  : narrativeThemeIds = List.unmodifiable(narrativeThemeIds),
        super(
          aggregateId: reflectionId.value,
          aggregateType: 'reflection',
          eventName: 'NarrativeThemesAdded',
        );

  final ReflectionId reflectionId;
  final List<NarrativeThemeId> narrativeThemeIds;
}
