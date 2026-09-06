import 'package:everyonesheroes/app/demo_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/app/app_composition_root.dart';
import 'package:everyonesheroes/app/presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = await AppCompositionRoot.initialize();

  await DemoRunner(container: container).run();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EveryonesHeroesApp(),
    ),
  );
}
