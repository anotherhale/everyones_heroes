abstract base class ValueObject {
  const ValueObject();

  List<Object?> get equalityProps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is ValueObject &&
          _listEquals(equalityProps, other.equalityProps);

  @override
  int get hashCode => Object.hashAll([runtimeType, ...equalityProps]);

  bool _listEquals(List<Object?> left, List<Object?> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }

    return true;
  }
}
