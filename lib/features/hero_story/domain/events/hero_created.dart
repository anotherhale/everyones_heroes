import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';

final class HeroCreated extends EventBase {
  HeroCreated({
    required HeroId heroId,
    super.correlationId,
    super.causationId,
  }) : heroId = heroId,
       super(aggregateId: heroId, aggregateType: AggregateType.hero);

  final HeroId heroId;
}
