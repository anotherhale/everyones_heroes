import 'package:uuid/uuid.dart';

/// Base class for all domain-specific identifiers.
///
/// Strongly typed IDs prevent accidentally passing one entity's identifier
/// where another is expected while still using UUID strings internally.
///
/// Example:
///
/// ```dart
/// final JourneyId journeyId = JourneyId.generate();
/// final MissionId missionId = MissionId.generate();
///
/// // Compile-time error:
/// // completeMission(journeyId);
/// ```
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
