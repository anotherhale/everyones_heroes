import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:everyonesheroes/bootstrap/application_bootstrap.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/discovery/presentation/inspiring_hero_profile_action.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/persistence/hero_story_persistence_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_transcription_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/experience_lab_run_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/experience_render_manifest_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/music_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_proposal_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_voice_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/transcription/transcription_store_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_profile_action_provider.dart';

/// Application composition root (HS.9 durable capture + HS.11 transcription).
///
/// Temporary development identity: [ensureActiveLocalHeroProvider] bootstraps a
/// local Hero until the Identity bounded context exists (HS-ADR-065).
///
/// Durable local filesystem persistence is used on native targets. Flutter Web
/// (and explicit in-memory mode) keeps the default in-memory Hero & Story
/// providers so browser startup does not depend on path_provider / dart:io
/// storage. Device recording remains lazy — the session is created when the
/// recording flow first reads [recordingSessionServiceProvider].
final class AppCompositionRoot {
  /// [storageRoot] / [recordingTemp] override path_provider for tests.
  ///
  /// When [useRealDeviceRecording] is false, a [FakeDeviceRecordingAdapter] is
  /// used (tests / environments without mic plugins).
  ///
  /// [enableDurableLocalPersistence] forces the durable or in-memory path.
  /// When omitted: durable when [storageRoot] is provided or the platform is
  /// not web; otherwise in-memory (browser-safe).
  ///
  /// Transcription defaults to the development in-memory adapter unless
  /// [transcriptionPort] is provided or `EH_AI_PROXY_URL` selects proxy mode
  /// (HS-ADR-067). Production OpenAI secrets never enter this client.
  static Future<ProviderContainer> initialize({
    Directory? storageRoot,
    Directory? recordingTemp,
    bool useRealDeviceRecording = true,
    bool? enableDurableLocalPersistence,
    StoryTranscriptionPort? transcriptionPort,
  }) async {
    final useDurable = enableDurableLocalPersistence ??
        (storageRoot != null || !kIsWeb);

    if (!useDurable) {
      return _initializeInMemoryHeroStory(
        transcriptionPort: transcriptionPort,
      );
    }

    return _initializeDurableHeroStory(
      storageRoot: storageRoot,
      recordingTemp: recordingTemp,
      useRealDeviceRecording: useRealDeviceRecording,
      transcriptionPort: transcriptionPort,
    );
  }

  static StoryTranscriptionPort _resolveTranscriptionPort(
    StoryTranscriptionPort? override,
  ) {
    if (override != null) {
      return override;
    }
    final mode = StoryTranscriptionConfig.resolveMode();
    if (mode == StoryTranscriptionMode.proxy) {
      final baseUrl = StoryTranscriptionConfig.resolveProxyBaseUrl();
      if (baseUrl == null) {
        throw StateError(
          'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
        );
      }
      return ProxyStoryTranscriptionAdapter(
        baseUrl: baseUrl,
        authToken: StoryTranscriptionConfig.resolveAuthToken(),
      );
    }
    return InMemoryStoryTranscriptionAdapter();
  }

  /// Browser / in-memory composition: eventing + local Hero bootstrap only.
  ///
  /// Leaves Hero/Story/media repositories on their default in-memory providers.
  /// Device recording uses [RecordPackageWebDeviceRecordingAdapter] so Tell Your
  /// Story can request the browser microphone on a user gesture. Filesystem
  /// path_provider is still avoided. [UnavailableDeviceRecordingAdapter] remains
  /// available for genuinely unsupported hosts but is not the web default.
  static Future<ProviderContainer> _initializeInMemoryHeroStory({
    StoryTranscriptionPort? transcriptionPort,
  }) async {
    final recordingPort = createRecordPackageWebDeviceRecordingAdapter();
    final resolvedTranscription = _resolveTranscriptionPort(transcriptionPort);
    final container = ProviderContainer(
      overrides: [
        heroProfileActionBuilderProvider.overrideWithValue(
          inspiringHeroProfileActionBuilder,
        ),
        useRealDeviceRecordingProvider.overrideWithValue(true),
        deviceRecordingPortProvider.overrideWithValue(recordingPort),
        storyTranscriptionPortProvider.overrideWithValue(resolvedTranscription),
      ],
    );

    final bootstrap = ApplicationBootstrap(container: container);
    await bootstrap.initialize();

    await container.read(ensureActiveLocalHeroProvider.future);

    return container;
  }

  static Future<ProviderContainer> _initializeDurableHeroStory({
    required Directory? storageRoot,
    required Directory? recordingTemp,
    required bool useRealDeviceRecording,
    StoryTranscriptionPort? transcriptionPort,
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
    final resolvedTranscription = _resolveTranscriptionPort(transcriptionPort);

    // Late-bound session so we can share one EventBus / CompleteCapture instance.
    RecordingSessionService? session;

    final container = ProviderContainer(
      overrides: [
        heroProfileActionBuilderProvider.overrideWithValue(
          inspiringHeroProfileActionBuilder,
        ),
        heroRepositoryProvider.overrideWithValue(durable.heroRepository),
        storyRepositoryProvider.overrideWithValue(durable.storyRepository),
        storyBuilderSessionRepositoryProvider.overrideWithValue(
          durable.storyBuilderSessionRepository,
        ),
        storyProposalRepositoryProvider.overrideWithValue(
          durable.storyProposalRepository,
        ),
        capturedStoryReadingRepositoryProvider.overrideWithValue(
          durable.capturedStoryReadingRepository,
        ),
        storyExperiencePlanRepositoryProvider.overrideWithValue(
          durable.storyExperiencePlanRepository,
        ),
        storyVoiceRenderingRepositoryProvider.overrideWithValue(
          durable.storyVoiceRenderingRepository,
        ),
        musicRenderingRepositoryProvider.overrideWithValue(
          durable.musicRenderingRepository,
        ),
        experienceLabRunRepositoryProvider.overrideWithValue(
          durable.experienceLabRunRepository,
        ),
        experienceRenderManifestRepositoryProvider.overrideWithValue(
          durable.experienceRenderManifestRepository,
        ),
        storyMediaStoragePortProvider.overrideWithValue(durable.mediaStorage),
        captureCompletionStoreProvider.overrideWithValue(
          durable.captureCompletionStore,
        ),
        transcriptionCompletionStoreProvider.overrideWithValue(
          durable.transcriptionCompletionStore,
        ),
        storyTranscriptionJobStoreProvider.overrideWithValue(
          durable.transcriptionJobStore,
        ),
        storyTranscriptionPortProvider.overrideWithValue(resolvedTranscription),
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

    // RecordingSessionService stays lazy: constructed on first recording-flow
    // read of recordingSessionServiceProvider (not at app launch).

    return container;
  }
}
