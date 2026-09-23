import 'package:eh_platform/src/shared_kernel/ids/aggregate_id.dart';
import 'package:eh_platform/src/shared_kernel/strongly_typed_id.dart';

final class MissionId extends StronglyTypedId implements AggregateId {
  const MissionId(super.value);

  factory MissionId.generate() {
    return MissionId(StronglyTypedId.uuid.v4());
  }
}
