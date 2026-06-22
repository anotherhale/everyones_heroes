import 'package:everyonesheroes/core/shared_kernel/domain_exception.dart';

final class UnauthorizedOperationException extends DomainException {
  const UnauthorizedOperationException(super.message);
}
