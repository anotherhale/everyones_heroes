import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factory returns RecordPackageWebDeviceRecordingAdapter', () {
    final port = createRecordPackageWebDeviceRecordingAdapter();
    expect(port, isA<RecordPackageWebDeviceRecordingAdapter>());
  });

  test('video prepare is rejected with cameraUnavailable', () async {
    final adapter = RecordPackageWebDeviceRecordingAdapter(
      readObjectUrlBytes: (_) async => Uint8List(0),
      revokeObjectUrl: (_) {},
    );
    addTearDown(adapter.dispose);

    await expectLater(
      adapter.prepare(mode: RecordingMode.video),
      throwsA(
        isA<DeviceRecordingException>().having(
          (e) => e.kind,
          'kind',
          DeviceRecordingFailureKind.cameraUnavailable,
        ),
      ),
    );
  });

  test('cancel/dispose are safe before any recording', () async {
    var revoked = false;
    final adapter = RecordPackageWebDeviceRecordingAdapter(
      readObjectUrlBytes: (url) async {
        expect(url, startsWith('blob:'));
        return Uint8List.fromList([1, 2, 3, 4]);
      },
      revokeObjectUrl: (_) {
        revoked = true;
      },
    );
    addTearDown(adapter.dispose);

    await adapter.cancel();
    expect(await adapter.isRecording, isFalse);
    expect(await adapter.isPaused, isFalse);
    expect(revoked, isFalse);
  });
}
