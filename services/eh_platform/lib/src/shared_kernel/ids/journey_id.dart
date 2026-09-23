import 'package:eh_platform/src/shared_kernel/ids/aggregate_id.dart';
import 'package:eh_platform/src/shared_kernel/strongly_typed_id.dart';

final class JourneyId extends StronglyTypedId implements AggregateId {
  const JourneyId(super.value);

  factory JourneyId.generate() {
    return JourneyId(StronglyTypedId.uuid.v4());
  }
}
