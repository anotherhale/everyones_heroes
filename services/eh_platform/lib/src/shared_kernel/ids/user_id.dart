import 'package:eh_platform/src/shared_kernel/ids/strongly_typed_id.dart';

final class UserId extends StronglyTypedId {
  const UserId(super.value);

  factory UserId.generate() {
    return UserId(StronglyTypedId.uuid.v4());
  }
}
