import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class AnalyzerId extends StronglyTypedId {
  const AnalyzerId(super.value);

  factory AnalyzerId.generate() => AnalyzerId(StronglyTypedId.uuid.v4());
}
