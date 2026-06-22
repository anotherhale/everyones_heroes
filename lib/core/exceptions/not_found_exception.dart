import 'package:everyonesheroes/core/shared_kernel/domain_exception.dart';

final class NotFoundException extends DomainException {
  const NotFoundException(super.message);
}
