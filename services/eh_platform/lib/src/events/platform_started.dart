import 'package:eh_platform/src/events/domain_event.dart';

/// Raised when the EH Platform process completes successful bootstrap.
final class PlatformStarted extends DomainEvent {
  PlatformStarted({
    required super.eventId,
    required super.occurredAt,
    required this.environment,
    required this.httpPort,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateId: 'eh-platform',
          aggregateType: 'Platform',
        );

  final String environment;
  final int httpPort;

  @override
  String get eventName => 'PlatformStarted';
}
