import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/app/app_composition_root.dart';
import 'package:everyonesheroes/app/demo_runner.dart';
import 'package:everyonesheroes/app/presentation/app.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/unavailable_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';

void main() {
  test('composition root initializes with durable local persistence', () async {
    final root = Directory.systemTemp.createTempSync('eh-composition-');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    final container = await AppCompositionRoot.initialize(
      storageRoot: root,
      recordingTemp: Directory('${root.path}/temp')..createSync(),
      useRealDeviceRecording: false,
    );
    addTearDown(container.dispose);

    expect(container.read(ensureActiveLocalHeroProvider).hasValue, isTrue);
  });

  test(
    'in-memory composition initializes without path_provider or recording warm-up',
    () async {
      final container = await AppCompositionRoot.initialize(
        enableDurableLocalPersistence: false,
      );
      addTearDown(container.dispose);

      expect(container.read(heroRepositoryProvider), isA<InMemoryHeroRepository>());
      expect(
        container.read(deviceRecordingPortProvider),
        isA<UnavailableDeviceRecordingAdapter>(),
      );
      expect(container.read(ensureActiveLocalHeroProvider).hasValue, isTrue);

      // Recording session must remain lazy — not constructed during initialize.
      expect(container.exists(recordingSessionServiceProvider), isFalse);
    },
  );

  testWidgets(
    'EveryonesHeroesApp renders Home after in-memory composition + DemoRunner',
    (tester) async {
      final container = await AppCompositionRoot.initialize(
        enableDurableLocalPersistence: false,
      );
      addTearDown(container.dispose);

      await DemoRunner(container: container).run();
      expect(
        container.read(currentJourneyContextProvider).currentJourneyId,
        isNotNull,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EveryonesHeroesApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning.'), findsOneWidget);
      expect(find.byKey(const Key('nav-home')), findsOneWidget);
      expect(find.byKey(const Key('nav-heroes')), findsOneWidget);
    },
  );
}
