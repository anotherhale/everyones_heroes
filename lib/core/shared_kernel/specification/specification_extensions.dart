import 'package:everyonesheroes/core/shared_kernel/specification/and_specification.dart';
import 'package:everyonesheroes/core/shared_kernel/specification/not_specification.dart';
import 'package:everyonesheroes/core/shared_kernel/specification/or_specification.dart';
import 'package:everyonesheroes/core/shared_kernel/specification/specification.dart';

extension SpecificationExtensions<T> on Specification<T> {
  Specification<T> and(Specification<T> other) {
    return AndSpecification<T>(this, other);
  }

  Specification<T> or(Specification<T> other) {
    return OrSpecification<T>(this, other);
  }

  Specification<T> not() {
    return NotSpecification<T>(this);
  }
}
