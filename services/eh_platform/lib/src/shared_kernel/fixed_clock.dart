import 'package:eh_platform/src/shared_kernel/clock.dart';

final class FixedClock implements Clock {
  final DateTime _fixedTime;

  const FixedClock(this._fixedTime);

  @override
  DateTime now() {
    return _fixedTime;
  }
}
