import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';

final class InfluenceRemoved extends EventBase {
  InfluenceRemoved({
    required super.aggregateId,
    required this.discoveryProfileId,
    required this.influenceId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'DiscoveryProfile');

  final DiscoveryProfileId discoveryProfileId;

  final InfluenceId influenceId;
}
