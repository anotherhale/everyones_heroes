import 'dart:io';

import 'package:everyonesheroes/bootstrap/application_bootstrap.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/persistence/hero_story_persistence_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Application composition root (HS.9 durable capture + device recording).
///
/// Temporary development identity: [ensureActiveLocalHeroProvider] bootstraps a
/// local Hero until the Identity bounded context exists (HS-ADR-065).
final class AppCompositionRoot {
  /// [storageRoot] / [recordingTemp] override path_provider for tests.
  ///
  /// When [useRealDeviceRecording] is false, a [FakeDeviceRecordingAdapter] is
  /// used (tests / environments without mic plugins).
  static Future<ProviderContainer> initialize({
    Directory? storageRoot,
    Directory? recordingTemp,
    bool useRealDeviceRecording = true,
  }) async {
    final root = storageRoot ??
        Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'hero_story'),
        );
    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    final temp = recordingTemp ??
        Directory(
          p.join(
            (await getTemporaryDirectory()).path,
            'hero_story_recording',
          ),
        );
    if (!await temp.exists()) {
      await temp.create(recursive: true);
    }

    final manifests = Directory(p.join(root.path, 'recording_sessions'));
    if (!await manifests.exists()) {
      await manifests.create(recursive: true);
    }

    final durable = HeroStoryDurablePersistence(root);
    final DeviceRecordingPort recordingPort = useRealDeviceRecording
        ? createRecordPackageDeviceRecordingAdapter(temp)
        : FakeDeviceRecordingAdapter(outputDirectory: temp);

    // Late-bound session so we can share one EventBus / CompleteCapture instance.
    RecordingSessionService? session;

    final container = ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(durable.heroRepository),
        storyRepositoryProvider.overrideWithValue(durable.storyRepository),
        storyMediaStoragePortProvider.overrideWithValue(durable.mediaStorage),
        captureCompletionStoreProvider.overrideWithValue(
          durable.captureCompletionStore,
        ),
        activeLocalHeroStoreProvider.overrideWithValue(
          ActiveLocalHeroStore(storageRoot: root),
        ),
        useRealDeviceRecordingProvider.overrideWithValue(useRealDeviceRecording),
        deviceRecordingPortProvider.overrideWithValue(recordingPort),
        recordingSessionServiceProvider.overrideWith((ref) {
          final existing = session;
          if (existing != null) {
            return existing;
          }
          final created = RecordingSessionService(
            recordingPort: recordingPort,
            completeCapture: CompleteStoryCaptureUseCase(
              storyRepository: durable.storyRepository,
              heroRepository: durable.heroRepository,
              mediaStorage: durable.mediaStorage,
              eventBus: ref.watch(eventBusProvider),
              completionStore: durable.captureCompletionStore,
            ),
            manifestDirectory: manifests,
          );
          session = created;
          return created;
        }),
      ],
    );

    final bootstrap = ApplicationBootstrap(container: container);
    await bootstrap.initialize();

    // Warm local Hero bootstrap so Tell Your Story has an owner.
    await container.read(ensureActiveLocalHeroProvider.future);

    // Ensure the session singleton is created against the live EventBus.
    container.read(recordingSessionServiceProvider);

    return container;
  }
}
