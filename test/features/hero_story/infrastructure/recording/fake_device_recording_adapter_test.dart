import 'dart:io';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late FakeDeviceRecordingAdapter adapter;
  var tick = DateTime.utc(2026, 9, 14, 12);

  DateTime clock() => tick;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fake-record-');
    tick = DateTime.utc(2026, 9, 14, 12);
    adapter = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      clock: clock,
    );
  });

  tearDown(() async {
    await adapter.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('stop writes deterministic fake audio bytes', () async {
    await adapter.prepare();
    await adapter.start();
    tick = tick.add(const Duration(seconds: 3));
    final artifact = await adapter.stop();

    expect(artifact.contentType, 'audio/m4a');
    expect(artifact.mode, RecordingMode.audio);
    expect(artifact.duration, const Duration(seconds: 3));
    expect(artifact.byteLength, 'fake-audio-bytes'.length);

    final bytes = await File(artifact.localFilePath).readAsBytes();
    expect(String.fromCharCodes(bytes), 'fake-audio-bytes');
  });

  test('pause and resume accumulate elapsed without double-counting', () async {
    await adapter.start();
    tick = tick.add(const Duration(seconds: 2));
    await adapter.pause();
    expect(await adapter.isPaused, isTrue);
    expect(await adapter.elapsed, const Duration(seconds: 2));

    tick = tick.add(const Duration(seconds: 10)); // paused time ignored
    await adapter.resume();
    tick = tick.add(const Duration(seconds: 4));
    expect(await adapter.elapsed, const Duration(seconds: 6));

    final artifact = await adapter.stop();
    expect(artifact.duration, const Duration(seconds: 6));
  });

  test('cancel deletes temp file', () async {
    await adapter.start();
    final path = (await Directory(tempDir.path).list().toList()).single.path;
    expect(await File(path).exists(), isTrue);

    await adapter.cancel();
    expect(await File(path).exists(), isFalse);
    expect(await adapter.isRecording, isFalse);
  });

  test('permission denial blocks start and can simulate failures', () async {
    await adapter.dispose();
    adapter = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      initialPermission: DevicePermissionStatus.denied,
      autoGrantOnRequest: false,
      clock: clock,
    );

    await adapter.prepare();
    expect(
      await adapter.checkMicrophonePermission(),
      DevicePermissionStatus.denied,
    );

    await expectLater(
      adapter.start(),
      throwsA(
        isA<DeviceRecordingException>().having(
          (e) => e.kind,
          'kind',
          DeviceRecordingFailureKind.permissionDenied,
        ),
      ),
    );

    final failures = <DeviceRecordingFailureKind>[];
    final sub = adapter.failures.listen(failures.add);
    adapter.simulateFailure(DeviceRecordingFailureKind.storageInsufficient);
    await expectLater(adapter.start(), throwsA(isA<DeviceRecordingException>()));
    await Future<void>.delayed(Duration.zero);
    expect(failures, contains(DeviceRecordingFailureKind.storageInsufficient));
    await sub.cancel();
  });

  test('autoGrantOnRequest upgrades notDetermined', () async {
    final gated = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      initialPermission: DevicePermissionStatus.notDetermined,
      autoGrantOnRequest: true,
    );
    addTearDown(gated.dispose);

    expect(
      await gated.requestMicrophonePermission(),
      DevicePermissionStatus.granted,
    );
  });
}
