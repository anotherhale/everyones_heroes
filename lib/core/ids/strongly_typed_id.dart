import 'package:uuid/uuid.dart';

abstract base class StronglyTypedId {
  static const Uuid uuid = Uuid();

  final String value;

  const StronglyTypedId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is StronglyTypedId &&
          value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}
