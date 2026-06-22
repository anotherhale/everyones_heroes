import 'package:flutter/material.dart';

import 'package:everyonesheroes/app/demo_runner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DemoRunner().run();

  runApp(const Placeholder());
}
