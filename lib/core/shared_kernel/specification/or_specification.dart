import 'package:everyonesheroes/core/shared_kernel/specification/specification.dart';

final class OrSpecification<T> implements Specification<T> {
  final Specification<T> left;
  final Specification<T> right;

  const OrSpecification(this.left, this.right);

  @override
  bool isSatisfiedBy(T candidate) {
    return left.isSatisfiedBy(candidate) || right.isSatisfiedBy(candidate);
  }
}
