import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class QuestId extends StronglyTypedId implements AggregateId {
  const QuestId(super.value);

  factory QuestId.generate() {
    return QuestId(StronglyTypedId.uuid.v4());
  }
}
