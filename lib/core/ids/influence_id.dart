import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class InfluenceId extends StronglyTypedId {
  const InfluenceId(super.value);

  factory InfluenceId.generate() {
    return InfluenceId(StronglyTypedId.uuid.v4());
  }
}
