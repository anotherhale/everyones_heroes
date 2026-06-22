import 'package:everyonesheroes/core/shared_kernel/domain_exception.dart';

final class InvariantViolationException extends DomainException {
  const InvariantViolationException(super.message);
}
