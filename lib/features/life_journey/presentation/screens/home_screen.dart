import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/experience_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayExperience = ref.watch(todayExperienceProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Good morning.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You don't have to change everything today.\n"
                  'Just take the next step.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                _SectionLabel(label: "TODAY'S EXPERIENCE", theme: theme),
                const SizedBox(height: 12),
                todayExperience.when(
                  loading: () => const _ExperienceLoadingCard(),
                  error: (error, stackTrace) => _ExperienceErrorCard(
                    onRetry: () {
                      ref.invalidate(todayExperienceProvider);
                    },
                  ),
                  data: (experience) =>
                      _ExperienceCard(experience: experience, theme: theme),
                ),
                const SizedBox(height: 32),
                _SectionLabel(label: 'YOUR JOURNEY', theme: theme),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.route_outlined,
                  title: 'Continue your journey',
                  subtitle: 'See where you are and what comes next.',
                  onTap: () {},
                  theme: theme,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'DISCOVER', theme: theme),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.explore_outlined,
                  title: 'Learn something about yourself',
                  subtitle: 'Discover what inspires you.',
                  onTap: () {},
                  theme: theme,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'REFLECT', theme: theme),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.edit_note_outlined,
                  title: 'Reflect on an experience',
                  subtitle: 'Take a moment to make meaning from your day.',
                  onTap: () {},
                  theme: theme,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience, required this.theme});

  final TodayExperienceViewModel experience;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              experience.title,
              key: const ValueKey('today-experience-title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              experience.description,
              key: const ValueKey('today-experience-description'),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            if (experience.rationale != null) ...[
              const SizedBox(height: 16),
              Text(
                experience.rationale!,
                key: const ValueKey('today-experience-rationale'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('today-experience-begin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExperienceScreen(experience: experience),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(experience.callToAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceLoadingCard extends StatelessWidget {
  const _ExperienceLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ExperienceErrorCard extends StatelessWidget {
  const _ExperienceErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(height: 12),
            Text(
              "Today's experience isn't available right now.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
