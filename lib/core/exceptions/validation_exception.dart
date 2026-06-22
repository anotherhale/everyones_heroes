import 'package:everyonesheroes/core/shared_kernel/domain_exception.dart';

final class ValidationException extends DomainException {
  const ValidationException(super.message);
}
