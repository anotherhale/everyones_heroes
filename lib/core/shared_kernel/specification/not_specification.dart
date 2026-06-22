import 'package:everyonesheroes/core/shared_kernel/specification/specification.dart';

final class NotSpecification<T> implements Specification<T> {
  final Specification<T> inner;

  const NotSpecification(this.inner);

  @override
  bool isSatisfiedBy(T candidate) {
    return !inner.isSatisfiedBy(candidate);
  }
}
