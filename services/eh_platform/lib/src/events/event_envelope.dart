import 'package:eh_platform/src/events/domain_event.dart';

/// Envelope wrapping a domain event for store append / audit.
final class EventEnvelope {
  const EventEnvelope({
    required this.event,
    this.correlationId,
    this.causationId,
  });

  final DomainEvent event;
  final String? correlationId;
  final String? causationId;
}
