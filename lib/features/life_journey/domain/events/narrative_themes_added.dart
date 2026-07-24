import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';

final class NarrativeThemesAdded extends EventBase {
  NarrativeThemesAdded({
    required super.aggregateId,
    required this.reflectionId,
    required this.narrativeThemeIds,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.reflection);

  final ReflectionId reflectionId;

  final List<NarrativeThemeId> narrativeThemeIds;
}
