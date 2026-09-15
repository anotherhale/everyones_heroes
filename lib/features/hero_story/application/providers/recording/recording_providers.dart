import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/record_package_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter.dart';

/// Whether to use the real device recorder (false → fake).
///
/// Native durable [AppCompositionRoot] sets this true and overrides
/// [deviceRecordingPortProvider] with [RecordPackageDeviceRecordingAdapter].
/// Browser / in-memory composition sets this true and overrides with
/// [RecordPackageWebDeviceRecordingAdapter] (microphone on user gesture).
final useRealDeviceRecordingProvider = Provider<bool>((ref) => false);

final deviceRecordingPortProvider = Provider<DeviceRecordingPort>((ref) {
  final useReal = ref.watch(useRealDeviceRecordingProvider);
  if (!useReal) {
    return FakeDeviceRecordingAdapter();
  }

  throw StateError(
    'Real DeviceRecordingPort must be provided by AppCompositionRoot overrides.',
  );
});

/// Builds a production [RecordPackageDeviceRecordingAdapter] (native).
DeviceRecordingPort createRecordPackageDeviceRecordingAdapter(
  Directory tempDirectory,
) {
  return RecordPackageDeviceRecordingAdapter(tempDirectory: tempDirectory);
}

/// Builds a production web [RecordPackageWebDeviceRecordingAdapter].
DeviceRecordingPort createRecordPackageWebDeviceRecordingPort() {
  return createRecordPackageWebDeviceRecordingAdapter();
}

/// Default session service for tests (no durable manifest directory).
///
/// Production overrides this with a session that has a manifest directory.
final recordingSessionServiceProvider = Provider<RecordingSessionService>((
  ref,
) {
  return RecordingSessionService(
    recordingPort: ref.watch(deviceRecordingPortProvider),
    completeCapture: ref.watch(completeStoryCaptureUseCaseProvider),
  );
});
