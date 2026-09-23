import 'package:eh_platform/src/shared_kernel/domain_exception.dart';

final class NotFoundException extends DomainException {
  const NotFoundException(super.message);
}
