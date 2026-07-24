import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class MissionId extends StronglyTypedId implements AggregateId {
  const MissionId(super.value);

  factory MissionId.generate() {
    return MissionId(StronglyTypedId.uuid.v4());
  }
}
