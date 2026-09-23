import 'package:eh_platform/src/shared_kernel/domain_exception.dart';

final class ValidationException extends DomainException {
  const ValidationException(super.message);
}
