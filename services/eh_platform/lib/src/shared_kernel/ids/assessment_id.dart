import 'package:eh_platform/src/shared_kernel/strongly_typed_id.dart';

final class AssessmentId extends StronglyTypedId {
  AssessmentId(super.value);

  factory AssessmentId.generate() => AssessmentId(StronglyTypedId.uuid.v4());
}
