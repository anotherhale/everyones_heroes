/// Controllable time source for deterministic domain/application behavior.
abstract interface class Clock {
  DateTime nowUtc();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

final class FixedClock implements Clock {
  FixedClock(DateTime value) : _value = value.toUtc();

  DateTime _value;

  @override
  DateTime nowUtc() => _value;

  void advance(Duration duration) {
    _value = _value.add(duration);
  }

  void set(DateTime value) {
    _value = value.toUtc();
  }
}
