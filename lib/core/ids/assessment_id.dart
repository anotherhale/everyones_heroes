import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class AssessmentId extends StronglyTypedId {
  AssessmentId(super.value);

  factory AssessmentId.generate() => AssessmentId(StronglyTypedId.uuid.v4());
}
