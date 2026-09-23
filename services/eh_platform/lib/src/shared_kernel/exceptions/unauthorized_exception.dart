import 'package:eh_platform/src/shared_kernel/domain_exception.dart';

final class UnauthorizedOperationException extends DomainException {
  const UnauthorizedOperationException(super.message);
}
