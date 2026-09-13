import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_experience_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_profile_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_catalog_screen.dart';

/// Primary HS.7 entry surface for Hero & Story discovery.
///
/// Kept separate from Life Journey [DiscoverScreen] (HS.7 navigation rule).
class HeroCatalogScreen extends ConsumerWidget {
  const HeroCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heroesAsync = ref.watch(discoverableHeroesProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Heroes',
                  key: const ValueKey('heroes-title'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover lived experiences that may inspire your own growth.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('browse-stories-button'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StoryCatalogScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: const Text('Browse stories'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'HEROES',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          heroesAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Unable to load heroes.'),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(discoverableHeroesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (response) {
              if (response.items.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No discoverable heroes yet.',
                      key: ValueKey('heroes-empty'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final hero = response.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        key: ValueKey('hero-tile-${hero.heroId.value}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          hero.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          hero.biography ??
                              (hero.experienceAreas.isEmpty
                                  ? 'Lived experience'
                                  : hero.experienceAreas.join(' · ')),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HeroProfileScreen(
                                heroId: hero.heroId.value,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }, childCount: response.items.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
