import 'package:eh_platform/src/shared_kernel/strongly_typed_id.dart';

/// Platform identity for a human user (PF-ADR-008).
///
/// Distinct from Hero — Hero is a Hero & Story aggregate that may link to a
/// UserId; they must never be merged.
final class UserId extends StronglyTypedId {
  const UserId(super.value);

  factory UserId.generate() => UserId(StronglyTypedId.uuid.v4());
}
