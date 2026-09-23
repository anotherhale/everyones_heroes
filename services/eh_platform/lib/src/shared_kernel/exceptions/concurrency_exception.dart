import 'package:eh_platform/src/shared_kernel/domain_exception.dart';

final class ConcurrencyException extends DomainException {
  const ConcurrencyException(super.message);
}
