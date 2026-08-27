import 'package:flutter/material.dart';

import 'package:everyonesheroes/app/presentation/app_shell.dart';
import 'package:everyonesheroes/app/presentation/theme/app_theme.dart';

class EveryonesHeroesApp extends StatelessWidget {
  const EveryonesHeroesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Everyone's Heroes",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
