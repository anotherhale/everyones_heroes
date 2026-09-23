import 'package:eh_platform/src/shared_kernel/ids/aggregate_id.dart';
import 'package:eh_platform/src/shared_kernel/strongly_typed_id.dart';

final class QuestId extends StronglyTypedId implements AggregateId {
  const QuestId(super.value);

  factory QuestId.generate() {
    return QuestId(StronglyTypedId.uuid.v4());
  }
}
