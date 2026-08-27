import 'package:flutter/material.dart';

import 'package:everyonesheroes/features/life_journey/presentation/screens/discover_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/home_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/journey_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = <Widget>[
    KeyedSubtree(key: ValueKey('screen-home'), child: HomeScreen()),
    KeyedSubtree(key: ValueKey('screen-journey'), child: JourneyScreen()),
    KeyedSubtree(key: ValueKey('screen-discover'), child: DiscoverScreen()),
    KeyedSubtree(key: ValueKey('screen-reflect'), child: ReflectScreen()),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _destinations),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey('nav-journey'),
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Journey',
          ),
          NavigationDestination(
            key: ValueKey('nav-discover'),
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            key: ValueKey('nav-reflect'),
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Reflect',
          ),
        ],
      ),
    );
  }
}
