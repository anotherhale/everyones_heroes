import 'package:eh_platform/src/eventing/event_base.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

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
