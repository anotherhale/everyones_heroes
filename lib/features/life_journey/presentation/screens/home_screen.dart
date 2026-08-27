import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                _ExperienceCard(theme: theme),
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
  const _ExperienceCard({required this.theme});

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
              'Take the next step.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A meaningful experience is waiting for you today.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Begin Experience'),
            ),
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
