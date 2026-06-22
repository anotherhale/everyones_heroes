import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class ReflectionId extends StronglyTypedId {
  const ReflectionId(super.value);

  factory ReflectionId.generate() {
    return ReflectionId(StronglyTypedId.uuid.v4());
  }
}
