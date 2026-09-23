import 'package:eh_platform/src/shared_kernel/clock.dart';

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() {
    return DateTime.now();
  }
}
