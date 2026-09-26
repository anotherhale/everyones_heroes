import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/presentation/providers/inspiring_hero_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_experience_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_detail_screen.dart';

/// Hero profile + discoverable stories for that Hero (HS.7 Slice 2).
///
/// Includes private "Inspires me" preference control (D.11) — not follow,
/// favorite, or public endorsement.
class HeroProfileScreen extends ConsumerWidget {
  const HeroProfileScreen({required this.heroId, super.key});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heroAsync = ref.watch(heroExperienceProvider(heroId));
    final storiesAsync = ref.watch(heroStoriesProvider(heroId));
    final inspiringAsync = ref.watch(isHeroInspiringMeProvider(heroId));
    final actionState = ref.watch(inspiringHeroControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hero')),
      body: heroAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'This hero is not available.',
              key: const ValueKey('hero-unavailable'),
            ),
          ),
        ),
        data: (hero) {
          final isInspiring = inspiringAsync.value ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text(
                hero.displayName,
                key: const ValueKey('hero-profile-name'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hero.visibilityLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  key: const Key('inspires-me-toggle'),
                  label: Text(
                    isInspiring ? 'Inspires me ✓' : 'Inspires me',
                    key: Key(
                      isInspiring
                          ? 'inspires-me-selected'
                          : 'inspires-me-unselected',
                    ),
                  ),
                  selected: isInspiring,
                  onSelected: actionState.isBusy || inspiringAsync.isLoading
                      ? null
                      : (_) {
                          ref
                              .read(inspiringHeroControllerProvider.notifier)
                              .toggle(HeroId(heroId));
                        },
                ),
              ),
              if (actionState.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  actionState.errorMessage!,
                  key: const Key('inspires-me-error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (hero.biography != null) ...[
                const SizedBox(height: 16),
                Text(hero.biography!, style: theme.textTheme.bodyLarge),
              ],
              if (hero.experienceAreas.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  hero.experienceAreas.join(' · '),
                  key: const ValueKey('hero-profile-experience-areas'),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (hero.geographicContext != null) ...[
                const SizedBox(height: 16),
                Text(
                  hero.geographicContext!,
                  key: const ValueKey('hero-profile-geographic-context'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (hero.languages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  hero.languages
                      .map((language) => language.value.toUpperCase())
                      .join(' · '),
                  key: const ValueKey('hero-profile-languages'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'STORIES',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              storiesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => const Text('Unable to load stories.'),
                data: (response) {
                  if (response.items.isEmpty) {
                    return const Text(
                      'No discoverable stories for this hero yet.',
                      key: ValueKey('hero-stories-empty'),
                    );
                  }
                  return Column(
                    children: [
                      for (final story in response.items)
                        ListTile(
                          key: ValueKey('hero-story-${story.storyId.value}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(story.title),
                          subtitle: Text(
                            story.originalLanguage.value.toUpperCase(),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => StoryDetailScreen(
                                  storyId: story.storyId.value,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
