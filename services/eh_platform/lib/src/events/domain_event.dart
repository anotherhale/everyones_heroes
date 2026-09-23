/// Past-tense domain fact owned by the platform (PF-ADR-006).
///
/// Domain events never cross the Flutter boundary as raw events.
abstract base class DomainEvent {
  DomainEvent({
    required this.eventId,
    required this.occurredAt,
    required this.aggregateId,
    required this.aggregateType,
    this.correlationId,
    this.causationId,
    this.schemaVersion = 1,
  });

  final String eventId;
  final DateTime occurredAt;
  final String aggregateId;
  final String aggregateType;
  final String? correlationId;
  final String? causationId;
  final int schemaVersion;

  /// Stable event type name for dispatch and logging.
  String get eventName;
}
