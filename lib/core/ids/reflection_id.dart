import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class ReflectionId extends StronglyTypedId implements AggregateId {
  const ReflectionId(super.value);

  factory ReflectionId.generate() {
    return ReflectionId(StronglyTypedId.uuid.v4());
  }
}
