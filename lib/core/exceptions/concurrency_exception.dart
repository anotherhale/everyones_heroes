import 'package:everyonesheroes/core/shared_kernel/domain_exception.dart';

final class ConcurrencyException extends DomainException {
  const ConcurrencyException(super.message);
}
