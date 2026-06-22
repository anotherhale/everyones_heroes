abstract interface class Specification<T> {
  bool isSatisfiedBy(T candidate);
}
