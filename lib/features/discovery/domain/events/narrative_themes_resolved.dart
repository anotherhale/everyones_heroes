import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

final class NarrativeThemesResolved extends EventBase {
  NarrativeThemesResolved({
    required super.aggregateId,
    required this.discoveryProfileId,
    required this.themeIds,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'DiscoveryProfile');

  final DiscoveryProfileId discoveryProfileId;

  final List<NarrativeThemeId> themeIds;
}
