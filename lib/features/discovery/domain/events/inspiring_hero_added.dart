import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';

final class InspiringHeroAdded extends EventBase {
  InspiringHeroAdded({
    required super.aggregateId,
    required this.discoveryProfileId,
    required this.heroId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.discoveryProfile);

  final DiscoveryProfileId discoveryProfileId;

  final HeroId heroId;
}
