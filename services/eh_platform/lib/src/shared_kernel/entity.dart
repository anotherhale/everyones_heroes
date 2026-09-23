abstract base class Entity<TId> {
  final TId id;

  const Entity(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType && other is Entity && other.id == id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}
