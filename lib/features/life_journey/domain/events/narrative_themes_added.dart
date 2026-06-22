import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

final class NarrativeThemesAdded extends EventBase {
  NarrativeThemesAdded({
    required super.aggregateId,
    required this.reflectionId,
    required this.narrativeThemeIds,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateType: 'Reflection',
        );

  final ReflectionId reflectionId;

  final List<NarrativeThemeId> narrativeThemeIds;
}