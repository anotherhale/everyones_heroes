import 'package:eh_platform/src/shared_kernel/guard.dart';
import 'package:uuid/uuid.dart';

/// Opaque strongly-typed identifier used across platform modules.
abstract base class StronglyTypedId {
  const StronglyTypedId(this.value)
      : assert(value != '', 'StronglyTypedId value must not be empty');

  static const Uuid uuid = Uuid();

  final String value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StronglyTypedId &&
        runtimeType == other.runtimeType &&
        value == other.value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => '$runtimeType($value)';
}

/// Validates a non-empty opaque id string.
String requireId(String value, {String name = 'id'}) {
  Guard.againstNullOrEmpty(value, name);
  return value;
}
