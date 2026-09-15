import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/unavailable_device_recording_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runtime-contract proof for [UnavailableDeviceRecordingAdapter].
///
/// Retained for genuinely unsupported hosts / explicit stubs. Normal Flutter
/// Web composition now binds [RecordPackageWebDeviceRecordingAdapter] instead.
void main() {
  late UnavailableDeviceRecordingAdapter adapter;

  setUp(() {
    adapter = UnavailableDeviceRecordingAdapter();
  });

  tearDown(() async {
    await adapter.dispose();
  });

  test('checkMicrophonePermission hardcodes unavailable', () async {
    expect(
      await adapter.checkMicrophonePermission(),
      DevicePermissionStatus.unavailable,
    );
  });

  test(
    'requestMicrophonePermission hardcodes unavailable (no getUserMedia)',
    () async {
      expect(
        await adapter.requestMicrophonePermission(),
        DevicePermissionStatus.unavailable,
      );
    },
  );

  test(
    'start throws microphoneUnavailable without touching media devices',
    () async {
      await expectLater(
        adapter.start(),
        throwsA(
          isA<DeviceRecordingException>().having(
            (e) => e.kind,
            'kind',
            DeviceRecordingFailureKind.microphoneUnavailable,
          ),
        ),
      );
    },
  );
}
